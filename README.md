# kind-ingress

A local multi-cluster dev environment for local apps. kind clusters sit behind Traefik, and every service gets a URL that
says where it lives:

    <service>.<namespace>.<cluster>.localhost

`*.localhost` at any depth already resolves to loopback on macOS and in browsers, so there is no DNS to install. Dev only.

## Use

    make cluster NAME=unum    # kind cluster + Traefik, safe to run again
    make test    NAME=unum    # throwaway service answers at hello.default.unum.localhost
    make test-cross FROM=a TO=b  # a pod in a reaches b's throwaway service by its public name
    make test-data NAME=unum  # throwaway app creates its database in the cluster's MySQL and writes a row
    make down    NAME=unum    # delete the cluster, keep its data
    make wipe    NAME=unum    # delete the data too, for good (the cluster has to be down)

The cluster holds host ports 80 and 443, so only one runs at a time for now.

## The database

Every cluster has a MySQL at `mysql.mysql:3306`, user `root`, password `root`. Local only, the password is public on purpose.
Its data lives on the Mac at `~/.kind-data/<name>`, mounted into the node at `/data`, so it survives `make down` and making
the cluster again. The cluster owns that directory. Only `make wipe` removes it.

Cluster setup knows nothing about apps. On first deploy an app connects as root, creates its database if it's missing,
runs its migrations and logs that it did. `test/data.yaml` is the smallest example, and `make test-persist NAME=unum` proves
the data outlives the cluster (it wipes `~/.kind-data/unum` first).

The mount is set when the cluster is made, so a cluster from before this has to be deleted and made again.

## The one convention apps follow

An app ships an ordinary `Ingress` in its own manifests with the host `<service>.<namespace>.<cluster>.localhost`.
Nothing registers with anything. Traefik in the cluster sees the Ingress and routes it.

The same name works from a pod, in or across clusters: CoreDNS sends `*.localhost` to the hub.

    rules:
    - host: ledger.ledger.unum.localhost

See [DESIGN.md](DESIGN.md) for where this is going.
