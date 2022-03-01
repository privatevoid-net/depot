import contextlib
import sqlite3
from functools import lru_cache
from threading import Lock

from reflex_cache import util


class ReflexDB:
    def __init__(self, cacheDir):
        self.__cacheDir = cacheDir
        self.__lock = Lock()

        # initialize DB schema
        with self.getcon() as (con, cur):
            cur.execute(
                "CREATE TABLE IF NOT EXISTS NarToIpfs (nar text primary key, ipfs text)"
            )
            con.commit()

    @contextlib.contextmanager
    def getcon(self):
        with self.__lock:
            con = sqlite3.connect(f"{self.__cacheDir}/nix-ipfs-cache.db")
            cur = con.cursor()
            try:
                yield con, cur
            finally:
                con.close()

    @lru_cache(maxsize=65536)
    def __get_path_cached(self, narPath):
        with self.getcon() as (con, cur):
            for (nar, ipfs) in cur.execute(
                "SELECT nar, ipfs FROM NarToIpfs WHERE nar=:nar", {"nar": narPath}
            ):
                return ipfs
            # HACK: lru_cache does not cache results if an exception occurs
            # since we don't want to cache empty query results, we make use of this behavior
            raise util.Uncached

    def get_path(self, narPath):
        try:
            return self.__get_path_cached(narPath)
        except util.Uncached:
            return None

    def set_path(self, narPath, ipfsPath):
        with self.getcon() as (con, cur):
            cur.execute(
                "INSERT INTO NarToIpfs VALUES (:nar, :ipfs)",
                {"nar": narPath, "ipfs": ipfsPath},
            )
            con.commit()
