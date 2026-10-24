# Changelog

## 0.3.0

- Every cluster comes with a MySQL 8.4 (`mysql.mysql:3306`, root, password `root`, local only). Its data is `~/.kind-data/<name>` on the host, mounted into the node at `/data` by kind's `extraMounts`, so it survives deleting and making the cluster again. Apps create their own databases as root on first deploy; cluster setup knows nothing about them.
- `make down NAME=` deletes the cluster and keeps the data. `make wipe NAME=` deletes the data, and refuses while the cluster is up. `make scatter` keeps data too.
- `make cluster` fails with the fix if an existing cluster has no `/data` mount, because MySQL would otherwise write to the node's own disk and lose it. The mount only happens when the cluster is made: delete and make an older cluster again.
- `make test-data` runs a throwaway app that creates its database if missing, migrates and writes a row, logging each. `make test-persist` wipes, makes the cluster, deploys, deletes the cluster, makes it again and deploys again, checking the database exists and the first row is still there.

## 0.2.0

- Pods use the public names: every cluster's CoreDNS answers `*.localhost` with the hub's node, `ingress-control-plane`, so a pod calls `<service>.<namespace>.<cluster>.localhost` the same way a browser does, in or across clusters (#2).
- The hub's Traefik Service is a NodePort on 80 and 443 themselves (node port range widened to `80-32767`), so pods on the kind network reach the hub on port 80 like the browser does. The range is set when the cluster is made: delete and make an existing hub again.
- `make test-cross FROM=a TO=b`: a pod in `a` fetches `b`'s throwaway service by its public name. It uses busybox `wget`, not curl: curl sends every `*.localhost` to 127.0.0.1 without asking DNS, so it never uses the rewrite. Proven a to b, b to a and a to a, and from Python on Alpine.
- The hub's node port range is set with kubeadm `extraArgs` as a map (`service-node-port-range: "80-32767"`), because kind hands kubeadm v1beta3 for this node image and refuses v1beta4's list of name and value. The hub's node ports are set by a JSON patch in `kubernetes/hub`, which picks the Service's ports by position (web, then websecure): check it again after `make vendor`.
- The CoreDNS Corefile is kind's own for kindest/node v1.35.0 plus the `rewrite`: check it again when the node image changes.

## 0.1.0

- `make cluster|down|test` for one kind cluster (Kubernetes v1.35.0) with Traefik chart 41.7.1 as a NodePort on host ports 80 and 443.
