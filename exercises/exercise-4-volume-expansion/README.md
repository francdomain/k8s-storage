# Exercise 4: Volume Expansion Without Data Loss

This exercise demonstrates how to expand a PersistentVolumeClaim (PVC) to provide more storage to running applications without losing data or causing downtime. This is a critical feature for production systems where storage needs grow over time.

## Overview

You will learn:
- How to enable volume expansion in StorageClasses
- How to expand a PVC while the pod is running
- How to verify expanded storage is available to the application
- Data and application continuity during expansion
- Limitations and considerations for volume expansion

## Key Concepts

### Volume Expansion
- **Dynamic**: Some storage backends support online expansion (while pod is running)
- **No Downtime**: Pod continues running during expansion
- **No Data Loss**: All data is preserved
- **Immediate Effect**: Applications see expanded storage right away

### Prerequisites
- StorageClass must have `allowVolumeExpansion: true`
- Underlying storage backend must support expansion
- PVC size can only increase, never decrease

## Files in This Exercise

| File | Purpose |
|------|---------|
| `01-expandable-storageclass.yaml` | StorageClass with allowVolumeExpansion enabled |
| `02-pvc-initial.yaml` | Initial 1Gi PVC |
| `03-test-pod.yaml` | Pod that writes data and monitors storage |
| `04-expand-pvc.yaml` | Expanded PVC configuration (2Gi) |
| `05-verification.sh` | Script to verify expansion |
| `demonstrate-expansion.sh` | Demo script showing expansion in action |
| `README.md` | This file |

## Quick Start

### Step 1: Deploy the Expandable StorageClass
```bash
cd exercises/exercise-4-volume-expansion
kubectl apply -f 01-expandable-storageclass.yaml
```

### Step 2: Create Initial 1Gi PVC
```bash
kubectl apply -f 02-pvc-initial.yaml

# Wait for binding (may be pending until pod claims it)
kubectl get pvc -n exercise-4
```

### Step 3: Deploy Pod with Test Data
```bash
kubectl apply -f 03-test-pod.yaml

# Wait for pod to be ready
kubectl get pods -n exercise-4 -w
# Should see: test-pod 1/1 Running
```

### Step 4: Verify Initial Storage
```bash
# Check initial storage from the test pod
kubectl exec -n exercise-4 test-pod -- df -h /data

# Should show 1Gi available
```

### Step 5: Expand the PVC
```bash
# Apply the expanded configuration (1Gi → 2Gi)
kubectl apply -f 04-expand-pvc.yaml
```

### Step 6: Verify Expansion
```bash
# Expansion happens in real-time
kubectl exec -n exercise-4 test-pod -- df -h /data

# Should now show 2Gi available
```

### Step 7: Run the Demonstration Script
```bash
chmod +x demonstrate-expansion.sh
./demonstrate-expansion.sh
```

## Detailed Explanation: What Happened

### Before Expansion
```
Pod: test-pod
PVC: expandable-pvc (1Gi)
PV: pvc-xxxxx (1Gi)
Filesystem: Mounted at /data with 1Gi capacity
Data: Test file written (500MB)
Available: ~500MB
```

### Expansion Command
```bash
kubectl apply -f 04-expand-pvc.yaml
# Or manually:
# kubectl patch pvc expandable-pvc -n exercise-4 \
#   -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'
```

### After Expansion
```
Pod: test-pod (CONTINUES RUNNING ✓)
PVC: expandable-pvc (2Gi) ✓
PV: pvc-xxxxx (2Gi) ✓
Filesystem: /data detects new size
Available: ~1500MB (doubled!)
Data: All 500MB of test data INTACT ✓
```

## Understanding Volume Expansion

### Storage Expansion Flow
```
User applies expanded PVC config
    ↓
Kubernetes validates expansion request
    ↓
Storage provisioner (local-path) receives expansion request
    ↓
Underlying storage is expanded
    ↓
PVC status shows new size
    ↓
Filesystem detects new capacity
    ↓
Application can use new space immediately
```

### What Makes This Safe
- Original data is preserved during expansion
- Pod continues running without interruption
- Filesystem handles size increase transparently
- No downtime required
- No data loss or corruption

## Verifying the Expansion

### Method 1: Check PVC Size
```bash
kubectl get pvc expandable-pvc -n exercise-4
# CAPACITY column should show 2Gi

kubectl get pvc expandable-pvc -n exercise-4 -o jsonpath='{.spec.resources.requests.storage}'
# Output: 2Gi
```

### Method 2: Check from Inside Pod
```bash
# Disk usage from container's perspective
kubectl exec -n exercise-4 test-pod -- df -h /data
# Should show Filesystem Size ~2Gi

kubectl exec -n exercise-4 test-pod -- du -sh /data/*
# Shows used space (test data should be there)
```

### Method 3: Check PV
```bash
PV=$(kubectl get pvc expandable-pvc -n exercise-4 -o jsonpath='{.spec.volumeName}')
kubectl get pv $PV
# CAPACITY column should show 2Gi
```

### Method 4: Verify Data Integrity
```bash
# Check the test file still exists
kubectl exec -n exercise-4 test-pod -- ls -lh /data/testfile.bin
# Should show the 500MB file we created earlier

# Verify file size hasn't changed
kubectl exec -n exercise-4 test-pod -- stat /data/testfile.bin
# Size should be exactly 500MB
```

## Multiple Expansion Example

You can expand the volume multiple times:

### Expand to 3Gi
```bash
kubectl patch pvc expandable-pvc -n exercise-4 \
  -p '{"spec":{"resources":{"requests":{"storage":"3Gi"}}}}'

sleep 5
kubectl exec -n exercise-4 test-pod -- df -h /data
# Should show 3Gi
```

