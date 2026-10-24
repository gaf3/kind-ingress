# Changelog

## 0.3.0

- One cluster only: `ingress`, made with `kind create cluster --name ingress --config ingress/kind.yaml` and `kubectl apply -k ingress`. The folder `ingress/` is a kustomize base other repos can reference.
- Removed the multi-cluster pieces: other clusters, routes to them, the CoreDNS `*.localhost` rewrite, the widened node port range, the node ports on 80 and 443, `make test-cross`, `scatter` and the cluster-name conventions. The Makefile keeps only `vendor`.
- Traefik is on node ports 30080 and 30443, mapped to host ports 80 and 443 by kind.

## 0.2.0

- Pods use the public names: every cluster's CoreDNS answers `*.localhost` with the hub's node, `ingress-control-plane`, so a pod calls `<service>.<namespace>.<cluster>.localhost` the same way a browser does, in or across clusters (#2).
- The hub's Traefik Service is a NodePort on 80 and 443 themselves (node port range widened to `80-32767`), so pods on the kind network reach the hub on port 80 like the browser does. The range is set when the cluster is made: delete and make an existing hub again.
- `make test-cross FROM=a TO=b`: a pod in `a` fetches `b`'s throwaway service by its public name. It uses busybox `wget`, not curl: curl sends every `*.localhost` to 127.0.0.1 without asking DNS, so it never uses the rewrite. Proven a to b, b to a and a to a, and from Python on Alpine.
- The hub's node port range is set with kubeadm `extraArgs` as a map (`service-node-port-range: "80-32767"`), because kind hands kubeadm v1beta3 for this node image and refuses v1beta4's list of name and value. The hub's node ports are set by a JSON patch in `kubernetes/hub`, which picks the Service's ports by position (web, then websecure): check it again after `make vendor`.
- The CoreDNS Corefile is kind's own for kindest/node v1.35.0 plus the `rewrite`: check it again when the node image changes.

## 0.1.0

- `make cluster|down|test` for one kind cluster (Kubernetes v1.35.0) with Traefik chart 41.7.1 as a NodePort on host ports 80 and 443.
