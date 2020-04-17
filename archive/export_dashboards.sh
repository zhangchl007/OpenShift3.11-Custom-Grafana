#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
protocol="https://"
KEY=`oc sa get-token grafana -n grafana`
grafana_host="${protocol}$( oc get route grafana -o jsonpath='{.spec.host}' -n grafana)"

if [ ! -d $SCRIPT_DIR/dashboards ] ; then
    mkdir -p $SCRIPT_DIR/dashboards
fi

for dash in $(curl -H "Authorization: Bearer eyJrIjoiY2JVaHlzc0FNQjVjc0NNWFEwNmNhdjBxbTRCYUdMbnkiLCJuIjoiYWRtaW4iLCJpZCI6MX0=" https://grafana-grafana.apps.ocp3.test01.com/api/search\?query\=\& | jq -r '.[] | .uri');
do
  curl -H "Authorization: Bearer eyJrIjoiY2JVaHlzc0FNQjVjc0NNWFEwNmNhdjBxbTRCYUdMbnkiLCJuIjoiYWRtaW4iLCJpZCI6MX0=" ${grafana_host}/api/dashboards/$dash | sed 's/"id":[0-9]\+,/"id":null,/' | sed 's/\(.*\)}/\1,"overwrite": true}/' | jq . > dashboards/$(echo ${dash} |cut -d\" -f 4 |cut -d\/ -f2).json
done
