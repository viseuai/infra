# Edge stack

Traefik (reverse proxy + TLS) and the WireGuard mesh control plane with an
embedded DERP relay, running on the edge host. Deployed by
`iac/ansible/playbooks/edge.yml` to `/opt/viseu/edge`.

| Service | Exposure | Purpose |
|---|---|---|
| Traefik v3.6 | 80/443 | TLS termination and routing for all public services |
| headscale 0.26 | `mesh.viseuai.org` (via Traefik), 3478/udp (STUN) | Mesh control plane + DERP relay fallback |

The public hostname is deliberately neutral (`mesh.`): DNS records do not
reveal the software in use.

## Mesh operations (on the edge host)

All commands run from `/opt/viseu/edge`.

```sh
# list users / nodes
docker compose exec headscale headscale users list
docker compose exec headscale headscale nodes list

# create a pre-auth key for a new inference node (single-use, 24h, tagged)
docker compose exec headscale headscale preauthkeys create \
  --user 1 --expiration 24h --tags tag:node

# the same for the gateway service or the edge host itself
docker compose exec headscale headscale preauthkeys create \
  --user 1 --expiration 24h --tags tag:gateway
```

Joining a machine to the mesh (Tailscale client on the node):

```sh
tailscale up \
  --login-server https://mesh.viseuai.org \
  --auth-key <pre-auth-key>
```

## Access policy

`headscale/policy.json` enforces hub-and-spoke: `tag:gateway` reaches
`tag:node`; `tag:edge` reaches everything (monitoring, admin); nodes can
initiate nothing, so volunteer machines can never probe each other.

## Notes

- TLS certificates: Let's Encrypt HTTP-01 via Traefik, account
  `geral@viseuai.org`, stored in the `traefik-letsencrypt` volume.
- `DOCKER_API_VERSION` is pinned on Traefik because Docker Engine 29 raised
  the minimum API version; Traefik ≥ v3.6 is required for the same reason.
- MagicDNS base domain is `internal.viseuai.org`; those names resolve only
  on the mesh.
- DERP fallback: when NAT hole-punching fails, node traffic relays through
  this host over HTTPS; STUN runs on 3478/udp.
