HUB=ingress
NAME?=tilt
CHART=41.7.1
STATE=$(HOME)/.kind-ingress/clusters
CTX=kind-$(NAME)
HUBCTX=kind-$(HUB)

.PHONY: vendor cluster up test test-cross scatter

# Maintainer step: render the chart once, split CRDs from the rest, record the version.
vendor:
	helm repo add traefik https://traefik.github.io/charts --force-update >/dev/null
	helm template traefik traefik/traefik --version $(CHART) --namespace traefik --include-crds --values vendor/values.yaml | python3 vendor/vendor.py
	echo $(CHART) > kubernetes/CHART

# Create the cluster if missing, then apply everything. NAME=ingress is the hub, the only one with host ports,
# its Traefik on node ports 80 and 443. Any other NAME needs the hub, which it brings up first, and gets a route
# in it. Every cluster's CoreDNS sends *.localhost to the hub, so pods use the public names. Safe to run again.
cluster:
	test $(NAME) = $(HUB) || $(MAKE) cluster NAME=$(HUB)
	kind get clusters | grep -qx $(NAME) || kind create cluster --name $(NAME) --config $(if $(filter $(NAME),$(HUB)),kind/hub.yaml,kind/cluster.yaml)
	mkdir -p $(dir $(STATE)) && touch $(STATE) && (grep -qx $(NAME) $(STATE) || echo $(NAME) >> $(STATE))
	kubectl --context $(CTX) apply --server-side -k kubernetes/$(if $(filter $(NAME),$(HUB)),hub,base)
	kubectl --context $(CTX) -n traefik rollout status deployment/traefik --timeout=180s
	kubectl --context $(CTX) apply --server-side --force-conflicts -f kubernetes/coredns/coredns.yaml
	kubectl --context $(CTX) -n kube-system rollout restart deployment/coredns
	kubectl --context $(CTX) -n kube-system rollout status deployment/coredns --timeout=120s
	test $(NAME) = $(HUB) || sed 's/__NAME__/$(NAME)/g' kubernetes/route/route.yaml | kubectl --context $(HUBCTX) apply -f -

up: cluster

# Deploy the throwaway service and fetch it through the hub on port 80 by its host name.
test:
	sed 's/__CLUSTER__/$(NAME)/g' test/hello.yaml | kubectl --context $(CTX) apply -f -
	kubectl --context $(CTX) rollout status deployment/hello --timeout=120s
	for i in $$(seq 1 30); do \
	curl -fsS http://hello.default.$(NAME).localhost/ | grep -q "Host: hello.default.$(NAME).localhost" && echo "ok" && exit 0; \
	sleep 2; done; echo "hello.default.$(NAME).localhost never answered" && exit 1

# Prove a pod in FROM reaches TO by its public name: TO's throwaway service, fetched from a pod in FROM through
# the hub. FROM and TO can be the same cluster. It's wget, not curl: curl sends every *.localhost to 127.0.0.1
# itself without asking DNS, so it never uses the rewrite.
FROM?=$(NAME)
TO?=$(NAME)
test-cross:
	$(MAKE) test NAME=$(TO)
	kubectl --context kind-$(FROM) run cross-$(TO) --rm -i --restart=Never --image=busybox:1.36 --command -- \
	sh -c 'for i in $$(seq 1 30); do \
	wget -q -T 5 -O - http://hello.default.$(TO).localhost/ | grep -q "Host: hello.default.$(TO).localhost" && echo "ok" && exit 0; \
	sleep 2; done; echo "hello.default.$(TO).localhost never answered from $(FROM)"; exit 1'

# Delete every cluster this repo ever created, no questions. Only the names in $(STATE); other kind clusters are not touched.
scatter:
	test -f $(STATE) && for n in $$(cat $(STATE)); do echo "scattering $$n"; kind delete cluster --name $$n; done; rm -f $(STATE)
