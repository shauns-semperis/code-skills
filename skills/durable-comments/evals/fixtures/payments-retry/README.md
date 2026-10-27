# payments-service

Charges customers through the PayCo gateway.

## Running locally

```sh
pip install -r requirements.txt
python -m payments.client --dry-run
```

## Configuration

Settings live in `config/payments.yaml` and are read once at startup.

| Setting | What it controls |
|---|---|
| `request_timeout` | Seconds before a single request is abandoned. |
| `retry_window` | Total seconds the client keeps retrying a failed charge. |
| `retry_backoff` | Delay before the first retry; doubles each attempt. |
| `max_attempts` | Hard cap on attempts, whichever limit is hit first. |
