from http.server import HTTPServer
from os import environ
from socketserver import ThreadingMixIn


class Uncached(Exception):
    pass


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    pass


class MissingEnvironmentVariableError(Exception):
    pass


def envOr(key, default):
    if key in environ:
        return environ[key]
    else:
        return default


def envOrRaise(key):
    if key in environ:
        return environ[key]
    else:
        raise MissingEnvironmentVariableError(key)
