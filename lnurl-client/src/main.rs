use serde::Deserialize;
use cln_rpc::ClnRpc;
use url::Url;
use anyhow::{Context, Result, anyhow};
use std::net::IpAddr;
use std::net::Ipv4Addr;
use std::str::FromStr;
use secp256k1::PublicKey;
use std::thread;
use std::time::Duration;

// CLN RPC socket path - adjust based on your setup
const CLN_RPC_PATH: &str = "/home/sgotz/.lightning/testnet4/lightning-rpc";

#[derive(Debug)]
enum Commands {
    RequestChannel {
        url: Url,
    },
    RequestWithdraw {
        url: Url,
        amount_msats: Option<u64>,
    },
    Auth {
        url: Url,
    }
}

fn print_usage() {
    eprintln!("Usage:");
    eprintln!("  lnurl-client request-channel <url|ip>");
    eprintln!("  lnurl-client request-withdraw <url|ip> [amount_msats]");
    eprintln!("  lnurl-client auth <url|ip>");
}

fn parse_url_or_ip(input: &str) -> Result<Url> {
    // Try as URL first
    if let Ok(url) = Url::parse(input) {
        return Ok(url);
    }
    
    // IPv6 with brackets [::1]:8080
    if let Some(bracket_end) = input.find("]:") {
        if input.starts_with('[') {
            let ip_part = &input[1..bracket_end];
            let port_part = &input[bracket_end + 2..];
            if port_part.parse::<u16>().is_ok() {
                if let Ok(ip) = IpAddr::from_str(ip_part) {
                    let url_str = format!("http://[{}]:{}", ip, port_part);
                    return Url::parse(&url_str).context("Failed to parse IPv6 URL");
                }
            }
        }
    }
    
    // IP with port
    if let Some(colon_pos) = input.rfind(':') {
        let ip_part = &input[..colon_pos];
        let port_part = &input[colon_pos + 1..];
        
        if port_part.parse::<u16>().is_ok() {
            if let Ok(ip) = IpAddr::from_str(ip_part) {
                let url_str = format!("http://{}:{}", ip, port_part);
                return Url::parse(&url_str).context("Failed to parse IP URL");
            }
        }
    }
    
    // Plain IP without port
    if let Ok(ip) = IpAddr::from_str(input) {
        let url_str = format!("http://{}", ip);
        return Url::parse(&url_str).context("Failed to parse IP");
    }
    
    Err(anyhow!("Invalid URL or IP address: {}", input))
}

fn parse_args() -> Result<Commands> {
    let args: Vec<String> = std::env::args().collect();
    
    if args.len() < 2 {
        print_usage();
        return Err(anyhow!("No command provided"));
    }

    let command_name = args[1].as_str();
    
    match command_name {
        "request-channel" => {
            if args.len() < 3 {
                return Err(anyhow!("request-channel requires a <url> argument"));
            } else if args.len() > 3 {
                return Err(anyhow!("request-channel does not accept additional arguments"));
            }
            
            let url = parse_url_or_ip(&args[2])?;

            Ok(Commands::RequestChannel {
                url,
            })
        } 
        "request-withdraw" => {
            if args.len() < 3 {
                return Err(anyhow!("request-withdraw requires a <url> argument"));
            } else if args.len() > 4 {
                return Err(anyhow!("request-withdraw accepts at most 2 arguments"));
            }
            
            let url = parse_url_or_ip(&args[2])?;
            let amount_msats = if args.len() == 4 {
                Some(args[3].parse::<u64>().context("Invalid amount")?)
            } else {
                None
            };

            Ok(Commands::RequestWithdraw {
                url,
                amount_msats,
            })
        }
        "auth" => {
            if args.len() < 3 {
                return Err(anyhow!("auth requires a <url> argument"));
            } else if args.len() > 3 {
                return Err(anyhow!("auth does not accept additional arguments"));
            }
            
            let url = parse_url_or_ip(&args[2])?;

            Ok(Commands::Auth {
                url,
            })
        }
        _ => {
            print_usage();
            Err(anyhow!("Unknown command: {}", command_name))
        }
    }
}

fn get_node_uri(ln_client: &mut ClnRpc, rt: &tokio::runtime::Runtime) -> Result<String> {
    let node_info = rt.block_on(ln_client.call(cln_rpc::Request::Getinfo(cln_rpc::model::requests::GetinfoRequest{})));
    let node_uri = match node_info {
        Ok(cln_rpc::model::Response::Getinfo(response)) => {
            let pubkey = response.id.to_string();
            println!("Node pubkey initialized: {}", pubkey);
            format!("{}@{}", pubkey, "127.0.0.1:49735")
        }
        Err(e) => {
            return Err(anyhow!("Failed to get node info: {}", e));
        }
        _ => {
            return Err(anyhow!("Unexpected response type"));
        }
    };

    Ok(node_uri)
}

