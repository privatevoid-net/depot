from reflex_cache import db, service_handler, util

CACHES = [
    "https://cache.privatevoid.net",
    "https://cache.nixos.org",
    "https://max.cachix.org"
]



def main():
    server = util.ThreadingHTTPServer(('127.0.0.1',int(util.envOr("REFLEX_PORT", "8002"))), service_handler.ReflexHTTPServiceHandler)
    server.serve_forever()
    
if __name__ == "__main__":
    main()
