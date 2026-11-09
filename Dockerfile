# syntax=docker/dockerfile:1
FROM caddy:2.11.8-builder AS builder
RUN xcaddy build \
  --with github.com/mholt/caddy-l4 \
  --with github.com/caddyserver/transform-encoder \
  --with github.com/hslatman/caddy-crowdsec-bouncer/http@main \
  --with github.com/hslatman/caddy-crowdsec-bouncer/appsec@main \
  --with github.com/hslatman/caddy-crowdsec-bouncer/layer4@main \
  --with github.com/caddy-dns/cloudflare

FROM caddy:2.11.8 AS caddy
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
