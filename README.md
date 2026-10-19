# 🐳 caddy-cloudflare-crowdsec

[![DockerHub](https://img.shields.io/badge/DockerHub-580132%2Fcaddy--cloudflare--crowdsec-blue?style=flat)](https://hub.docker.com/r/580132/caddy-cloudflare-crowdsec)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/580132/caddy-cloudflare-crowdsec?label=Latest%20Version)](https://github.com/580132/caddy-cloudflare-crowdsec/tags)
[![Docker Build & Release](https://github.com/580132/caddy-cloudflare-crowdsec/actions/workflows/docker.yml/badge.svg)](https://github.com/580132/caddy-cloudflare-crowdsec/actions/workflows/docker.yml)
[![License](https://img.shields.io/github/license/580132/caddy-cloudflare-crowdsec)](https://github.com/580132/caddy-cloudflare-crowdsec/blob/main/LICENSE)
[![Dependabot](https://img.shields.io/badge/Dependabot-0366d6?style=flat&logo=dependabot&logoColor=white)](.github/dependabot.yml)

The [Caddy](https://hub.docker.com/_/caddy) Docker image with the added

- [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare) module for
  DNS-01 ACME validation support
- [CrowdSec bouncers](https://github.com/hslatman/caddy-crowdsec-bouncer)
  (HTTP, AppSec and Layer 4) for blocking malicious traffic based on
  decisions made by [CrowdSec](https://crowdsec.net/)
- [caddy-l4](https://github.com/mholt/caddy-l4) and
  [transform-encoder](https://github.com/caddyserver/transform-encoder)

Built for the same platforms as the upstream Caddy project (except Windows, sorry)!

> [!NOTE]
> This image does not change anything with original Caddy Docker image except
> replace the `caddy` binary.

```sh
# Docker Hub
docker pull 580132/caddy-cloudflare-crowdsec:latest

# GHCR
docker pull ghcr.io/580132/caddy-cloudflare-crowdsec:latest
```

## Tags

The following tags are the latest available for the
`580132/caddy-cloudflare-crowdsec` image.

<!--START-TAGS-->
- [`latest`](https://github.com/580132/caddy-cloudflare-crowdsec/tree/v2.11.7)
- [`2.11.7`](https://github.com/580132/caddy-cloudflare-crowdsec/tree/v2.11.7)
- [`2.11`](https://github.com/580132/caddy-cloudflare-crowdsec/tree/v2.11)
- [`2`](https://github.com/580132/caddy-cloudflare-crowdsec/tree/v2)
<!--END-TAGS-->

Check the GitHub
[Tags](https://github.com/580132/caddy-cloudflare-crowdsec/tags)
for a list of all versions!

## Usage

### Docker

Since this is built off the official Docker image all of the same Volumes,
Environment variables, etc. can be used with this container. Please refer to the
official [Caddy](https://hub.docker.com/_/caddy) Docker image and
[docs](https://caddyserver.com/docs/) for more information on using Caddy.

Simply create the container as usual and include your `CF_API_TOKEN` (email no
longer required for API Tokens). We can utilize Caddy's support for
[Environment varaiables](https://caddyserver.com/docs/caddyfile/concepts#environment-variables)
to pass these values into our `Caddyfile`.

> [!IMPORTANT]
> Be sure to create your `Caddyfile` beforehand to avoid Docker startup errors.

```sh
docker run --rm -it \
  --name caddy \
  -p 80:80 \
  -p 443:443 \
  -v caddy_data:/data \
  -v caddy_config:/config \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
  -e CF_API_TOKEN=UhKLc...JD9jk \
  580132/caddy-cloudflare-crowdsec:latest
```

If you prefer `docker-compose` you can use the provided
[`docker-compose.yml`](docker-compose.yml) after updating it with your
`CF_API_TOKEN`.

```sh
docker compose up
```

### Caddy

Set the global
[acme_dns](https://caddyserver.com/docs/caddyfile/options#acme-dns) directive
in your `Caddyfile`

```Caddyfile
{
  acme_dns cloudflare {env.CF_API_TOKEN}
}
```

or via JSON

```json
{
  "module": "acme",
  "challenges": {
    "dns": {
      "provider": {
        "name": "cloudflare",
        "api_token": "{env.CF_API_TOKEN}"
      }
    }
  }
}
```

See the [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare) module
and [`tls`](https://caddyserver.com/docs/caddyfile/directives/tls#tls) directive
for advanced usage.

### CrowdSec

The image bundles the [CrowdSec bouncer for Caddy](https://github.com/hslatman/caddy-crowdsec-bouncer),
which blocks malicious traffic based on the decisions made by your
[CrowdSec](https://crowdsec.net/) Security Engine.

| Module | Directive | Purpose |
| ------ | --------- | ------- |
| `http` | `crowdsec` | Checks the client IP of incoming HTTP requests against CrowdSec decisions |
| `appsec` | `appsec` | Checks incoming HTTP requests against the rulesets of a CrowdSec AppSec component |
| `layer4` | `crowdsec` (matcher) | Matches TCP/UDP IP addresses against the CrowdSec Local API, for non-HTTP traffic |

All three share a single Caddy app, so the Local API credentials only have to
be configured once in the global options.

#### Enabling the bouncer

Declare the `crowdsec` global option, then use the `crowdsec` directive in
your site block:

```Caddyfile
{
  crowdsec {
    api_url http://crowdsec:8080
    api_key {env.CROWD_SEC_API_KEY}
    ticker_interval 15s
  }
}

example.com {
  route {
    crowdsec
    reverse_proxy localhost:3000
  }
}
```

The `api_key` is the value of a bouncer registered on your CrowdSec instance:

```sh
docker exec crowdsec cscli bouncers add caddy-bouncer
```

#### Configuration options

| Option | Description | Default |
| ------ | ----------- | ------- |
| `api_url` | The URL of the CrowdSec Local API. | `http://127.0.0.1:8080/` |
| `api_key` | The API key to authenticate with the Local API. | *required* |
| `disable_streaming` | Falls back to LiveBouncer mode (queries the API per request). | `false` |
| `ticker_interval` | Interval for pulling decisions from the Local API. | `60s` |
| `metrics_interval` | Interval for pushing metrics to the Local API. | `0s` (disabled) |
| `enable_caddy_metrics` | Enables emitting bouncer metrics at Caddy's `/metrics` endpoint. | `false` |
| `enable_hard_fails` | Caddy fails to start if the CrowdSec API is unreachable. | `false` |
| `appsec_url` | The URL of the CrowdSec AppSec component. | *disabled* |
| `appsec_max_body_bytes` | Maximum request body size sent to AppSec. | `0` (full request) |
| `appsec_max_timeout` | Maximum time for a request to the AppSec component. | `2s` |
| `appsec_fail_open` | Ignore AppSec component connection errors. | `false` |
| `enable_caddy_error` | Propagates decisions as Caddy errors, to allow custom error pages. | `false` |

> [!WARNING]
> When enabling `enable_caddy_error`, make sure `handle_errors` routes are
> strictly static, to avoid resource exhaustion (DoS).

#### AppSec

If you run a [CrowdSec AppSec](https://docs.crowdsec.net/u/appsec_bouncer/intro)
component, point the bouncer at it and add the `appsec` directive:

```Caddyfile
{
  crowdsec {
    api_url http://crowdsec:8080
    api_key {env.CROWD_SEC_API_KEY}
    appsec_url http://crowdsec-appsec:7422
  }
}

example.com {
  route {
    crowdsec
    appsec
    reverse_proxy localhost:3000
  }
}
```

#### Layer 4

The Layer 4 matcher blocks TCP and UDP traffic by IP address, using the
[caddy-l4](https://github.com/mholt/caddy-l4) app:

```Caddyfile
{
  crowdsec {
    api_url http://crowdsec:8080
    api_key {env.CROWD_SEC_API_KEY}
  }

  layer4 {
    :443 {
      @crowdsec crowdsec
      route @crowdsec {
        proxy {
          upstream localhost:8443
        }
      }
    }
  }
}
```

#### Client IP

The bouncer relies on Caddy's native client IP detection. Caddy uses the
`X-Forwarded-For` header by default, so if you run behind a proxy or CDN you
**must** configure the
[`trusted_proxies`](https://caddyserver.com/docs/json/apps/http/servers/#trusted_proxies)
global directive, otherwise every request will be checked against the proxy's
IP address.

```Caddyfile
{
  trusted_proxies static private_ranges
}
```

#### Blocked request details

The HTTP and AppSec handlers record why a request was blocked, so matchers and
logs can tell blocks apart:

| Variable | Description | Examples |
| -------- | ----------- | -------- |
| `{http.vars.crowdsec.module}` | The handler that blocked the request. | `http`, `appsec` |
| `{http.vars.crowdsec.remediation}` | The remediation that was applied. | `ban`, `captcha`, `throttle` |
| `{http.vars.crowdsec.origin}` | The origin of the decision. | `appsec`, `crowdsec`, `lists:foo` |
| `{http.vars.crowdsec.duration}` | The duration of the decision. | `3h59m58s` |

```Caddyfile
handle_errors {
  log_append blocked-by {http.vars.crowdsec.module}
}
```

#### Runtime utilities

Building Caddy with the bouncer also enables the `caddy crowdsec` command, which
talks to the Caddy Admin API to inspect the integration:

```sh
caddy crowdsec health    # check the integration health
caddy crowdsec info      # show runtime information
caddy crowdsec ping      # ping the Local API endpoint
caddy crowdsec check <IP> # check whether an IP is banned
```

> [!NOTE]
> The `caddy crowdsec` command is currently experimental.

### Creating a Cloudflare API Token

You can generate a Cloudflare API token via the Cloudflare web console using the following steps:

1. Login to your [Dashboard](https://dash.cloudflare.com/)
2. Go to [Account Profile](https://dash.cloudflare.com/profile) > [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
3. Click "Create token" (Use the "Create Custom Token" option)
4. Grant the following permissions:
   - `Zone > Zone > Read`
   - `Zone > DNS > Edit`

## Building

You can easily build the Docker image locally by doing

```sh
docker build -t caddy-cloudflare-crowdsec .
```

If you prefer `docker-compose` you can use the provided
[`docker-compose.yml`](docker-compose.yml) for building

```sh
docker compose build
```

## Container signatures

All container images will be automatically signed via
[Cosign](https://docs.sigstore.dev/cosign/overview/) using
[keyless signatures](https://docs.sigstore.dev/cosign/keyless/). You can use the
following command to verify the integrity of these images yourself.

```sh
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp https://github.com/580132/caddy-cloudflare-crowdsec/.github/workflows/ \
  580132/caddy-cloudflare-crowdsec:latest
```

## Contributing

Feel free to contribute and make things better by opening an
[Issue](https://github.com/580132/caddy-cloudflare-crowdsec/issues) or
[Pull Request](https://github.com/580132/caddy-cloudflare-crowdsec/pulls).

## License

See [LICENSE](https://github.com/580132/caddy-cloudflare-crowdsec/blob/main/LICENSE).
