"""In-memory stand-in for MongoDB.

Used automatically when the real MongoDB connection fails, so the API still
serves data during development. It implements only the slice of the pymongo
surface this project actually calls:

    insert_one / find_one / find (+ cursor .sort/.skip/.limit)
    update_one / delete_one / count_documents / aggregate

Data lives in process memory only and resets on every restart.
"""

import json
import logging
import re
from datetime import datetime, timedelta
from pathlib import Path

from bson.objectid import ObjectId

logger = logging.getLogger(__name__)

# Where the in-memory contents get mirrored so seller listings and accounts
# survive a server restart. Delete this file to reset to the seed catalogue.
STORE_PATH = Path(__file__).resolve().parents[1] / "static" / "mock_store.json"


def _encode(value):
    """Make ObjectId/datetime JSON-serialisable, tagged so we can restore them."""
    if isinstance(value, ObjectId):
        return {"__oid__": str(value)}
    if isinstance(value, datetime):
        return {"__dt__": value.isoformat()}
    if isinstance(value, dict):
        return {k: _encode(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_encode(v) for v in value]
    return value


def _decode(value):
    if isinstance(value, dict):
        if "__oid__" in value:
            return ObjectId(value["__oid__"])
        if "__dt__" in value:
            return datetime.fromisoformat(value["__dt__"])
        return {k: _decode(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_decode(v) for v in value]
    return value


def _matches(doc, query):
    """Evaluate a (small) subset of MongoDB query syntax against one document."""
    if not query:
        return True

    for key, condition in query.items():
        # Logical operators
        if key == "$or":
            if not any(_matches(doc, sub) for sub in condition):
                return False
            continue
        if key == "$and":
            if not all(_matches(doc, sub) for sub in condition):
                return False
            continue

        value = doc.get(key)

        if isinstance(condition, dict):
            for op, operand in condition.items():
                if op == "$regex":
                    flags = re.IGNORECASE if "i" in condition.get("$options", "") else 0
                    if value is None or not re.search(operand, str(value), flags):
                        return False
                elif op == "$options":
                    continue  # handled alongside $regex
                elif op == "$in":
                    if value not in operand:
                        return False
                elif op == "$nin":
                    if value in operand:
                        return False
                elif op == "$ne":
                    if value == operand:
                        return False
                elif op in ("$gt", "$gte", "$lt", "$lte"):
                    if value is None:
                        return False
                    try:
                        if op == "$gt" and not value > operand:
                            return False
                        if op == "$gte" and not value >= operand:
                            return False
                        if op == "$lt" and not value < operand:
                            return False
                        if op == "$lte" and not value <= operand:
                            return False
                    except TypeError:
                        return False
                elif op == "$exists":
                    if (key in doc) != bool(operand):
                        return False
                else:
                    logger.warning("MockDB: unsupported query operator %s", op)
                    return False
        else:
            if value != condition:
                return False

    return True


class MockCursor:
    """Chainable cursor so `find(...).sort(...).skip(...).limit(...)` works."""

    def __init__(self, docs):
        self._docs = list(docs)

    def sort(self, key_or_list, direction=1):
        # Support both sort("field", -1) and sort([("field", -1), ...])
        keys = key_or_list if isinstance(key_or_list, list) else [(key_or_list, direction)]
        for key, dir_ in reversed(keys):
            try:
                self._docs.sort(
                    # None sorts first ascending, so key on a (is_none, value) tuple
                    key=lambda d: (d.get(key) is None, d.get(key)),
                    reverse=(dir_ == -1),
                )
            except TypeError:
                # Mixed/incomparable types in this field - leave the order as-is
                # rather than blowing up the request.
                logger.warning("MockDB: cannot sort on %r (mixed types)", key)
        return self

    def skip(self, count):
        if count:
            self._docs = self._docs[count:]
        return self

    def limit(self, count):
        if count:
            self._docs = self._docs[:count]
        return self

    def __iter__(self):
        return iter(self._docs)

    def __len__(self):
        return len(self._docs)

    def __getitem__(self, item):
        return self._docs[item]


class MockCollection:
    def __init__(self, name, on_change=None):
        self.name = name
        self.data = []
        # Called after any write so the owning MockDB can persist to disk.
        self._on_change = on_change

    def _changed(self):
        if self._on_change:
            self._on_change()

    def insert_one(self, document):
        document = dict(document)
        document.setdefault("_id", ObjectId())
        self.data.append(document)
        self._changed()
        return type("InsertOneResult", (object,), {"inserted_id": document["_id"]})

    def insert_many(self, documents):
        ids = [self.insert_one(d).inserted_id for d in documents]
        return type("InsertManyResult", (object,), {"inserted_ids": ids})

    def find_one(self, query=None, *args, **kwargs):
        for doc in self.data:
            if _matches(doc, query or {}):
                return doc
        return None

    def find(self, query=None, *args, **kwargs):
        return MockCursor(doc for doc in self.data if _matches(doc, query or {}))

    def count_documents(self, query=None, *args, **kwargs):
        return sum(1 for doc in self.data if _matches(doc, query or {}))

    def update_one(self, query, update, upsert=False):
        for doc in self.data:
            if _matches(doc, query or {}):
                doc.update(update.get("$set", {}))
                for field, amount in update.get("$inc", {}).items():
                    doc[field] = (doc.get(field) or 0) + amount
                for field, item in update.get("$push", {}).items():
                    doc.setdefault(field, []).append(item)
                self._changed()
                return type("UpdateResult", (object,), {"matched_count": 1, "modified_count": 1})

        if upsert:
            new_doc = dict(query or {})
            new_doc.update(update.get("$set", {}))
            self.insert_one(new_doc)
            return type("UpdateResult", (object,), {"matched_count": 0, "modified_count": 0})

        return type("UpdateResult", (object,), {"matched_count": 0, "modified_count": 0})

    def delete_one(self, query):
        for index, doc in enumerate(self.data):
            if _matches(doc, query or {}):
                del self.data[index]
                self._changed()
                return type("DeleteResult", (object,), {"deleted_count": 1})
        return type("DeleteResult", (object,), {"deleted_count": 0})

    def aggregate(self, pipeline, *args, **kwargs):
        # Only analytics/report endpoints use aggregation. Returning empty keeps
        # them responding instead of raising; they are not part of the storefront.
        logger.warning(
            "MockDB: aggregate() on %r is not implemented; returning no rows", self.name
        )
        return []


class MockDB(dict):
    """Collection registry that mirrors itself to STORE_PATH after each write."""

    def __init__(self):
        super().__init__()
        # Suppress disk writes while bulk-loading from disk.
        self._loading = False

    def __getitem__(self, key):
        if key not in self:
            self[key] = MockCollection(key, on_change=self.save)
        return super().__getitem__(key)

    def save(self):
        if self._loading:
            return
        try:
            STORE_PATH.parent.mkdir(parents=True, exist_ok=True)
            payload = {name: _encode(col.data) for name, col in self.items()}
            # Write via a temp file so a crash mid-write cannot corrupt the store.
            temp_path = STORE_PATH.with_suffix(".tmp")
            temp_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
            temp_path.replace(STORE_PATH)
        except Exception as exc:  # persistence must never break a request
            logger.warning("MockDB: could not persist store: %s", exc)

    def load(self):
        if not STORE_PATH.exists():
            return False
        try:
            payload = json.loads(STORE_PATH.read_text(encoding="utf-8"))
        except Exception as exc:
            logger.warning("MockDB: could not read store (%s); starting fresh", exc)
            return False

        self._loading = True
        try:
            for name, docs in payload.items():
                self[name].data = _decode(docs)
        finally:
            self._loading = False

        logger.info(
            "MockDB: restored %d products and %d users from disk",
            len(self["products"].data),
            len(self["users"].data),
        )
        return True


# --------------------------------------------------------------------------
# Seed catalogue
# --------------------------------------------------------------------------
# Mirrors the products the Flutter app bundles in
# lib/AppScreens/ShopMenu/dummy_products.dart, so the API and the app's offline
# fallback show the same catalogue.

_SEED_PRODUCTS = [
    # name, price, category, image, stock
    ("Classic Cotton Shirt", 1999, "Shirt", "munggyqamzvdgokxkupy.jpg", 25),
    ("White Shirt", 2499, "Shirt", "shirt1.jpg", 18),
    ("Black Formal Shirt", 2199, "Shirt", "shirt2.jpg", 20),
    ("Printed Summer Shirt", 1799, "Shirt", "green.jpg", 30),
    ("Women T-Shirt", 2099, "Shirt", "w1.jpg", 22),
    ("Black Men T-Shirt", 2099, "Shirt", "casual.jpg", 27),
    ("Classic Blue Jeans", 2999, "Jean", "JEANS 6.jpg", 15),
    ("Distressed Jeans", 3199, "Jean", "JEANS 5.jpg", 12),
    ("Washed Denim Jeans", 3299, "Jean", "JEANS 4.jpg", 14),
    ("Slim Fit Jeans", 3499, "Jean", "JEANS 3.jpg", 10),
    ("Straight Cut Jeans", 2799, "Jean", "JEANS 2.jpg", 16),
    ("Black Denim Jeans", 3599, "Jean", "JEANS 1.jpg", 11),
    ("Classic White Sneakers", 2999, "Shoes", "SHOES 6.jpg", 20),
    ("Black Running Shoes", 3499, "Shoes", "shoe2.jpg", 17),
    ("Blue Sports Shoes", 2799, "Shoes", "shoe3.jpg", 19),
    ("Red Casual Shoes", 2599, "Shoes", "shoe4.jpg", 21),
    ("Formal Black Shoes", 3999, "Shoes", "shoe5.jpg", 9),
    ("Brown Leather Boots", 4999, "Shoes", "shoe6.jpg", 7),
    ("Black Leather Jacket", 5999, "Jacket", "jacket1.jpg", 8),
    ("Denim Jacket", 3999, "Jacket", "jacket2.jpg", 13),
    ("Bomber Jacket", 4499, "Jacket", "jacket3.jpg", 10),
    ("Winter Jacket", 6999, "Jacket", "jacket4.jpg", 6),
    ("Puffer Jacket", 5499, "Jacket", "jacket5.jpg", 9),
    ("Brown Suede Jacket", 6499, "Jacket", "jacket6.jpg", 5),
]


def seed(db):
    """Restore any saved state, then populate the starter catalogue if empty."""
    db.load()

    _seed_products(db)

    # Ownership and order history are seeded separately: the catalogue may
    # already exist from disk while the seller demo data does not.
    try:
        from app.db.seed_demo import seed_demo

        seed_demo(db)
    except Exception as exc:  # demo data must never block startup
        logger.warning("MockDB: could not seed demo data: %s", exc)


def _seed_products(db):
    products = db["products"]
    if products.data:
        return  # already seeded or restored from disk

    now = datetime.utcnow()
    for index, (name, price, category, image, stock) in enumerate(_SEED_PRODUCTS):
        products.insert_one(
            {
                "name": name,
                "description": f"{name} - available now from the AI Salesman store.",
                "price": float(price),
                "stock": stock,
                "category": category,
                # Asset paths the Flutter app already ships, so images resolve
                # locally without needing a media server.
                "images": [f"assets/images/{image}"],
                # Newest first when sorted by created_at descending.
                "created_at": now - timedelta(minutes=len(_SEED_PRODUCTS) - index),
                "updated_at": now,
            }
        )

    logger.info("MockDB: seeded %d products", len(products.data))
