#!/bin/bash
# Copyright 2017 Istio Authors. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
################################################################################
# The script deploy etcd monitoring on OpenShift 3.11
set -e

Usage() {
   echo "---------------------------Usage---------------------------------------"
   echo "`basename $0`" 
   echo "make sure etcd ca.key and ca.cert are under ./etcd_monitoring"
   exit 1
}

CM_Patch() {
cat <<EOF > /tmp/etcd-patch.yaml
    etcd:
      targets:
        selector:
          openshift.io/component: etcd
          openshift.io/control-plane: "true"
EOF
if [ -f /tmp/etcd-patch.yaml ];then
   oc get cm cluster-monitoring-config -n openshift-monitoring -o yaml --export > /tmp/cluster-monitoring-config.yaml
   sed -i '3 r /tmp/etcd-patch.yaml' /tmp/cluster-monitoring-config.yaml
fi 
if [ -f /tmp/cluster-monitoring-config.yaml ]; then
   oc get cm cluster-monitoring-config -o yaml -n openshift-monitoring| grep etcd || oc apply -f /tmp/cluster-monitoring-config.yaml -n openshift-monitoring
   rm /tmp/cluster-monitoring-config.yaml /tmp/etcd-patch.yaml
fi
}
Self_Cert() {

cat <<EOF> openssl.cnf
[ req ]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, keyEncipherment, digitalSignature
extendedKeyUsage=serverAuth, clientAuth
EOF
openssl genrsa -out etcd.key 2048
openssl req -new -key etcd.key -out etcd.csr -subj "/CN=etcd" -config openssl.cnf
openssl x509 -req -in etcd.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd.crt -days 365 -extensions v3_req -extfile openssl.cnf
}

Create_Secret() {
cat <<-EOF > /tmp/etcd-cert-secret.yaml
apiVersion: v1
data:
  etcd-client-ca.crt: "$(cat ca.crt | base64 --wrap=0)"
  etcd-client.crt: "$(cat etcd.crt | base64 --wrap=0)"
  etcd-client.key: "$(cat etcd.key | base64 --wrap=0)"
kind: Secret
metadata:
  name: kube-etcd-client-certs
  namespace: openshift-monitoring
type: Opaque
EOF
oc apply -f /tmp/etcd-cert-secret.yaml -n openshift-monitoring 
rm /tmp/etcd-cert-secret.yaml
}

if [ -d etcd_monitoring  ];then
  rm -rf ./etcd_monitoring/etc/etcd/ca/ca.*
  cp /etc/etcd/ca/ca.crt /etc/etcd/ca/ca.key ./etcd_monitoring

else 
   mkdir etcd_monitoring
   cp /etc/etcd/ca/ca.crt /etc/etcd/ca/ca.key ./etcd_monitoring
fi

if [ -f /etc/etcd/ca/ca.crt ] && [ -f /etc/etcd/ca/ca.key ];then
     CM_Patch
     cd  etcd_monitoring
     Self_Cert
     Create_Secret
     cd ../ &&rm -rf etcd_monitoring
     ### create service monitor for OpenShift Router
     oc apply -f ../router/router-service-monitor.yaml
else 
     Usage
fi
