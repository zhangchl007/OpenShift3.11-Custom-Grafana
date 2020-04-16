# Openshift 3.11 custom Grafana Dashboards

Due to the readonly grafan with Openshift 3.11 CMO, this example creates a custom Grafana instance and It uses "OAuth" token to login Grafana,
which was inspired by "https://github.com/openshift/origin/tree/master/examples/grafana"

## Available Dashboards
- k8s-compute-resources-cluster
- k8s-compute-resources-namespace
- k8s-compute-resources-pod
- k8s-use-method-cluster
- k8s-use-method-node
- OpenShift-Cluster-Overview

istio dashboard will be added soon

# Add etcd service monitoring for Prometheus Operator
```
oc -n openshift-monitoring edit configmap cluster-monitoring-config

data:
  config.yaml: |+
    ...
    etcd:
      targets:
        selector:
          openshift.io/component: etcd
          openshift.io/control-plane: "true"
```
on the master server,execute the script

```
config_etcd_monitoring.sh

```

### Run the deployment script
``` 
./setup-grafana.sh -n <any_datasorce_name> 
```
for more info ```./setup-grafana.sh -h```

![install](https://github.com/zhangchl007/OpenShift3.11-Custom-Grafana/blob/master/archive/img1.png)

![gui](https://github.com/zhangchl007/OpenShift3.11-Custom-Grafana/blob/master/archive/img2.png)


#### Pull standalone docker grafana instance
to build standalone docker instance see
https://github.com/mrsiano/grafana-ocp

#### Resources 
- example video https://youtu.be/srCApR_J3Os
- deploy openshift prometheus: https://docs.openshift.com/container-platform/3.11/install_config/prometheus_cluster_monitoring.html
