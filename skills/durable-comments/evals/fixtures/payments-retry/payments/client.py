import time
import uuid

import yaml
from payco import PayCoClient, TransientError


def load_settings(path="config/payments.yaml"):
    with open(path) as f:
        return yaml.safe_load(f)["payco"]


def charge(customer_id: str, amount_cents: int, settings=None):
    settings = settings or load_settings()
    client = PayCoClient(settings["base_url"], timeout=settings["request_timeout"])

    # One key per logical charge, reused on every retry, so PayCo can
    # deduplicate attempts that reached it.
    idempotency_key = str(uuid.uuid4())

    deadline = time.monotonic() + settings["retry_window"]
    delay = settings["retry_backoff"]
    for attempt in range(1, settings["max_attempts"] + 1):
        try:
            return client.charge(customer_id, amount_cents, idempotency_key=idempotency_key)
        except TransientError:
            if attempt == settings["max_attempts"] or time.monotonic() + delay > deadline:
                raise
            time.sleep(delay)
            delay *= 2
