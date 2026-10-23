#!/usr/bin/env bash
# Release the newest main on this server. Run it as root.
set -euo pipefail

cd /opt/conduit/src
git pull

/opt/conduit/venv/bin/pip install -q -r backend/requirements.txt

cd frontend
npm install --no-package-lock
npm run build

systemctl restart conduit conduit-web
sleep 5

curl -fsS http://127.0.0.1:8000/api/health-check
echo
curl -fsS -o /dev/null http://127.0.0.1:3000
echo "OK: released $(git rev-parse --short HEAD)"
