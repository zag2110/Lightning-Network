# Test Results

## Environment
- Bitcoin Core v30.2.0 (testnet4, synced)
- Core Lightning v25.12.1 (testnet4)
- Node ID: 021b98c1fd22abd0964685d394723e13d4f66ce8301a84986d00f4572856826f76

## Tests with Professor's Server (82.67.177.113:3001)

### request-channel
**Status:** ✅ Success

Channel opened successfully with professor's node.
- Transaction ID: `f5a43977aa7d83d37d2e7a4723d837fe9edebadc9fda24e88861ce0845dfa4ef`
- Channel ID: `efa4df4508ce6188e824da9fdcbade9efe37d823477a2e7dd3837daa7739a4f5`

### auth
**Status:** ✅ Success

Authentication flow completed:
1. GET /auth-challenge → received k1
2. Used `lightning-cli signmessage` to sign k1
3. GET /auth-response with signature → {"status":"OK"}

### request-withdraw
**Status:** ⚠️ Not tested

Professor's server returns 404 for /withdraw-request endpoint.
Client implementation is complete and ready.

## Notes

Lightning node stability issues in WSL environment prevented deployment of own server.
All client functionality has been implemented and tested where possible.
