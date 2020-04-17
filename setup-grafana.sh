#!/bin/bash
datasource_name=''
prometheus_namespace="openshift-monitoring"
sa_reader=''
graph_granularity=''
yaml=''
protocol="https://"

while getopts 'n:s:p:g:y' flag; do
  case "${flag}" in
    n) datasource_name="${OPTARG}" ;;
    s) sa_reader="${OPTARG}" ;;
    p) grafana_namespace="${OPTARG}" ;;
    g) graph_granularity="${OPTARG}" ;;
    y) yaml="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

usage() {
echo "
USAGE
 setup-grafana.sh -n <datasource_name> [optional: -p <prometheus_namespace> -s <prometheus_serviceaccount> -g <graph_granularity> -y <yaml>]

 switches:
   -n: grafana datasource name
   -s: prometheus serviceaccount name
   -p: existing prometheus name e.g openshift-metrics
   -g: specifiy granularity
   -y: specifies the grafana yaml
"
exit 1
}

get::namespace(){
    grafana_namespace="grafana"
}

# import grafana dashboards
dashboard::importer(){
dashboard_file=$1
sed -i.bak "s/Xs/${graph_granularity}/" "${dashboard_file}"
sed -i.bak "s/\${DS_PR}/${datasource_name}/" "${dashboard_file}"
curl --insecure -H "Content-Type: application/json" -u admin:admin "${grafana_host}/api/dashboards/db" -X POST -d "@./${dashboard_file}"
mv "${dashboard_file}.bak" "${dashboard_file}"
}
[[ -n ${datasource_name} ]] || usage
[[ -n ${sa_reader} ]] || sa_reader="prometheus-k8s"
[[ -n ${grafana_namespace} ]] || get::namespace
[[ -n ${graph_granularity} ]]  || graph_granularity="2m"
[[ -n ${yaml} ]] || yaml="grafana.yaml"


oc new-project ${grafana_namespace}
oc adm policy add-cluster-role-to-user system:auth-delegator -z grafana -n ${grafana_namespace}
oc process -f "${yaml}" --param NAMESPACE=${grafana_namespace} |oc create -f -
oc rollout status deployment/grafana
grafana_host="${protocol}$( oc get route grafana -o jsonpath='{.spec.host}' -n ${grafana_namespace})"
until [ `curl --insecure -H "Content-Type: application/json" -u admin:admin "${grafana_host}/metrics" |grep ^go_goroutines | wc -l` -eq 1 ]
do
  echo "Waiting for grafana readiness!"
done
#oc adm policy add-cluster-role-to-user system:auth-delegator -z grafana -n ${grafana_namespace}

payload="$( mktemp )"
cat <<EOF >"${payload}"
{
"name": "${datasource_name}",
"type": "prometheus",
"typeLogoUrl": "",
"access": "proxy",
"url": "https://$( oc get route prometheus-k8s -n "${prometheus_namespace}" -o jsonpath='{.spec.host}' )",
"basicAuth": false,
"withCredentials": false,
"jsonData": {
    "tlsSkipVerify":true,
    "httpHeaderName1":"Authorization"
},
"secureJsonData": {
    "httpHeaderValue1":"Bearer $( oc sa get-token "${sa_reader}" -n "${prometheus_namespace}" )"
}
}
EOF

# setup grafana data source
curl --insecure -H "Content-Type: application/json" -u admin:admin "${grafana_host}/api/datasources" -X POST -d "@${payload}"

# deploy openshift dashboard
cd dashboards
for i in `ls *.json`;
do 
  dashboard::importer $i
done
cd ../
exit 0
