CONTROL_PLANE_COUNT ?= 1
WORKER_COUNT ?= 1

default: capo-cluster.yaml

.PHONY: vars-check
vars-check:
	@if [ -z "$(CLUSTER_NAME)" ]; then \
		echo "CLUSTER_NAME is not set"; \
		false; \
	fi

.PHONY: cluster-with-crs/cluster-resources.yaml
cluster-with-crs/cluster-resources.yaml: vars
	kustomize build cluster-resources | \
		(source ./vars && clusterctl generate yaml) > $@

.PHONY: capo-cluster.yaml
capo-cluster.yaml: vars-check
	kustomize build cluster | \
		(source ./vars && clusterctl generate cluster \
			--control-plane-machine-count $(CONTROL_PLANE_COUNT) \
			--worker-machine-count $(WORKER_COUNT) --from - $(CLUSTER_NAME)) > $@

.PHONY: capo-cluster-with-crs.yaml
capo-cluster-with-crs.yaml: cluster-with-crs/cluster-resources.yaml vars-check
	kustomize build cluster-with-crs | \
		(source ./vars && clusterctl generate cluster \
			--control-plane-machine-count $(CONTROL_PLANE_COUNT) \
			--worker-machine-count $(WORKER_COUNT) --from - $(CLUSTER_NAME)) > $@

.PHONY: cluster-apply
cluster-apply: capo-cluster.yaml
	kubectl apply -f $< --server-side=true

.PHONY: cluster-with-crs-apply
cluster-with-crs-apply: capo-cluster.yaml
	kubectl apply -f $< --server-side=true
