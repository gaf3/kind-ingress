# kind-ingress

A local multi-cluster dev environment for unum apps. kind clusters sit behind Traefik, and every service gets a URL that
says where it lives:

    <service>.<namespace>.<cluster>.localhost

`*.localhost` at any depth already resolves to loopback on macOS and in browsers, so there is no DNS to install. Dev only.

## Use

    make cluster NAME=unum    # kind cluster + Traefik, safe to run again
    make test    NAME=unum    # throwaway service answers at hello.default.unum.localhost
    make down    NAME=unum    # delete the cluster

The cluster holds host ports 80 and 443, so only one runs at a time for now.

## The one convention apps follow

An app ships an ordinary `Ingress` in its own manifests with the host `<service>.<namespace>.<cluster>.localhost`.
Nothing registers with anything. Traefik in the cluster sees the Ingress and routes it.

    rules:
    - host: ledger.ledger.unum.localhost

See [DESIGN.md](DESIGN.md) for where this is going.
