from functools import lru_cache

import requests

from reflex_cache.util import Uncached


class NixCacheFetcher:
    def __init__(self, caches):
        self.__caches = caches

    @lru_cache(maxsize=32768)
    def __try_all_cached(self, method, path):
        fn = (
            requests.get
            if method == "get"
            else requests.head
            if method == "head"
            else Exception("invalid method")
        )

        bestState = 404

        print(f"  fetching [{method}] from any cache {path}")
        for cache in self.__caches:
            try:
                rCache = fn(f"{cache}{path}")
                if rCache.status_code < bestState:
                    bestState = rCache.status_code

                print(f"  {rCache.status_code} - [{method}] {cache}{path}")
                if bestState == 200:
                    r = (bestState, rCache.content if method != "head" else False)
                    if path.endswith(".narinfo"):
                        return r
                    else:
                        raise Uncached(r)
            except requests.ConnectionError as e:
                print(e)

        # HACK: lru_cache does not cache results if an exception occurs
        # since we don't want to cache empty query results, we make use of this behavior
        raise Uncached((bestState, False))

    def try_all(self, method, path):
        try:
            return self.__try_all_cached(method, path)
        except Uncached as r:
            return r.args[0]
