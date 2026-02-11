# Exercise 2: Multi-Replica Web App with RWX Storage

This exercise demonstrates **ReadWriteMany (RWX) access mode** with multiple pod replicas sharing the same persistent storage in Kubernetes.

## Overview

This exercise shows how multiple replicas of a web application can:
- Share the same storage volume
- Read and write files simultaneously
- Access the same data across pods

**Key Concepts:**
- **ReadWriteMany (RWX):** Multiple pods on different nodes can read and write to the same volume
- **HostPath Storage:** Direct node-level storage access for shared data
- **Persistent Volumes (PV):** Cluster-level storage resource
- **Persistent Volume Claims (PVC):** Pod-level storage request
- **Multi-Replica Deployments:** Running multiple identical pods

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Exercise 2 Architecture                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Node: k3d-storage-lab-server-0                        │
│  ┌───────────────────────────────────────┐             │
│  │ HostPath: /exports                    │             │
│  │ (Shared storage on node)              │             │
│  └──────────┬──────────────────────────┬─┘             │
│             │                          │                │
│  ┌──────────▼────────┐    ┌────────────▼────────┐      │
│  │   NFS Server Pod  │    │  WebApp Pod 1       │      │
│  │  (Exports /exports)    │ (nginx:alpine)      │      │
│  └───────────────────┘    └─────────────────────┘      │
│                                                         │
│                           ┌──────────────────────────┐  │
│                           │  WebApp Pod 2            │  │
│                           │ (nginx:alpine)           │  │
│                           └──────────────────────────┘  │
│                                                         │
│                           ┌──────────────────────────┐  │
│                           │  WebApp Pod 3            │  │
│                           │ (nginx:alpine)           │  │
│                           └──────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
       ↓ (All pods mount shared storage via PVC)
   ┌─────────────────┐
   │   shared-web    │
   │     -pvc (2Gi)  │ ← RWX Access Mode
   └────────┬────────┘
            │
   ┌────────▼────────┐
   │    nfs-pv       │
   │  (HostPath)     │
   └─────────────────┘
```

## Files and Configuration

| File | Purpose |
|------|---------|
| `01-nfs-server.yaml` | NFS server deployment that exports `/exports` directory |
| `02-nfs-pv.yaml` | PersistentVolume using HostPath `/exports` with RWX access |
| `03-rwx-pvc.yaml` | PersistentVolumeClaim requesting 2Gi RWX storage |
| `04-webapp-deployment.yaml` | nginx deployment with 3 replicas, all mounting shared storage |
| `05-test-script.sh` | Test script to verify RWX functionality |
| `setup.sh` | Deployment script that applies all manifests |

## Quick Start

### 1. Deploy Resources
```bash
# Make scripts executable
chmod +x setup.sh 05-test-script.sh

# Deploy NFS server, storage, and web app
./setup.sh
```

**What this does:**
- Creates `exercise-2` namespace
- Deploys NFS server pod
- Creates PersistentVolume (HostPath backed)
- Creates PersistentVolumeClaim
- Deploys 3 nginx web app replicas

### 2. Wait for Ready Pods
```bash
# Check pod status
kubectl get pods -n exercise-2

# Expected output (all should show 1/1 Running):
NAME                              READY   STATUS
nfs-server-7c8b5bf5bb-98557       1/1     Running
webapp-5965946479-srxk4           1/1     Running
webapp-7787f8c6d-spxlq            1/1     Running
webapp-7d886fd749-xm4w7           1/1     Running
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

### PersistentVolume (nfs-pv)
```yaml
Capacity: 2Gi
Access Modes: ReadWriteMany (RWX)
Reclaim Policy: Retain
Storage Type: HostPath (/exports)
```

### PersistentVolumeClaim (shared-web-pvc)
```yaml
Capacity: 2Gi
Access Modes: ReadWriteMany (RWX)
Bound Volume: nfs-pv
Status: Bound
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

# Common issue: Node affinity
# All pods are pinned to k3d-storage-lab-server-0
kubectl get node k3d-storage-lab-server-0
```

### PVC not binding
```bash
# Check PV status
kubectl get pv nfs-pv -o yaml

# Check PVC status
kubectl get pvc shared-web-pvc -n exercise-2 -o yaml

# Ensured PV and PVC access modes match (both RWX)
```

### NFS server not ready
```bash
# Check NFS pod logs
kubectl logs -n exercise-2 -l app=nfs-server

# Verify exports
kubectl exec -n exercise-2 <nfs-pod> -- exportfs -v
```

### Web app returns 403 Forbidden
```bash
# Check if index.html exists
kubectl exec -n exercise-2 <pod> -- ls -la /usr/share/nginx/html/

# Create index.html manually
kubectl exec -n exercise-2 <pod> -- sh -c "echo '<h1>Test</h1>' > /usr/share/nginx/html/index.html"
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
   - Multiple pods can read and write simultaneously
   - Data is shared across all replicas
   - Changes are immediately visible to all pods

2. **Storage Binding:**
   - PVC binds to first matching PV
   - Access modes must be compatible
   - Storage capacity must meet PVC requests

3. **HostPath Storage:**
   - Direct node filesystem access
   - Good for development/testing
   - Not recommended for production
   - Data persists on the node

4. **Multi-Replica Patterns:**
   - Replicas can share state via shared storage
   - Useful for web servers, databases, caches
   - Requires careful data consistency handling

## References

- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
- [HostPath Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath)
./05-test-script.sh