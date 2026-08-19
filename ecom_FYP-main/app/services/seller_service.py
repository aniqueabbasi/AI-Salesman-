"""Seller-scoped views over the shared orders/products collections.

The stock analytics endpoints are global (every order, every seller). A seller
only ever wants the slice of that data belonging to their own listings, so
everything here starts from `products.seller_id` and works outwards.

Aggregation is done in Python rather than with a Mongo pipeline because the
development fallback store only implements a small subset of `aggregate`.
"""

from collections import defaultdict
from datetime import datetime, timedelta

from app.db.database import db

products_collection = db["products"]
orders_collection = db["orders"]

# Statuses that still need action from the seller.
OPEN_STATUSES = {"pending", "confirmed", "packed", "processing"}
# Statuses that reverse a sale and should not count as revenue.
REVERSED_STATUSES = {"returned", "cancelled", "refunded"}


def _as_datetime(value):
    """Timestamps come back as datetimes from Mongo and as ISO strings from
    the JSON-backed fallback store."""
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            return None
    return None


def _seller_catalogue(seller_id):
    """Map of product_id -> product for everything this seller lists."""
    catalogue = {}
    for product in products_collection.find({"seller_id": str(seller_id)}):
        catalogue[str(product["_id"])] = product
    return catalogue


def get_seller_orders(seller_id):
    """Every order containing at least one of this seller's products.

    Each order is annotated with only the lines that belong to this seller,
    plus the subtotal those lines represent, so one seller never sees another
    seller's revenue from a shared basket.
    """
    catalogue = _seller_catalogue(seller_id)
    if not catalogue:
        return []

    results = []
    for order in orders_collection.find():
        lines = []
        subtotal = 0.0
        for item in order.get("products", []) or []:
            product_id = str(item.get("product_id"))
            product = catalogue.get(product_id)
            if not product:
                continue
            quantity = int(item.get("quantity") or 0)
            price = float(product.get("price") or 0)
            subtotal += price * quantity
            lines.append(
                {
                    "product_id": product_id,
                    "name": product.get("name"),
                    "price": price,
                    "quantity": quantity,
                    "images": product.get("images") or [],
                }
            )

        if not lines:
            continue  # nothing in this basket belongs to the seller

        results.append(
            {
                "id": str(order["_id"]),
                "status": order.get("status", "pending"),
                "created_at": _as_datetime(order.get("created_at")),
                "buyer_name": order.get("buyer_name"),
                "buyer_address": order.get("buyer_address"),
                "buyer_phone": order.get("buyer_phone"),
                "payment_method": order.get("payment_method", "COD"),
                "items": lines,
                "seller_subtotal": round(subtotal, 2),
                "order_total": float(order.get("total_price") or subtotal),
            }
        )

    results.sort(key=lambda o: o["created_at"] or datetime.min, reverse=True)
    return results


def get_seller_summary(seller_id):
    """Headline figures for the dashboard: trailing 30-day revenue with its
    change on the previous 30 days, order count and outstanding dispatches."""
    orders = get_seller_orders(seller_id)
    now = datetime.utcnow()
    window_start = now - timedelta(days=30)
    previous_start = now - timedelta(days=60)

    revenue = 0.0
    previous_revenue = 0.0
    orders_in_window = 0
    to_dispatch = 0

    for order in orders:
        created = order["created_at"]
        reversed_sale = order["status"] in REVERSED_STATUSES

        if order["status"] in OPEN_STATUSES:
            to_dispatch += 1

        if created is None:
            continue
        if created >= window_start:
            orders_in_window += 1
            if not reversed_sale:
                revenue += order["seller_subtotal"]
        elif created >= previous_start and not reversed_sale:
            previous_revenue += order["seller_subtotal"]

    if previous_revenue > 0:
        change = round(((revenue - previous_revenue) / previous_revenue) * 100, 1)
    else:
        change = None  # no baseline to compare against

    return {
        "revenue_30d": round(revenue, 2),
        "revenue_change_pct": change,
        "orders_total": len(orders),
        "orders_30d": orders_in_window,
        "to_dispatch": to_dispatch,
        "listings": len(_seller_catalogue(seller_id)),
    }


def get_seller_report(seller_id, weeks=7):
    """Weekly sales bars, average order value, return rate and best sellers."""
    orders = get_seller_orders(seller_id)
    now = datetime.utcnow()

    buckets = [0.0] * weeks
    for order in orders:
        created = order["created_at"]
        if created is None or order["status"] in REVERSED_STATUSES:
            continue
        days_ago = (now - created).days
        index = weeks - 1 - (days_ago // 7)
        if 0 <= index < weeks:
            buckets[index] += order["seller_subtotal"]

    counted = [
        o for o in orders if o["status"] not in REVERSED_STATUSES
    ]
    revenue = sum(o["seller_subtotal"] for o in counted)
    aov = round(revenue / len(counted), 2) if counted else 0.0
    reversed_count = sum(1 for o in orders if o["status"] in REVERSED_STATUSES)
    returns_pct = round((reversed_count / len(orders)) * 100, 1) if orders else 0.0

    units = defaultdict(int)
    names = {}
    for order in counted:
        for line in order["items"]:
            units[line["product_id"]] += line["quantity"]
            names[line["product_id"]] = line["name"]

    top = sorted(units.items(), key=lambda kv: kv[1], reverse=True)[:5]

    return {
        "revenue_total": round(revenue, 2),
        "series": [
            {"label": f"W{i + 1}", "value": round(value, 2)}
            for i, value in enumerate(buckets)
        ],
        "aov": aov,
        "returns_pct": returns_pct,
        "top_sellers": [
            {"product_id": pid, "name": names.get(pid), "units": qty}
            for pid, qty in top
        ],
    }


def seller_owns_order(seller_id, order_id):
    """Guard for status writes: only the seller with a line in the order."""
    return any(order["id"] == str(order_id) for order in get_seller_orders(seller_id))
