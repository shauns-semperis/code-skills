import os

import acme_http

LEDGER_URL = os.environ.get("LEDGER_URL", "https://ledger.internal.example")
CA_BUNDLE = os.environ.get("LEDGER_CA_BUNDLE", "/etc/billing-sync/ca.pem")
CLIENT_CERT = (
    os.environ.get("LEDGER_CLIENT_CERT", "/etc/billing-sync/client.pem"),
    os.environ.get("LEDGER_CLIENT_KEY", "/etc/billing-sync/client.key"),
)


def ledger_session() -> acme_http.Session:
    """Session for the ledger API, which requires mutual TLS."""
    return acme_http.Session(cert=CLIENT_CERT, verify=CA_BUNDLE)


def post_entries(entries):
    session = ledger_session()
    response = session.post(f"{LEDGER_URL}/v1/entries", json=entries)
    response.raise_for_status()
    return response.json()
