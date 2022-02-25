from urllib.parse import quote_plus

import requests
import requests_unixsocket

from reflex_cache.util import envOrRaise


class IPFSController:
    def __init__(self, apiAddress, nixCache, db):
        self.__addr = f'http+unix://{quote_plus(apiAddress.get("unix"))}'
        self.__nix = nixCache
        self.__db = db

    def ipfs_fetch_task(self, nar):
        print(f"Downloading NAR: {nar}")
        code, content = self.__nix.try_all("get",nar)
        if code == 200:
            upload = {'file': ('FILE',content,'application/octet-stream')}
            try:
                rIpfs = requests_unixsocket.post(f'{self.__addr}/api/v0/add?pin=false&quieter=true', files=upload)
                hash = rIpfs.json()["Hash"]
                print(f"Mapped: {nar} -> /ipfs/{hash}")
                self.__db.set_path(nar, hash)
                return (nar, 200, hash)
            except requests.ConnectionError as e:
                print(e)
                return (nar, 502, False)
        else:
            return (nar, code, False)
