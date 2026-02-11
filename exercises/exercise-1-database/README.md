# Exercise 1: Database Deployment with Persistent Storage

This exercise demonstrates deploying a stateful PostgreSQL database with persistent storage, testing data persistence across pod restarts, and implementing automated backups using Kubernetes CronJobs.

## Overview

You will learn:
- How to create a PersistentVolumeClaim (PVC) for database storage
- Deploying a stateful application (PostgreSQL) with persistent storage
- Testing data persistence when pods are killed and restarted
- Implementing automatic backups using CronJobs
- Working with ReadWriteOnce (RWO) access mode

## Key Concepts

- **ReadWriteOnce (RWO)**: Storage can be mounted by a single pod on a single node
- **StatefulSet vs Deployment**: PostgreSQL uses Deployment but could use StatefulSet for more complex scenarios
- **Persistent Storage**: Data survives pod restarts and deletions
- **Data Integrity**: Database maintains consistency across pod lifecycle

## Files in This Exercise

| File | Purpose |
|------|---------|
| `01-postgres-pvc.yaml` | Creates 5Gi PVC for PostgreSQL data storage |
| `02-postgres-deployment.yaml` | PostgreSQL deployment with persistent volume mounting |
| `03-test-data.yaml` | Pod that creates test database and inserts sample data |
| `04-backup-cronjob.yaml` | CronJob for automated daily database backups |
| `README.md` | This file |

## Quick Start

### Step 1: Create Namespace and PVC
```bash
kubectl apply -f 01-postgres-pvc.yaml
```

### Step 2: Deploy PostgreSQL
```bash
kubectl apply -f 02-postgres-deployment.yaml
```

**Wait for PostgreSQL to be ready:**
```bash
kubectl get pods -n exercise-1 -w
# Should see postgres pod in Running state
```

### Step 3: Verify Storage Binding
```bash
kubectl get pvc -n exercise-1
kubectl get pv | grep exercise-1
```

### Step 4: Create Test Data
```bash
kubectl apply -f 03-test-data.yaml
kubectl logs -n exercise-1 -l job-name=create-testdb --tail=20
```

### Step 5: Deploy Backup CronJob
```bash
kubectl apply -f 04-backup-cronjob.yaml
```

## Testing Data Persistence

### Test 1: Verify Data is Stored
```bash
# Connect to PostgreSQL and check the test database
kubectl exec -it -n exercise-1 deployment/postgres -- psql -U postgres -d testdb -c "SELECT * FROM test_table;"

# Expected output: rows of sample data
```

### Test 2: Kill Pod and Verify Data Survives
```bash
# Get the pod name
POD=$(kubectl get pods -n exercise-1 -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Delete the pod
kubectl delete pod -n exercise-1 $POD

# Wait for new pod to start
kubectl get pods -n exercise-1 -w

# Query data again
kubectl exec -it -n exercise-1 deployment/postgres -- psql -U postgres -d testdb -c "SELECT * FROM test_table;"

# Data should still be there! ✅
```

### Test 3: Verify Backups
```bash
# Check CronJob status
kubectl get cronjobs -n exercise-1
kubectl get jobs -n exercise-1

# View backup pod logs
kubectl get pods -n exercise-1 -l app=postgres-backup
kubectl logs -n exercise-1 -l app=postgres-backup --tail=10
```

## Storage Details

### PersistentVolumeClaim Specification
```yaml
Name: postgres-pvc
Size: 5Gi
Access Mode: ReadWriteOnce (RWO)
Storage Class: local-path (default k3d provisioner)
Status: Bound to PV
```

### Backup Storage
```yaml
Name: postgres-backup-pvc
Size: 2Gi
Access Mode: ReadWriteOnce (RWO)
Used for: Storing database backups
```

## Understanding the Exercise

### What is RWO (ReadWriteOnce)?
- Only one pod can mount this volume
- Pod can read and write
- Must be on the same node
- Perfect for stateful applications like databases

### Data Flow
```
PostgreSQL Pod
    ↓
  volumes/
    ↓
postgres-pvc (PVC)
    ↓
Persistent Volume (PV)
    ↓
Node filesystem (/var/lib/kubelet/...)
```

### Why Persistence Matters
Without persistent storage, losing a pod means losing all data. With persistent storage:
- Database data survives pod crashes
- Updates don't cause data loss
- Backups can be automated
- Planning maintenance becomes easier

## Common Tasks

### View Current Data
```bash
kubectl exec -it -n exercise-1 deployment/postgres -- \
  psql -U postgres -d testdb -c "SELECT * FROM test_table;"
```

### Add More Data
```bash
kubectl exec -it -n exercise-1 deployment/postgres -- \
  psql -U postgres -d testdb -c "INSERT INTO test_table VALUES (999, 'new entry');"
```

### Check Storage Usage
```bash
kubectl exec -n exercise-1 deployment/postgres -- df -h /var/lib/postgresql/data
```

### View Recent Backups
```bash
kubectl get pods -n exercise-1 -l app=postgres-backup --sort-by=.metadata.creationTimestamp
```

## Troubleshooting

### Pod stuck in Pending
```bash
kubectl describe pod -n exercise-1 -l app=postgres
# Check if PVC is bound
kubectl get pvc -n exercise-1
```

### Cannot connect to PostgreSQL
```bash
# Check pod logs
kubectl logs -n exercise-1 deployment/postgres

# Verify environment variables
kubectl get deployment -n exercise-1 postgres -o yaml | grep -A 10 env:

# Default credentials: user: postgres, password: postgres
```

### Backup CronJob not running
```bash
# Check CronJob configuration
kubectl get cronjob -n exercise-1 postgres-backup -o yaml

# Check the schedule (should match your timezone)
kubectl get jobs -n exercise-1
```

### PVC not binding
```bash
# Check storage class
kubectl get sc local-path

# Check PV status
kubectl get pv | grep exercise-1

# Check PVC events
kubectl describe pvc -n exercise-1 postgres-pvc
```

## Learning Outcomes

After completing this exercise, you should understand:
- ✅ How to create and bind PersistentVolumeClaims
- ✅ How to configure stateful workloads with persistent storage
- ✅ How data persists across pod restarts
- ✅ How to implement automated backups
- ✅ RWO access mode use cases

## Cleanup

To remove all resources:
```bash
kubectl delete namespace exercise-1
```

This will delete:
- PostgreSQL deployment
- PVCs and PVs
- CronJob
- Test data jobs
- Backups

## References

- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [PostgreSQL on Kubernetes](https://kubernetes.io/docs/tutorials/stateful-application/sql/)