# Exercise 2: Multi-Replica Web App with RWX Storage

This exercise demonstrates **ReadWriteMany (RWX) access mode** with multiple pod replicas sharing the same persistent storage in Kubernetes.

## Overview

This exercise shows how multiple replicas of a web application can:
- Share the same storage volume
- Read and write files simultaneously
- Access the same data across pods

**Key Concepts:**
- **ReadWriteMany (RWX):** Multiple pods on the same node can read and write to the same volume
- **HostPath Storage:** Direct node-level storage access using host filesystem
- **Persistent Volumes (PV):** Cluster-level storage resource
- **Persistent Volume Claims (PVC):** Pod-level storage request
- **Multi-Replica Deployments:** Running multiple identical pods with shared storage

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Exercise 2 Architecture                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Node: k3d-storage-lab-server-0                        │
│  ┌───────────────────────────────────────────┐         │
│  │ HostPath: /tmp/shared-data                │         │
│  │ (Shared storage on node filesystem)       │         │
│  └──────────┬──────────────────────────────┬─┘         │
│             │                              │            │
│    ┌────────▼────────┐        ┌────────────▼────────┐  │
│    │  WebApp Pod 1   │        │  WebApp Pod 2       │  │
│    │ (nginx:alpine)  │        │ (nginx:alpine)      │  │
│    │ Shared Index    │        │ Shared Index        │  │
│    └─────────────────┘        └─────────────────────┘  │
│                                                         │
│                      ┌──────────────────────────────┐   │
│                      │  WebApp Pod 3                │   │
│                      │ (nginx:alpine)               │   │
│                      │ Shared Index                 │   │
│                      └──────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
       ↓ (All pods mount shared storage via PVC)
   ┌──────────────────────┐
   │  shared-web-pvc      │
   │    (2Gi, RWX)        │ ← ReadWriteMany Access Mode
   └────────      ├─────────────┘
            │
   ┌────────▼──────────────┐
   │  shared-storage-pv    │
   │  (HostPath)           │
   │  /tmp/shared-data     │
   └───────────────────────┘
```

## Files and Configuration

| File | Purpose |
|------|---------|
| `01-shared-storage.yaml` | PersistentVolume and PersistentVolumeClaim using HostPath with RWX access |
| `02-webapp-deployment.yaml` | nginx deployment with 3 replicas, all mounting shared storage; includes init container for setup |
| `05-test-script.sh` | Test script to verify RWX functionality |
| `setup.sh` | Deployment script that applies all manifests |

## Quick Start

### 1. Deploy Resources
```bash
# Make scripts executable
chmod +x setup.sh 05-test-script.sh

# Deploy storage and web app
./setup.sh
```

**What this does:**
- Creates `exercise-2` namespace
- Creates PersistentVolume using HostPath at `/tmp/shared-data`
- Creates PersistentVolumeClaim requesting RWX storage
- Deploys 3 nginx web app replicas with init containers that populate shared storage

### 2. Wait for Ready Pods
```bash
# Check pod status
kubectl get pods -n exercise-2

# Expected output (all should show 1/1 Running):
NAME                       READY   STATUS    RESTARTS   AGE
webapp-574d944bb5-9sj82    1/1     Running   0          1m
webapp-574d944bb5-d57vc    1/1     Running   0          1m
webapp-574d944bb5-ngshx    1/1     Running   0          1m
```

### 3. Test RWX Functionality
```bash
# Run comprehensive test
./05-test-script.sh
```

**Test includes:**
- Each pod writes unique files to shared storage
- All pods can read all files (verifies RWX)
- Creates shared HTML content
- Tests HTTP access via port-forward

### 4. Access the Web App
```bash
# Port-forward to web service
kubectl port-forward -n exercise-2 svc/webapp-service 8080:80

# In another terminal, open browser or curl:
curl http://localhost:8080
```

## Storage Details

### PersistentVolume (shared-storage-pv)
```yaml
Capacity: 2Gi
Access Modes: ReadWriteMany (RWX)
Reclaim Policy: Retain
Storage Type: HostPath (/tmp/shared-data)
Node Affinity: k3d-storage-lab-server-0
```

### PersistentVolumeClaim (shared-web-pvc)
```yaml
Capacity: 2Gi
Access Modes: ReadWriteMany (RWX)
Bound Volume: shared-storage-pv
Status: Bound
Storage Class: None (manual binding)
```

## Verify Shared Storage Access

### Method 1: Check files from each pod
```bash
# From pod 1
kubectl exec -n exercise-2 <pod1-name> -- ls -la /usr/share/nginx/html/

# From pod 2 (will see same files)
kubectl exec -n exercise-2 <pod2-name> -- ls -la /usr/share/nginx/html/
```

### Method 2: Write from one pod, read from another
```bash
# Write from pod 1
kubectl exec -n exercise-2 <pod1> -- sh -c "echo 'Hello from pod1' > /usr/share/nginx/html/shared.txt"

# Read from pod 2
kubectl exec -n exercise-2 <pod2> -- cat /usr/share/nginx/html/shared.txt
# Output: Hello from pod1
```

### Method 3: Check storage status
```bash
# View PV and PVC
kubectl get pv,pvc -n exercise-2

# Detailed PVC info
kubectl describe pvc shared-web-pvc -n exercise-2
```

## Troubleshooting

### Pods stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name> -n exercise-2

# Check node affinity is met
kubectl get nodes -L kubernetes.io/hostname
```

### PVC not binding
```bash
# Check PV status
kubectl get pv shared-storage-pv -o yaml

# Check PVC status
kubectl get pvc shared-web-pvc -n exercise-2 -o yaml

# Ensure PV and PVC access modes match (both RWX)
kubectl describe pvc shared-web-pvc -n exercise-2
```

### Pods not reaching Ready state
```bash
# Check pod logs
kubectl logs -n exercise-2 <pod-name>

# Check for init container issues
kubectl logs -n exercise-2 <pod-name> -c init-storage

# Verify shared storage was created
kubectl exec -n exercise-2 <pod-name> -- ls -la /usr/share/nginx/html/
```

### Web app returns 403 or 404
```bash
# Check if index.html exists
kubectl exec -n exercise-2 <pod> -- ls -la /usr/share/nginx/html/

# Verify file contents
kubectl exec -n exercise-2 <pod> -- cat /usr/share/nginx/html/index.html
```

## Cleanup

### Remove all Exercise 2 resources
```bash
./setup.sh clean
```

**This removes:**
- All pods (nfs-server, webapp)
- PVC and PV
- Services
- Namespace

## Learning Points

1. **RWX Access Mode:**
   - Multiple pods on the same node can read and write simultaneously
   - Data is shared across all replicas
   - Changes are immediately visible to all pods

2. **Storage Binding:**
   - PVC binds to matching PV with sufficient capacity
   - Access modes must be compatible
   - Storage capacity must meet PVC requests
   - Manual binding (storageClassName: "") requires exact name match

3. **HostPath Storage:**
   - Direct node filesystem access using `/tmp/shared-data`
   - Good for development/testing
   - Data persists on the node
   - Single-node limitation: pods must run on same node
   - Not recommended for production

4. **Multi-Replica Patterns:**
   - Replicas can share state via shared storage
   - Init containers can populate initial shared data
   - Useful for web servers, shared configuration, logs
   - Requires careful data consistency handling

## References

- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
- [HostPath Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath)
./05-test-script.sh