### Expand to 5Gi
```bash
kubectl patch pvc expandable-pvc -n exercise-4 \
  -p '{"spec":{"resources":{"requests":{"storage":"5Gi"}}}}'

sleep 5
kubectl exec -n exercise-4 test-pod -- df -h /data
# Should show 5Gi
```

**Key Point**: You can expand multiple times, but **cannot shrink**

## Real-World Considerations

### When to Expand
- Database growing beyond initial allocation
- Log files accumulating over time
- User data storage increasing
- Predictive scaling based on trends

### How to Monitor
```bash
# Watch storage usage
watch -n 5 'kubectl exec -n exercise-4 test-pod -- df /data'

# Set alerts for approaching capacity
# (e.g., > 80% of PVC size used)
```

### Expansion Policies
```yaml
# Development: Manual expansion as needed
# Staging: Automated expansion when 80% full
# Production: Pre-expansion with capacity planning
```

## Troubleshooting

### Expansion Not Working

#### Check if StorageClass allows expansion
```bash
kubectl get sc expandable-sc -o yaml | grep allowVolumeExpansion
# Should show: allowVolumeExpansion: true
```

#### Check PVC is bound
```bash
kubectl get pvc -n exercise-4 expandable-pvc
# Status should be "Bound" (not "Pending")
```

#### Check for errors in PVC
```bash
kubectl describe pvc -n exercise-4 expandable-pvc
# Look for error messages or warnings
```

#### Check PV is correctly sized
```bash
kubectl get pv
# CAPACITY should match new size
```

### Pod Not Seeing New Storage

```bash
# Sometimes filesystem needs time to detect the change
# Wait 10-30 seconds and retry:
sleep 30
kubectl exec -n exercise-4 test-pod -- df -h /data

# If still not showing, check if pod needs restart
# (usually not required)
```

### Expansion Stuck in Progress
```bash
# Check provisioner logs
kubectl logs -n kube-system -l app.kubernetes.io/name=local-path-provisioner

# Check PVC events
kubectl describe pvc -n exercise-4 expandable-pvc | tail -20
```

## Advanced: Manual Expansion Method

Instead of applying the YAML file, you can expand with kubectl patch:

```bash
# Expand from 2Gi to 3Gi
kubectl patch pvc expandable-pvc -n exercise-4 \
  -p '{"spec":{"resources":{"requests":{"storage":"3Gi"}}}}'

# Expand from 3Gi to 4Gi
kubectl patch pvc expandable-pvc -n exercise-4 \
  -p '{"spec":{"resources":{"requests":{"storage":"4Gi"}}}}'

# View the new size
kubectl get pvc expandable-pvc -n exercise-4 -o jsonpath='{.spec.resources.requests.storage}' && echo
```

## Integration with Automation

### Monitor and Auto-Expand Script Example
```bash
# Check current usage
USAGE=$(kubectl exec -n exercise-4 test-pod -- df /data | tail -1 | awk '{print $5}' | sed 's/%//')

# If usage > 80%, expand by 50%
if [ "$USAGE" -gt 80 ]; then
  echo "Usage at $USAGE%, expanding PVC..."
  kubectl patch pvc expandable-pvc -n exercise-4 \
    -p '{"spec":{"resources":{"requests":{"storage":"3Gi"}}}}'
fi
```

## Key Differences from Other Storage Features

### Expansion vs. Replication
- **Expansion**: Grows a single volume
- **Replication**: Creates copies across nodes

### Expansion vs. Snapshots
- **Expansion**: Increases capacity
- **Snapshots**: Creates point-in-time copy

### Expansion vs. Dynamic Provisioning
- **Dynamic Provisioning**: PV created on demand
- **Expansion**: Existing PV grows

## Important Limitations

⚠️ **Cannot Shrink**
- PVC size can only increase
- Once expanded, cannot reduce size
- Plan storage carefully

⚠️ **Backend Dependent**
- Not all storage backends support expansion
- local-path provisioner supports expansion
- Some cloud providers may have restrictions

⚠️ **Application Aware**
- Some applications cache filesystem size
- May need pod restart to see new capacity
- Usually automatic with Linux ext4/xfs

## Production Best Practices

### Monitoring
```bash
# Create alerts for these conditions:
# 1. PVC usage > 80%
# 2. PVC approaching StorageClass limits
# 3. Expansion failures
```

### Planning
```yaml
# Initial size: Peak expected + 20% buffer
# Expansion trigger: 80% capacity
# Expansion amount: 50-100% increase
```

### Documentation
```bash
# Track expansion history
kubectl get events -n exercise-4 --field-selector involvedObject.kind=PersistentVolumeClaim
```

## Learning Outcomes

After completing this exercise, you should understand:
- ✅ How to enable volume expansion in StorageClasses
- ✅ How to expand a PVC with running pods
- ✅ How data integrity is maintained during expansion
- ✅ Monitoring expanded storage
- ✅ Limitations of volume expansion
- ✅ Production considerations for scaling storage

## Cleanup

### Remove All Resources
```bash
kubectl delete namespace exercise-4
```

This will delete:
- StorageClass
- PVC and expanded PV
- Test pod
- All data written to the volume

### Or Delete Individual Resources
```bash
# Delete pod first
kubectl delete pod -n exercise-4 test-pod

# Then PVC
kubectl delete pvc -n exercise-4 expandable-pvc

# Then StorageClass
kubectl delete sc expandable-sc

# Then namespace
kubectl delete namespace exercise-4
```

## References

- [Kubernetes Volume Expansion](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims)
- [StorageClass Expansion Parameters](https://kubernetes.io/docs/concepts/storage/storage-classes/#allow-volume-expansion)
- [Local Path Provisioner](https://github.com/rancher/local-path-provisioner)