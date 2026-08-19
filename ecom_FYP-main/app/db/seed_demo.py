"""Demo data for the seller experience.

The starter catalogue ships without owners, which leaves every seller
dashboard empty. This module gives the unowned products to the demo seller
accounts and lays down a spread of historic orders so revenue, dispatch
queues and reports have something real to compute from.

Everything here is idempotent and only ever runs against an empty orders
collection, so a real order placed through the app is never disturbed.
"""

import logging
import random
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# Buyers used for the seeded order history.
_BUYERS = [
    ("Anique Shah", "House 12, Street 4, Gulberg III, Lahore", "+92 300 1234567"),
    ("Sana Malik", "Flat 8B, Askari Heights, Karachi", "+92 321 7654321"),
    ("Bilal Ahmed", "42 Jinnah Road, Rawalpindi", "+92 333 2223344"),
    ("Hina Qureshi", "Plot 19, DHA Phase 5, Lahore", "+92 345 9988776"),
    ("Usman Tariq", "6 Mall Road, Islamabad", "+92 301 4455667"),
]

# Weighted so most history is settled and a handful still needs the seller.
_STATUS_PLAN = (
    ["delivered"] * 11
    + ["shipped"] * 4
    + ["packed"] * 3
    + ["pending"] * 3
    + ["returned"] * 1
    + ["cancelled"] * 1
)


def assign_unowned_products(db):
    """Hand ownerless catalogue products to the demo seller accounts.

    Products a real seller already owns are left untouched.
    """
    users = db["users"]
    products = db["products"]

    sellers = [u for u in users.find({"role": "seller"})]
    if not sellers:
        return []

    # Stable order so repeated runs distribute the same way.
    sellers.sort(key=lambda u: str(u.get("email") or ""))

    unowned = [p for p in products.find() if not p.get("seller_id")]
    if not unowned:
        return sellers

    unowned.sort(key=lambda p: str(p["_id"]))
    for index, product in enumerate(unowned):
        seller = sellers[index % len(sellers)]
        products.update_one(
            {"_id": product["_id"]},
            {
                "$set": {
                    "seller_id": str(seller["_id"]),
                    "seller_email": seller.get("email"),
                    "shop_name": seller.get("shop_name"),
                }
            },
        )

    logger.info(
        "Demo seed: assigned %d unowned products across %d sellers",
        len(unowned),
        len(sellers),
    )
    return sellers


def seed_orders(db, count=24):
    """Lay down `count` historic orders spread over the last ~50 days."""
    orders = db["orders"]
    if orders.count_documents({}) > 0:
        return  # never touch a store that already has orders

    catalogue = list(db["products"].find())
    if not catalogue:
        return

    # Deterministic so the demo numbers are stable between restarts.
    rng = random.Random(20260819)
    now = datetime.utcnow()

    for index in range(count):
        basket_size = rng.choice([1, 1, 2, 2, 3])
        chosen = rng.sample(catalogue, min(basket_size, len(catalogue)))

        items = []
        total = 0.0
        for product in chosen:
            quantity = rng.choice([1, 1, 1, 2])
            price = float(product.get("price") or 0)
            total += price * quantity
            items.append(
                {"product_id": str(product["_id"]), "quantity": quantity}
            )

        status = _STATUS_PLAN[index % len(_STATUS_PLAN)]
        created = now - timedelta(
            days=rng.randint(0, 49), hours=rng.randint(0, 23)
        )
        buyer_name, buyer_address, buyer_phone = _BUYERS[index % len(_BUYERS)]

        # A plausible progression up to whatever state the order landed in.
        ladder = ["pending", "packed", "shipped", "delivered"]
        history = []
        for step in ladder:
            history.append({"status": step, "updated_at": created})
            if step == status:
                break
        if status in {"returned", "cancelled"}:
            history.append({"status": status, "updated_at": created})

        orders.insert_one(
            {
                "user_id": f"demo-{index}",
                "products": items,
                "total_price": round(total, 2),
                "status": status,
                "buyer_name": buyer_name,
                "buyer_address": buyer_address,
                "buyer_phone": buyer_phone,
                "payment_method": "COD",
                "tracking_history": history,
                "created_at": created,
                "is_demo": True,
            }
        )

    logger.info("Demo seed: created %d orders", count)


def seed_demo(db):
    """Entry point: owners first, then the order history that depends on them."""
    assign_unowned_products(db)
    seed_orders(db)
