// This file is copied from:
// https://github.com/caddyserver/caddy/blob/master/cmd/caddy/main.go

package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	// plug in Caddy modules here
	_ "github.com/caddyserver/caddy/v2/modules/standard"
	_ "github.com/caddy-dns/cloudflare"
)

func main() {
	caddycmd.Main()
}