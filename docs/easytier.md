## Easytier Node Config

- due to encryption, node config must use same format or command;
- for systemd-service, `NETWORK_NAME` and `NETWORK_SECRET` is not hidden in command and logs;

```shell
# example-cmd
easytier-core -c /etc/easytier/config.toml

# /etc/easytier/config.toml
instance_name = "default"
dhcp = true
listeners = [
     "tcp://0.0.0.0:11010",
     "udp://0.0.0.0:11010",
     "wg://0.0.0.0:11011",
     "ws://0.0.0.0:11011/",
     "wss://0.0.0.0:11012/",
]
exit_nodes = []
rpc_portal = "0.0.0.0:15888"

[network_identity]
network_name = "${NETWORK_NAME}"
network_secret = "${$NETWORK_SECRET}"

[[peer]]
uri = "tcp://public.easytier.top:11010"

[[proxy_network]]
cidr = "172.19.80.0/24"
[[proxy_network]]
cidr = "172.19.82.0/24"

[flags]
enable_kcp_proxy = true
latency_first = true
no_tun = true
relay_all_peer_rpc = true
relay_network_whitelist = ""

```
