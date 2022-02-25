import re
from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler
from threading import Lock

import multibase
from multiaddr import Multiaddr

from reflex_cache import db, ipfs, nix_cache, util


class ReflexHTTPServiceHandler(BaseHTTPRequestHandler):
    _workSet = set()
    _workSetLock = Lock()
    _executor_nar = ThreadPoolExecutor(8)
    #_executor_narinfo = ThreadPoolExecutor(16) # for narinfo uploads - TODO
    
    _db = db.ReflexDB(util.envOr("CACHE_DIRECTORY", "/var/tmp"))

    _nix = nix_cache.NixCacheFetcher(util.envOr("NIX_CACHES","https://cache.nixos.org").split(" "))

    _ipfs = ipfs.IPFSController(Multiaddr(util.envOrRaise("IPFS_API")), _nix, _db)
    
    def do_HEAD(self):
        if self.path.endswith(".narinfo"):
            print(f"NAR info request: {self.path}")
            code, content = self._nix.try_all("head",self.path)
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
            resultHash = self._db.get_path(self.path)

            if resultHash == None:
                with self._workSetLock:
                    found = False
                    for (itemNar, itemFuture) in self._workSet:
                        if itemNar == self.path:
                            f = itemFuture
                            print(f"IPFS fetch task for {self.path} already being processed")
                            found = True
                            break

                    if not found:
                        print(f"Creating new IPFS fetch task for {self.path}")
                        f = self._executor_nar.submit(self._ipfs.ipfs_fetch_task, self.path)
                        self._workSet.add((self.path, f))

                resultNar, code, resultHash = f.result()

                with self._workSetLock:
                    try:
                        self._workSet.remove((self.path, f))
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
                        redirect = multibase.decode(decoded1).decode("utf-8")
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
            code, content = self._nix.try_all("get",self.path)
            self.send_response(code)
            self.end_headers()
            if code == 200:
                self.wfile.write(content)
                if match := re.search('URL: (nar/[a-z0-9]*\.nar.*)', content.decode("utf-8")):
                    nar = f"/{match.group(1)}"
                    if self._db.get_path(nar) == None:
                        with self._workSetLock:
                            found = False
                            for (itemNar, itemFuture) in self._workSet:
                                if itemNar == nar:
                                    found = True
                                    break

                            if not found and len(self._workSet) < 8:
                                print(f"Pre-flight: creating IPFS fetch task for {nar}")
                                f = self._executor_nar.submit(self._ipfs.ipfs_fetch_task, nar)
                                self._workSet.add((nar, f))
            return

        else:
            code = 404

        if code > 299:
            self.send_response(code)
            self.end_headers()
            return
