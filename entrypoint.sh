#!/bin/bash
set -e

# Fix ownership of GitHub Actions workspace if it exists
if [ -d "/__w" ]; then
    sudo /usr/bin/chown -R -h app:app /__w 2>/dev/null || true
fi

if [ -d "/github" ]; then
    sudo /usr/bin/chown -R -h app:app /github 2>/dev/null || true
fi

exec "$@"