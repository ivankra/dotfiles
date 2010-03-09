#!/bin/sh

if [ -z "$1" -o -z "$2" ]; then
  echo "This script converts Google Chrome's cookie database to Firefox 3's database."
  echo "Usage: $0 <Chrome's Cookies> <Firefox's cookies.sqlite>"
  echo "Firefox database will be overwritten."
  exit 1
fi

if [ -z "`which sqlite3`" ]; then
  echo "This script requires sqlite3 command line tool."
  echo "Try: sudo apt-get install sqlite3"
  exit 1;
fi

cp -f "$1" "$2" &&
sqlite3 "$2" <<EOF
  BEGIN;
  CREATE TABLE moz_cookies (
    id INTEGER PRIMARY KEY, name TEXT, value TEXT, host TEXT,
    path TEXT, expiry INTEGER, lastAccessed INTEGER, isSecure INTEGER,
    isHttpOnly INTEGER);
  INSERT INTO moz_cookies
    SELECT creation_utc AS id, name, value, host_key AS host, path,
    expires_utc AS expiry, last_access_utc AS lastAccessed,
    secure AS isSecure, httponly AS isHttpOnly FROM cookies;
  DROP TABLE cookies;
  DROP TABLE meta;
  COMMIT;
EOF

