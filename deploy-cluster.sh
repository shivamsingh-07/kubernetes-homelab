#!/bin/bash

set -e

echo "========================================"
echo " Creating homelab cluster"
echo "========================================"
kind create cluster --config=kind-config.yaml
kubectl label nodes -l '!node-role.kubernetes.io/control-plane' node-role.kubernetes.io/worker=

echo "========================================"
echo " Installing Calico CNI"
echo "========================================"
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/calico.yaml
kubectl patch ippool.crd.projectcalico.org default-ipv4-ippool \
    --type=merge \
    -p '{"spec":{"ipipMode":"Never","vxlanMode":"Always"}}'
kubectl patch bgpconfiguration.crd.projectcalico.org default \
    --type=merge \
    -p '{"spec":{"nodeToNodeMeshEnabled":false}}'

echo "========================================"
echo " Waiting for cluster to become Ready"
echo "========================================"
kubectl wait --for=condition=Ready pods -n kube-system --all --timeout=300s

echo "========================================"
echo " Installing MetalLB"
echo "========================================"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml
kubectl wait --for=condition=Ready pods -n metallb-system --all --timeout=300s
kubectl apply -f metallb-config.yaml

echo "========================================"
echo " Installing Metrics Server"
echo "========================================"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

echo "========================================"
echo " Cluster Created."
echo "========================================"
