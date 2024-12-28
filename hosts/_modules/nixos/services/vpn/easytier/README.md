# Easytier Node Config

- due to encryption, node config must use same format;

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
network_name = "$NETWORK_NAME"
network_secret = "$NETWORK_SECRET"

[[peer]]
uri = "tcp://public.easytier.top:11010"
[[peer]]
uri = "tcp://gz.minebg.top:11010"
[[peer]]
uri = "wss://gz.minebg.top:11012"
[[peer]]
uri = "tcp://156.231.117.80:11010"
[[peer]]
uri = "wss://156.231.117.80:11012"
[[peer]]
uri = "tcp://public.easytier.net:11010"
[[peer]]
uri = "wss://public.easytier.net:11012"
[[peer]]
uri = "tcp://public.server.soe.icu:11010"
[[peer]]
uri = "wss://public.server.soe.icu:11012"
[[peer]]
uri = "tcp://ah.nkbpal.cn:11010"
[[peer]]
uri = "wss://ah.nkbpal.cn:11012"
[[peer]]
uri = "tcp://et.gbc.moe:11011"
[[peer]]
uri = "wss://et.gbc.moe:11012"
[[peer]]
uri = "tcp://et.pub.moe.gift:11111"
[[peer]]
uri = "wss://et.pub.moe.gift:11111"
[[peer]]
uri = "tcp://et.01130328.xyz:11010"
[[peer]]
uri = "tcp://47.103.35.100:11010"
[[peer]]
uri = "tcp://et.ie12vps.xyz:11010"
[[peer]]
uri = "tcp://116.206.178.250:11010"
[[peer]]
uri = "tcp://x.cfgw.rr.nu:11010"

[[proxy_network]]
cidr = "172.19.80.0/24"
[[proxy_network]]
cidr = "172.19.82.0/24"

[flags]
default_protocol = "udp"
enable_ipv6 = false
latency_first = true

# /etc/easytier/.env
NETWORK_NAME=
NETWORK_SECRET=

```
