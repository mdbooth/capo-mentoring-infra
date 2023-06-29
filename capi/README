* Create your kind cluster

When creating your kind cluster you MUST precreate the docker network with a
custom MTU. This is because the wireguard interface has an MTU of 1200, but
kind takes the MTU of your default interface, which is probably 1500. This
causes lots of weird networking issues.

If you already have a kind network (check with `docker network ls`), delete
your kind cluster and the network and start again.

Step 1: $ docker network create -o "com.docker.network.driver.mtu=1200" kind
Step 2: $ kind create cluster

* Initialise CAPI in kind

Set environment variable EXP_CLUSTER_RESOURCE_SET=true before running
clusterctl init. This enabled the ClusterResourceSet feature in CAPI, which
allows us to automatically install things in the deployed cluster.

* Configure `vars`

Copy vars.tmpl to vars, and fill out any necessary values. vars is used by the
Makefile when executing `clusterctl generate <foo>` as the source of template
values.

* Create a workload cluster

Create a cluster yaml with `make capo-cluster.yaml CLUSTER_NAME=<foo>`. This:
* Uses the kustomize configuration in the `cluster` directory
  * Based on the `without-lb` template from CAPO release 0.7
  * Adds CCM, which is required since kubernetes 1.26
* Pipes the output of kustomize through `clusterctl generate cluster` to
  template values

Inspect and modify this file if desired before creating the cluster with
`kubectl apply -f capo-cluster.yaml --server-side=true`.

N.B. Recommend using --server-side=true in general when doing kubectl apply or
you risk getting weird errors about annotations being too large due to the way
client-side apply works.

You can generate the cluster yaml and apply in a single step with
`make cluster-apply`.

* Get kubeconfig for the workload cluster

`clusterctl get kubeconfig <foo> > kubeconfig`

Use this kubeconfig with `export KUBECONFIG=$(pwd)/kubeconfig`.

You can then, e.g. inspect nodes on the workload cluster. Note that, unless
you've done the next step, they won't be Ready.

* Install services in the workload cluster to make the nodes ready

N.B. We don't necessarily need to do this step for our work on CAPO. CAPO
doesn't really care if the workload cluster is ready for use, only that it's
installed.

There's another kustomize directory, `cluster-resources`, which combines a CNI
and CCM configuration. You can generate yamls with
`kustomize build cluster-resources/`. Note that these still need to be
templated by `clusterctl generate yaml` before use.

`make cluster-with-crs/cluster-resources.yaml` will do both of these steps for
you.

Using the workload cluster KUBECONFIG, apply
cluster-with-crs/cluster-resources.yaml to the workload cluster. You can watch
pods being created and initialised with `kubectl get pod -Aw`. When everything
is stable you will see that the nodes are read with `kubectl get node`.

* Install services in the workload cluster automatically

N.B. CRS is deprecated in CAPI and will be removed soon, but it still works for
now.

CRS is a feature of CAPI which will automatically install services in the
workload cluster when it comes up. See the Makefile to find out how it is
implemented here.
