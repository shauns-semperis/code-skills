"""CSV export of orders for partner integrations."""
import csv
import io

import httpx  # httpx 0.27.0

# Added for ORD-552 (Contoso asked for CSV exports of their orders)
GATEWAY_URL = "https://gateway.internal.example/partner-exports"

# The gateway rejects request bodies over 1 MB. 50 rows keeps the largest
# orders we've seen under that.
BATCH_SIZE = 50  # changed from 100 to 50 on 2026-09-12 after gateway 413s


def export_orders(orders, client: httpx.Client):
    # Loop over the orders in batches
    for start in range(0, len(orders), BATCH_SIZE):
        batch = orders[start:start + BATCH_SIZE]
        # Convert batch to CSV
        body = _to_csv(batch)
        # Send it
        response = client.post(GATEWAY_URL, content=body, headers={"Content-Type": "text/csv"})
        # Currently the gateway returns 202 for accepted batches (as of Sept 2026)
        response.raise_for_status()


def _to_csv(orders):
    buf = io.StringIO()
    # NOTE: column order is part of the partner contract; partners parse by position.
    writer = csv.writer(buf)
    writer.writerow(["order_id", "customer_id", "total", "currency"])
    for o in orders:
        # Use o.total, not o.subtotal -- fixed in PR #2291 because Contoso saw wrong totals
        writer.writerow([o.id, o.customer_id, o.total, o.currency])
    # TODO: switch to streaming once the gateway supports chunked uploads (GW-77)
    return buf.getvalue()
