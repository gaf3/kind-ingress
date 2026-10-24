# kind-ingress

One kind cluster, `ingress`, running Traefik, for local apps. Dev only.

    kind create cluster --name ingress --config ingress/kind.yaml
    kubectl --context kind-ingress apply --server-side -k ingress

It holds host ports 80 and 443, so there is only one. `*.localhost` at any depth already resolves to loopback on macOS and
in browsers, so there is no DNS to install.

## The one convention apps follow

An app ships an ordinary `Ingress` in its own manifests with a `.localhost` host. Nothing registers with anything. Traefik
sees the Ingress and routes it.

    rules:
    - host: ledger.localhost

Try it with the throwaway service:

    kubectl --context kind-ingress apply -f test/hello.yaml
    curl http://hello.default.localhost/

## From another repo

The cluster is made with `kind create cluster` as above, since kustomize can't make it. The Traefik part can be referenced:

    resources:
    - github.com/gaf3/kind-ingress/ingress?ref=main

See [DESIGN.md](DESIGN.md) for where this is going.