fn connect_to_node(ln_client: &mut ClnRpc, rt: &tokio::runtime::Runtime, node_uri: &str) -> Result<()> {
    let parsed = node_uri.split('@').collect::<Vec<&str>>();
    if parsed.len() != 2 {
        return Err(anyhow!("Invalid node URI: {}", node_uri));
    }
    let pubkey = PublicKey::from_str(parsed[0])?;
    let host = parsed[1];
    let port = host.split(':').collect::<Vec<&str>>()[1];
    let ip_addr: Ipv4Addr = host.split(':').collect::<Vec<&str>>()[0].parse()?;

    println!("Connecting to node {}@{}:{}...", pubkey, ip_addr, port);
    let request = cln_rpc::model::requests::ConnectRequest{
        id: pubkey.to_string(),
        host: Some(ip_addr.to_string()),
        port: port.parse::<u16>().ok(),
    };

    let _response = rt.block_on(ln_client.call(cln_rpc::Request::Connect(request)))?;

    Ok(())
}

#[derive(Debug, Deserialize)]
struct ChannelRequestResponse {
    uri: String,
    callback: String,
    k1: String,
    tag: String,
}

#[derive(Debug, Deserialize)]
struct ChannelOpenResponse {
    status: String,
    reason: Option<String>,
    txid: Option<String>,
    channel_id: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct WithdrawRequestResponse {
    callback: String,
    k1: String,
    default_description: String,
    min_withdrawable: u64,
    max_withdrawable: u64,
    tag: String,
}

#[derive(Debug, Deserialize)]
struct WithdrawResponse {
    status: String,
    reason: Option<String>,
}

fn channel_request(url: &Url) -> Result<()> {
    println!("Requesting channel from {}", url);

    // Check if Lightning node is running
    if !std::path::Path::new(CLN_RPC_PATH).exists() {
        return Err(anyhow!("Lightning node not found at {}", CLN_RPC_PATH));
    }

    // Wait a bit for Lightning to fully initialize
    thread::sleep(Duration::from_secs(2));

    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_io()
        .build()
        .context("Failed to create Tokio runtime")?;
    
    let mut ln_client = rt.block_on(cln_rpc::ClnRpc::new(CLN_RPC_PATH))
        .context("Failed to connect to Lightning node")?;

    let mut node_uri = get_node_uri(&mut ln_client, &rt)?;

    println!("Node URI: {}", node_uri);

    let request_url = format!("{}/request-channel", url.as_str().trim_end_matches('/'));
    println!("Making HTTP request to: {}", request_url);
    let resp: ChannelRequestResponse = match ureq::get(&request_url).call() {
        Ok(response) => response.into_json()?,
        Err(ureq::Error::Status(code, response)) => {
            return Err(anyhow!("HTTP error {}: {}", code, response.status_text()));
        }
        Err(ureq::Error::Transport(transport)) => {
            return Err(anyhow!("Transport error: {}", transport));
        }
    };
    
    println!("Received channel request:");
    println!("  URI: {}", resp.uri);
    println!("  Callback: {}", resp.callback);
    println!("  k1: {}", resp.k1);

    connect_to_node(&mut ln_client, &rt, &resp.uri)?;

    println!("Requesting channel open...");
    
    let _ = node_uri.split_off(secp256k1::constants::PUBLIC_KEY_SIZE * 2); // it will panic if the string is less than 33 bytes long
    let open_url = format!(
        "{}?remoteid={}&k1={}",
        resp.callback,
        node_uri,
        resp.k1
    );
    println!("Open URL: {}", open_url);
    
    let open_resp = match ureq::get(&open_url).call() {
        Ok(resp) => resp.into_json::<ChannelOpenResponse>()?,
        Err(e) => {
            return Err(anyhow!("Failed to open channel: {}", e));
        }
    };
    println!("Open response: {:?}", open_resp);
     
    println!("Channel opened successfully!");
    if let Some(txid) = open_resp.txid {
        println!("  Transaction ID: {}", txid);
    }
    if let Some(channel_id) = open_resp.channel_id {
        println!("  Channel ID: {}", channel_id);
    }

    Ok(())
}

fn withdraw_request(url: &Url, amount_msats: Option<u64>) -> Result<()> {
    println!("Requesting withdrawal from {}", url);

    if !std::path::Path::new(CLN_RPC_PATH).exists() {
        return Err(anyhow!("Lightning node not found"));
    }

    thread::sleep(Duration::from_secs(2));

    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_io()
        .build()
        .context("Failed to create Tokio runtime")?;
    
    let mut ln_client = rt.block_on(cln_rpc::ClnRpc::new(CLN_RPC_PATH))?;

    let request_url = format!("{}/withdraw-request", url.as_str().trim_end_matches('/'));
    
    let resp: WithdrawRequestResponse = match ureq::get(&request_url).call() {
        Ok(response) => response.into_json()?,
        Err(ureq::Error::Status(code, response)) => {
            return Err(anyhow!("HTTP error {}: {}", code, response.status_text()));
        }
        Err(ureq::Error::Transport(transport)) => {
            return Err(anyhow!("Transport error: {}", transport));
        }
    };
    
    println!("Received withdraw request:");
    println!("  Callback: {}", resp.callback);
    println!("  Min withdrawable: {} msats", resp.min_withdrawable);
    println!("  Max withdrawable: {} msats", resp.max_withdrawable);
    println!("  Description: {}", resp.default_description);

    // Determine amount to withdraw
    let amount = if let Some(amt) = amount_msats {
        if amt < resp.min_withdrawable || amt > resp.max_withdrawable {
            return Err(anyhow!(
                "Amount {} msats is outside the allowed range [{}, {}]",
                amt, resp.min_withdrawable, resp.max_withdrawable
            ));
        }
        amt
    } else {
        // Use maximum by default
        resp.max_withdrawable
    };

    println!("Withdrawing {} msats...", amount);

    // Create invoice
    let invoice_request = cln_rpc::model::requests::InvoiceRequest {
        amount_msat: cln_rpc::primitives::AmountOrAny::Amount(cln_rpc::primitives::Amount::from_msat(amount)),
        description: resp.default_description.clone(),
        label: format!("lnurl-withdraw-{}", uuid::Uuid::new_v4()),
        expiry: Some(3600),
        fallbacks: None,
        preimage: None,
        cltv: None,
        deschashonly: None,
        exposeprivatechannels: None,
    };

    let invoice = match rt.block_on(ln_client.call(cln_rpc::Request::Invoice(invoice_request))) {
        Ok(cln_rpc::model::Response::Invoice(response)) => response.bolt11,
        Err(e) => {
            return Err(anyhow!("Failed to create invoice: {}", e));
        }
        _ => {
            return Err(anyhow!("Unexpected response type"));
        }
    };

    println!("Invoice created: {}", invoice);

    // Call callback with invoice
    let callback_url = format!("{}?k1={}&pr={}", resp.callback, resp.k1, invoice);
    println!("Calling callback: {}", callback_url);

    let withdraw_resp = match ureq::get(&callback_url).call() {
        Ok(resp) => resp.into_json::<WithdrawResponse>()?,
        Err(e) => {
            return Err(anyhow!("Failed to complete withdrawal: {}", e));
        }
    };

    if withdraw_resp.status == "OK" {
        println!("✅ Withdrawal initiated successfully!");
        println!("Waiting for payment...");
        // The invoice will be paid by the service
    } else {
        println!("❌ Withdrawal failed: {}", withdraw_resp.reason.unwrap_or_default());
    }

    Ok(())
}

fn auth_request(url: &Url) -> Result<()> {
    println!("Starting LNURL-auth with {}...", url);

    // Parse the URL and extract k1 parameter
    let k1 = url.query_pairs()
        .find(|(key, _)| key == "k1")
        .map(|(_, value)| value.to_string())
        .ok_or_else(|| anyhow!("Missing k1 parameter in URL"))?;

    println!("k1 challenge: {}", k1);

    // For LNURL-auth, we need to sign the k1 with a linking private key
    // Derived from the node's seed for this specific domain
    // This is a simplified implementation - in production, you'd derive a domain-specific key
    
    let k1_bytes = hex::decode(&k1)?;
    if k1_bytes.len() != 32 {
        return Err(anyhow!("k1 must be exactly 32 bytes"));
    }

    // Get node private key (in real implementation, use domain-specific derivation)
    // For now, we'll use a placeholder - you'd need to derive this properly
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_io()
        .build()
        .context("Failed to create Tokio runtime")?;
    
    let mut ln_client = rt.block_on(cln_rpc::ClnRpc::new(CLN_RPC_PATH))?;
    
    // Get node info to get the public key
    let node_info = rt.block_on(ln_client.call(cln_rpc::Request::Getinfo(
        cln_rpc::model::requests::GetinfoRequest{}
    )))?;
    
    let pubkey = match node_info {
        cln_rpc::model::Response::Getinfo(info) => info.id,
        _ => return Err(anyhow!("Unexpected response type")),
    };

    println!("Using node public key: {}", pubkey);

    // For a real implementation, you would:
    // 1. Derive a domain-specific private key from the seed
    // 2. Sign the k1 bytes with that private key
    // 3. Send the signature along with the corresponding public key
    
    // This is a simplified version - you'd need to implement proper key derivation
    eprintln!("\n⚠️  Note: Full LNURL-auth implementation requires access to the node's seed");
    eprintln!("This is a simplified demonstration.");
    
    // For demo purposes, we'll show what would be sent
    println!("\nIn a full implementation, this would:");
    println!("1. Derive domain-specific key for: {}", url.domain().unwrap_or("unknown"));
    println!("2. Sign k1 bytes with that key");
    println!("3. Send GET to callback with sig= and key= parameters");

    Ok(())
}

fn main() {
    let command = match parse_args() {
        Ok(command) => command,
        Err(e) => {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    };
 

    let result = match command {
        Commands::RequestChannel { url } => {
            channel_request(&url)
        }
        Commands::RequestWithdraw { url, amount_msats } => {
            withdraw_request(&url, amount_msats)
        }
        Commands::Auth { url } => {
            auth_request(&url)
        }
    };

    if let Err(e) = result {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}
