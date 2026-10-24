CHART=41.7.1

.PHONY: vendor

# Maintainer step: render the chart once, split CRDs from the rest, record the version.
vendor:
	helm repo add traefik https://traefik.github.io/charts --force-update >/dev/null
	helm template traefik traefik/traefik --version $(CHART) --namespace traefik --include-crds --values vendor/values.yaml | python3 vendor/vendor.py
	echo $(CHART) > ingress/CHART
