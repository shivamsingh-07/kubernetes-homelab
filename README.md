# 🏠 Kubernetes Homelab

A multi-node [kind](https://kind.sigs.k8s.io/) Kubernetes cluster for bare-metal servers, with [MetalLB](https://metallb.universe.tf/) integration for native `LoadBalancer` service support.

## ✨ Overview

This project provisions a local Kubernetes homelab on bare metal using kind (Kubernetes IN Docker). It stands up a multi-node cluster and installs MetalLB so `Service` objects of type `LoadBalancer` receive real IPs — the same workflow you would use in a cloud environment, without a cloud provider.

| Component          | Purpose                                                     |
| ------------------ | ----------------------------------------------------------- |
| **kind**           | Multi-node Kubernetes cluster (1 control-plane + 2 workers) |
| **Calico**         | Container Network Interface (CNI)                           |
| **MetalLB**        | Layer-2 load balancer for `LoadBalancer` services           |
| **Metrics Server** | Resource metrics for `kubectl top` and HPA                  |

## 🗂️ Project Structure

```
kubernetes-homelab/
├── deploy-cluster.sh    # End-to-end cluster bootstrap
├── kind-config.yaml     # kind multi-node cluster definition
├── metallb-config.yaml  # MetalLB IP pool & L2 advertisement
└── README.md
```

## 📋 Prerequisites

- Docker
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## 🚀 Quick Start

```bash
chmod +x deploy-cluster.sh
./deploy-cluster.sh
```

The script will:

1. Create a multi-node kind cluster from `kind-config.yaml`
2. Label worker nodes
3. Install Calico CNI
4. Install MetalLB and apply the IP address pool
5. Install Metrics Server

## ⚙️ Configuration

### Cluster Topology

Node count and roles are configured in `kind-config.yaml`. Default layout:

- **1** control-plane node
- **2** worker nodes
- Default CNI disabled (Calico is installed separately)

Add or remove entries under `nodes` to change the cluster size.

Set `networking.apiServerAddress` to the bare-metal host IP so the API server is reachable remotely. The default (`192.168.29.250`) is environment-specific — update it to match your server before deploying.

### MetalLB Address Pool

Defined in `metallb-config.yaml`:

| Setting       | Value                               |
| ------------- | ----------------------------------- |
| Pool name     | `homelab-pool`                      |
| Address range | `172.18.100.200` – `172.18.100.250` |
| Advertisement | Layer 2 (`homelab-l2`)              |

Adjust the IP range to match your Docker/kind network as needed.

## ✅ Verify the Cluster

```bash
# Nodes
kubectl get nodes

# MetalLB
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system

# Metrics
kubectl top nodes
```

## 📦 Using a LoadBalancer Service

After deployment, create a service with `type: LoadBalancer`. MetalLB will assign an IP from the configured pool:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: example
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: example
```

```bash
kubectl get svc example
# EXTERNAL-IP will show an address from the MetalLB pool
```

## 🧹 Teardown

```bash
kind delete cluster --name homelab
```
