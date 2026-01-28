# LNURL Implementation

Implementation of LNURL protocol client and server for Lightning Network on testnet4.

## Project Structure

- `lnurl-client/` - Client with 3 commands
- `lnurl-server/` - Server with 6 endpoints

## Client Commands

```bash
cd lnurl-client
cargo build --release

# Request channel opening
./target/release/client request-channel <server_url>

# Request withdrawal  
./target/release/client request-withdraw <server_url> [amount_msats]

# LNURL-auth
./target/release/client auth <auth_url>
```

## Server Endpoints

```bash
cd lnurl-server
cargo build --release
./target/release/server
```

Endpoints:
- `GET /request-channel` - Returns channel open info
- `GET /open-channel?remoteid=<id>&k1=<k1>` - Opens channel
- `GET /withdraw-request` - Returns withdrawal info
- `GET /withdraw?k1=<k1>&pr=<invoice>` - Pays invoice
- `GET /auth` - Returns auth challenge
- `GET /auth-verify?k1=<k1>&sig=<sig>&key=<key>` - Verifies signature

## Requirements

- Bitcoin Core (testnet4)
- Core Lightning (testnet4)
- Rust toolchain

## Testing

Server runs on `localhost:3000` by default.

Client requires a running Lightning node with RPC socket at:
`~/.lightning/testnet4/lightning-rpc`
