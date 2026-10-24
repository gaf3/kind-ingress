# Design

Notes from the design talk, 2026-10-11. Milestones 1, 2 and 3 are built, and every cluster has a persistent MySQL.

## Names

`<service>.<namespace>.<cluster>.localhost`. Apps ship a plain Ingress with that host. No DNS install, no dnsmasq.

## Milestones

1. One cluster, Traefik, a service answering. Built.
2. Many clusters: a router owns host port 80 and sends `*.<cluster>.localhost` to that cluster's ingress. Any cluster can
   take the router role. Route changes must reload without a restart; file events across the Docker Desktop mount are
   untested, so write the file inside the container if they fail.
3. Calls between services: rewrite `*.localhost` to the router in each cluster's CoreDNS so a pod can use the public name,
   in or across clusters. Built (#2): `rewrite name regex ^(.+)\.localhost\.$ ingress-control-plane. answer auto`,
   with the hub's Traefik Service on node ports 80/443 so pods reach it on 80. Proven by `make test-cross`.

## Control plane (not built)

One central service that knows the registry and is the only thing that touches Docker, kind, helm and git.
Verbs: `register <repo>`, `up`, `down`, `kill`. Apps' `make up` and `make down` are thin clients of it, as is a web page.
It listens on 127.0.0.1 only and asks for a token on anything destructive. Dev only.

- `needs`: what must exist first. `owns`: what only the app creates.
- App `down` removes only what it owns. `kill` lives here, in the hub (and on the web page), and removes only what the
  control plane created, never a broad prune. The `desktop` and `dg-platform` kind clusters are not ours.
- `register` clones the repo, reads its needs, clones those too, and records everything in a registry.
- Everything is a YAML repo (cluster definitions, routers), versioned with git tags.
- Versions are plain `X.Y.Z`, tag equals `VERSION`, no `v`, no pre-releases. Requirements start as exact pins
  (`kind-ingress: 0.1.0`). Operators (`>=`, `<`, ranges) are allowed later through `packaging` specifiers; whatever
  resolves is recorded and only moves on an explicit `update`.
- `up --local` uses whatever is already checked out and says what it found.

## Tests

Apps test themselves. An app may add `make e2e` that runs against a running cluster by the URL convention. A separate
scenario repo, built later, owns topologies: one unum, or three clusters testing data syncing.

## Open

Data that must survive a `kill` has to live outside the cluster. MySQL is done: `~/.kind-data/<name>` is mounted into every node at `/data`. Other services decide per service, and can use the same directory. View-only versus controls on the web page.
