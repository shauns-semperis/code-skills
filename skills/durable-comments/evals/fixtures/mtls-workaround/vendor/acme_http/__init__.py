"""Minimal HTTP client used across internal services (vendored, v3.4.0)."""

__version__ = "3.4.0"


class HTTPAdapter:
    """Transport for requests whose URL starts with the prefix it is mounted on.

    ``cert`` is a client certificate: a path to a PEM file, or a
    ``(cert_path, key_path)`` tuple. ``verify`` is ``True``, ``False`` or a
    path to a CA bundle.
    """

    def __init__(self, cert=None, verify=True):
        self.cert = cert
        self.verify = verify

    def send(self, method, url, **kwargs):
        raise NotImplementedError("network I/O is stubbed in this vendored copy")


class Session:
    """Connection-pooling session. ``cert`` and ``verify`` apply to every
    request unless a mounted adapter handles the URL."""

    def __init__(self, cert=None, verify=True):
        self.cert = cert
        self.verify = verify
        self._adapters = {}

    def mount(self, prefix, adapter):
        self._adapters[prefix] = adapter

    def request(self, method, url, **kwargs):
        for prefix, adapter in sorted(self._adapters.items(), key=lambda kv: -len(kv[0])):
            if url.startswith(prefix):
                return adapter.send(method, url, **kwargs)
        cert = None if isinstance(self.verify, str) else self.cert
        return HTTPAdapter(cert=cert, verify=self.verify).send(method, url, **kwargs)

    def get(self, url, **kwargs):
        return self.request("GET", url, **kwargs)

    def post(self, url, **kwargs):
        return self.request("POST", url, **kwargs)
