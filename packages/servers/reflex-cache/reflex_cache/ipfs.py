from datetime import datetime, timedelta, timezone
from urllib.parse import quote_plus

import requests
import requests_unixsocket


class IPFSController:
    def __init__(self, nodeApiAddress, clusterApiAddress, nixCache, db):
        self.__nodeAddr = f'http+unix://{quote_plus(nodeApiAddress.get("unix"))}'
        self.__clusterAddr = f'http+unix://{quote_plus(clusterApiAddress.get("unix"))}'
        self.__nix = nixCache
        self.__db = db

    def ipfs_fetch_task(self, callback, nar, hint=None):
        print(f"Downloading NAR: {nar}")
        code, _, content = self.__nix.try_all("get", nar, hint)
        if code == 200:
            upload = {"file": ("FILE", content, "application/octet-stream")}
            try:
                rIpfs = requests_unixsocket.post(
                    f"{self.__nodeAddr}/api/v0/add?pin=false&quieter=true", files=upload
                )
                hash = rIpfs.json()["Hash"]
                print(f"Mapped: {nar} -> /ipfs/{hash}")
                self.__db.set_path(nar, hash)
                expireAt = datetime.now(timezone.utc) + timedelta(hours=24)
                rClusterPin = requests_unixsocket.post(
                    f"{self.__clusterAddr}/pins/ipfs/{hash}?expire-at={quote_plus(expireAt.isoformat())}&mode=recursive&name=reflex-{quote_plus(nar)}&replication-max=2&replication-min=1", files=upload
                )
                if rClusterPin.status_code != 200:
                    print(f"Warning: failed to pin {hash} on IPFS cluster")
                callback()
                return (nar, 200, hash)
            except requests.ConnectionError as e:
                print(e)
                callback()
                return (nar, 502, False)
        else:
            callback()
            return (nar, code, False)
