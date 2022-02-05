from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
from http.server import HTTPServer, BaseHTTPRequestHandler
from os import environ
from random import randint
from socketserver import ThreadingMixIn
from sys import argv
from threading import Thread, Lock
import base64
import json
import queue
import re
import requests
import requests_unixsocket
import sqlite3
import time

CACHES = [
    "https://cache.privatevoid.net",
    "https://cache.nixos.org",
    "https://max.cachix.org"
]

workSet = set()
workSetLock = Lock()
dbLock = Lock()

class Uncached(Exception):
    pass

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    pass

def db_getcon():
    cacheDir = environ["CACHE_DIRECTORY"]
    con = sqlite3.connect(f"{cacheDir}/nix-ipfs-cache.db")
    cur = con.cursor()
    return con, cur

def db_close(con):
    con.close()

@lru_cache(maxsize=65536)
def db_get_path_cached(narPath):
    with dbLock:
        con, cur = db_getcon()
        for (nar, ipfs) in cur.execute("SELECT nar, ipfs FROM NarToIpfs WHERE nar=:nar", {"nar": narPath}):
            db_close(con)
            return ipfs
        raise Uncached

def db_get_path(narPath):
    try:
        return db_get_path_cached(narPath)
    except Uncached:
        return None

def db_set_path(narPath, ipfsPath):
    with dbLock:
        con, cur = db_getcon()
        cur.execute("INSERT INTO NarToIpfs VALUES (:nar, :ipfs)", {"nar": narPath, "ipfs": ipfsPath})
        con.commit()
        db_close(con)

@lru_cache(maxsize=32768)
def try_all_cached(method, path):
    fn = requests.get if method == "get" else requests.head if method == "head" else Error("invalid method")

    bestState = 502

    print(f"  fetching [{method}] from any cache {path}")
    for cache in CACHES:
        try:
            rCache = fn(f"{cache}{path}")
            if rCache.status_code < bestState:
                bestState = rCache.status_code

            print(f"  {rCache.status_code} - [{method}] {cache}{path}")
            if bestState == 200:
                r = (bestState,rCache.content if method != "head" else False)
                if path.endswith(".narinfo"):
                    return r
                else:
                    raise Uncached(r)
        except requests.ConnectionError as e:
            print(e)

    raise Uncached((bestState,False))

def try_all(method, path):
    try:
        return try_all_cached(method, path)
    except Uncached as r:
        return r.args[0]

def ipfs_fetch_task(nar):
    print(f"Downloading NAR: {nar}")
    code, content = try_all("get",nar)
    if code == 200:
        upload = {'file': ('FILE',content,'application/octet-stream')}
        try:
            rIpfs = requests_unixsocket.post('http+unix://%2Frun%2Fipfs%2Fipfs-api.sock/api/v0/add?pin=false&quieter=true', files=upload)
            hash = rIpfs.json()["Hash"]
            print(f"Mapped: {nar} -> /ipfs/{hash}")
            db_set_path(nar, hash)
            return (nar, 200, hash)
        except requests.ConnectionError as e:
            print(e)
            return (nar, 502, False)
    else:
        return (nar, code, False)

class ServiceHandler(BaseHTTPRequestHandler):
    _executor_nar_pre = ThreadPoolExecutor(4)
    _executor_nar_main = ThreadPoolExecutor(8)
    #_executor_narinfo = ThreadPoolExecutor(16) # for narinfo uploads - TODO
    
    def do_HEAD(self):
        if self.path.endswith(".narinfo"):
            print(f"NAR info request: {self.path}")
            code, content = try_all("head",self.path)
            self.send_response(code)
            self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        if self.path.startswith("/nix-cache-info"):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"StoreDir: /nix/store\n")
            return

        elif self.path.startswith("/nar/"):
            resultHash = db_get_path(self.path)

            if resultHash == None:
                with workSetLock:
                    found = False
                    for (itemNar, itemFuture) in workSet:
                        if itemNar == self.path:
                            f = itemFuture
                            print(f"IPFS fetch task for {self.path} already being processed")
                            found = True
                            break

                    if not found:
                        print(f"Creating new IPFS fetch task for {self.path}")
                        f = self._executor_nar_main.submit(ipfs_fetch_task, self.path)
                        workSet.add((self.path, f))

                resultNar, code, resultHash = f.result()

                with workSetLock:
                    try:
                        workSet.remove((self.path, f))
                    except KeyError:
                        # already removed
                        pass
            else:
                code = 200

            if code != 200:
                self.send_response(code)
                self.end_headers()
                return

            self.send_response(302)

            # not used for auth, but for defining a redirect target
            auth = self.headers.get('Authorization')
            if auth != None:
                try:
                    decoded1 = base64.b64decode(auth.removeprefix("Basic ")).removesuffix(b":")
                    if decoded1.isdigit():
                        redirect = f"http://127.0.0.1:{decoded1.decode('utf-8')}"
                    else:
                        decoded2 = base64.b32decode(decoded1.upper() + b"=" * (-len(decoded1) % 8))
                        redirect = decoded2.decode("utf-8")
                except Exception:
                    redirect = "http://127.0.0.1:8080"
            else:
                redirect = "http://127.0.0.1:8080"

            self.send_header('Location', f'{redirect}/ipfs/{resultHash}')
            self.send_header('X-Ipfs-Path', f'/ipfs/{resultHash}')
            self.end_headers()
            return

        elif self.path.endswith(".narinfo"):
            print(f"NAR info request: {self.path}")
            code, content = try_all("get",self.path)
            self.send_response(code)
            self.end_headers()
            if code == 200:
                self.wfile.write(content)
                if match := re.search('URL: (nar/[a-z0-9]*\.nar.*)', content.decode("utf-8")):
                    nar = f"/{match.group(1)}"
                    if db_get_path(nar) == None:
                        with workSetLock:
                            found = False
                            for (itemNar, itemFuture) in workSet:
                                if itemNar == nar:
                                    found = True
                                    break

                            if not found:
                                print(f"Pre-flight: creating IPFS fetch task for {nar}")
                                f = self._executor_nar_pre.submit(ipfs_fetch_task, nar)
                                workSet.add((nar, f))
            return

        else:
            code = 404

        if code > 299:
            self.send_response(code)
            self.end_headers()
            return


con, cur = db_getcon()
cur.execute("CREATE TABLE IF NOT EXISTS NarToIpfs (nar text primary key, ipfs text)")
con.commit()
db_close(con)

server = ThreadingHTTPServer(('127.0.0.1',int(argv[1])), ServiceHandler)
server.serve_forever()
