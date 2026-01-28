#!/bin/bash

pkill -f target/release/server 2>/dev/null
echo "=== Lightning status ==="
lightning-cli --network=testnet4 getinfo 2>&1 | head -3
echo ""
echo "=== Starting server ==="
cd ~/LN_version_2/lnurl-server
./target/release/server > /tmp/server.log 2>&1 &
SPID=$!
echo "Server PID: $SPID"
sleep 5
echo ""
echo "=== Server process check ==="
ps aux | grep "$SPID" | grep -v grep || echo "Server process not found"
echo ""
echo "=== Server logs ==="
cat /tmp/server.log 2>/dev/null || echo "No logs yet"
echo ""
echo "=== Testing endpoints ==="
curl -s http://localhost:3000/request-channel
echo ""
curl -s http://localhost:3000/withdraw-request
