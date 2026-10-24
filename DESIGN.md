# Design

Notes from the design talk, 2026-10-11.

## Names

A `.localhost` host, such as `<service>.localhost`. Apps ship a plain Ingress with that host. No DNS install, no dnsmasq.

## Milestones

1. One cluster, Traefik, a service answering. Built.
2. Many clusters behind a router, and pods calling services by their public names, were built and then removed in 0.3.0:
   this repo makes the one ingress cluster and nothing else. See 0.2.0 in git history (#3) if it comes back.

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

Data that must survive a `kill` has to live outside the cluster. Decide per service. View-only versus controls on the web page.
