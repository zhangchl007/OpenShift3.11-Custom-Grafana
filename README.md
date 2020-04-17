# Openshift 3.11 custom Grafana Dashboards

Due to the readonly grafan with Openshift 3.11 CMO, this example creates a custom Grafana instance and It uses "OAuth" token to login Grafana,
which was inspired by "origin grafana example"

## Available Dashboards
- k8s-compute-resources-cluster
- k8s-compute-resources-namespace
- k8s-compute-resources-pod
- k8s-use-method-cluster
- k8s-use-method-node
- OpenShift-Cluster-Overview

istio dashboard will be added soon

# Add etcd servicemonitor for Prometheus Operator

This part would be also completed by the script: deploy_etcd_monitoring.sh
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
Execute the script below on OpenShift Master server

```
deploy_etcd_monitoring.sh

```

### Run the deployment script
``` 
./setup-grafana.sh -n prometheus

```
for more info ```./setup-grafana.sh -h```

![gui](https://github.com/zhangchl007/OpenShift3.11-Custom-Grafana/blob/master/archive/img2.png)

# Grafana data persistance

Suppose nfs provisoner is using for your OCP Cluster

```
cat <<EOF>  grafana-db.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: grafana-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: managed-nfs-storage
EOF

oc create -f grafana-db.yaml

oc set volume deploy grafana  --add --overwrite --name=grafana-data --type=pvc --claim-name=grafana-data

````

#### Resources 
- grafana example https://github.com/openshift/origin/tree/master/examples/grafana
- deploy openshift prometheus: https://docs.openshift.com/container-platform/3.11/install_config/prometheus_cluster_monitoring.html
