# Exercise 3: StorageClass Reclaim Policy Comparison

This exercise demonstrates the critical difference between `Retain` and `Delete` reclaim policies when PersistentVolumeClaims (PVCs) are deleted. Understanding these policies is essential for production storage management.

## Overview

You will learn:
- What reclaim policies are and why they matter
- Difference between Retain and Delete policies
- Behavior of PVs when PVCs are deleted under each policy
- Manual cleanup of retained PVs
- Impact on data and billing in production environments

## Key Concepts

### Reclaim Policy
Determines what happens to a PersistentVolume when its PersistentVolumeClaim is deleted:

- **Delete**: The PV is automatically deleted (default for dynamic provisioning)
- **Retain**: The PV and data are kept; must be manually cleaned up
- **Recycle**: (Deprecated) The PV is scrubbed and made available for new claims

### Use Cases
- **Delete**: Development, testing, temporary workloads (data cleanup automatic)
- **Retain**: Production data, compliance requirements, archival (prevents accidental loss)

## Files in This Exercise

| File | Purpose |
|------|---------|
| `01-retain-storageclass.yaml` | StorageClass with Retain reclaim policy |
| `02-delete-storageclass.yaml` | StorageClass with Delete reclaim policy |
| `03-pvc-retain.yaml` | PVC using Retain policy (1Gi) |
| `04-pvc-delete.yaml` | PVC using Delete policy (1Gi) |
| `setup-exercise-3.yaml` | All-in-one deployment with test pods |
| `demonstrate-reclaim.sh` | Script showing reclaim policy differences |
| `06-test-pods.yaml` | Test pods for writing data |
| `README.md` | This file |

## Quick Start

### Option 1: Deploy Everything at Once
```bash
cd exercises/exercise-3-storageclass-comparison
kubectl apply -f setup-exercise-3.yaml
sleep 20

# Verify resources
kubectl get sc | grep -E "retain|delete"
kubectl get pvc -n exercise-3
kubectl get pods -n exercise-3
```

### Option 2: Deploy Step by Step
```bash
# 1. Create StorageClasses
kubectl apply -f 01-retain-storageclass.yaml
kubectl apply -f 02-delete-storageclass.yaml

# 2. Create PVCs
kubectl apply -f 03-pvc-retain.yaml
kubectl apply -f 04-pvc-delete.yaml

# 3. Deploy test pods to trigger PV creation
kubectl apply -f 06-test-pods.yaml

# Wait for pods to be running
kubectl get pods -n exercise-3 -w
```

## Understanding the Policies

### Before PVC Deletion

Both PVCs are bound to dynamically created PVs:

```bash
kubectl get pvc -n exercise-3
kubectl get pv | grep exercise-3
```

**Output should show:**
```
NAME                  STATUS   VOLUME                                   CLAIM
delete-policy-pvc     Bound    pvc-6c894a61-f773-46dc-b8cd-...        exercise-3/delete-policy-pvc
retain-policy-pvc     Bound    pvc-ec655096-1111-414e-a32b-...        exercise-3/retain-policy-pvc
```

### Deleting PVCs - The Key Experiment

```bash
# Delete both PVCs
kubectl delete pvc delete-policy-pvc retain-policy-pvc -n exercise-3

# Wait for deletion to process
sleep 10

# Check PV status
kubectl get pv
```

### After PVC Deletion - The Difference!

#### Delete Policy (PVC deleted)
✅ **PV is AUTOMATICALLY DELETED**
- PV no longer appears in `kubectl get pv`
- Data is cleaned up from the node
- Storage space is freed
- No manual intervention required

#### Retain Policy (PVC deleted)
✅ **PV REMAINS with status "Released"**
- PV still appears in `kubectl get pv`
- Status changes from "Bound" to "Released"
- Data is preserved on the node
- claimRef still points to the deleted PVC
- **Must be manually cleaned up or reclaimed**

## Demonstrating the Difference

### Run the Automated Demo
```bash
chmod +x demonstrate-reclaim.sh
./demonstrate-reclaim.sh
```

This script:
1. Shows PV/PVC status BEFORE deletion
2. Deletes both PVCs
3. Shows PV/PVC status AFTER deletion
4. Highlights the difference between policies

### Manual Verification
```bash
# Get the PV names before deletion
RETAIN_PV=$(kubectl get pvc retain-policy-pvc -n exercise-3 -o jsonpath='{.spec.volumeName}')
DELETE_PV=$(kubectl get pvc delete-policy-pvc -n exercise-3 -o jsonpath='{.spec.volumeName}')

echo "Retain PV: $RETAIN_PV"
echo "Delete PV: $DELETE_PV"

# Delete PVCs
kubectl delete pvc -n exercise-3 --all

# Check what happened
echo "After deletion:"
kubectl get pv $RETAIN_PV  # Should still exist
kubectl get pv $DELETE_PV  # Should be gone
```

## Deep Dive: What Each Policy Does

### Delete Policy Flow
```
PVC deleted
    ↓
PV status → "Released"
    ↓
Deletion controller detects "Delete" policy
    ↓
PV automatically deleted
    ↓
Data cleaned from node
    ↓
Storage completely removed
```

### Retain Policy Flow
```
PVC deleted
    ↓
PV status → "Released"
    ↓
claimRef remains pointing to deleted PVC
    ↓
PV stays in cluster indefinitely
    ↓
Data remains on node
    ↓
Manual intervention required to clean up
```

## Reclaiming a Retained PV

If you need to reuse a retained PV:

### Option 1: Delete the PV
```bash
# Data is lost!
kubectl delete pv $RETAIN_PV
```

### Option 2: Remove claimRef (Make it reusable)
```bash
# Remove the reference to the deleted PVC
kubectl patch pv $RETAIN_PV -p '{"spec":{"claimRef": null}}'

# PV status changes from "Released" to "Available"
kubectl get pv $RETAIN_PV

# Now it can be bound to a new PVC
```

### Option 3: Archive the Data
```bash
# Before deleting, copy data somewhere
kubectl get pv $RETAIN_PV -o yaml > backup-pv.yaml

# Keep the YAML as documentation
# Then delete the PV
kubectl delete pv $RETAIN_PV
```

## Real-World Scenarios

### Development/Testing
```yaml
storageClass: "delete-policy"
reclaim-policy: Delete
# Auto-cleanup saves space and costs
```

### Production Database
```yaml
storageClass: "retain-policy"
reclaim-policy: Retain
# Prevents accidental data loss
```

### Compliance Requirements
```yaml
storageClass: "retain-policy-archival"
reclaim-policy: Retain
# Keep data for audit trails, legal holds
```

## Important Notes

⚠️ **Delete Policy is Dangerous**
- Deleting a PVC immediately removes the data
- No backup or recovery possible
- Be careful in production!

⚠️ **Retain Policy Creates Orphaned Resources**
- PVs accumulate over time
- Nodes may run out of storage
- Requires manual cleanup process
- Costs may accumulate (in cloud environments)

✅ **Best Practice**
- Use Retain for important/production data
- Use Delete for temporary/test data
- Monitor and clean up orphaned PVs regularly
- Document your reclaim policy strategy

## Storage Class Details

### Retain Policy StorageClass
```yaml
reclaimPolicy: Retain          # Data kept after PVC deletion
allowVolumeExpansion: true     # Can be expanded
volumeBindingMode: WaitForFirstConsumer  # Binds when pod needs it
```

### Delete Policy StorageClass
```yaml
reclaimPolicy: Delete          # Data deleted with PVC
allowVolumeExpansion: true     # Can be expanded
volumeBindingMode: WaitForFirstConsumer  # Binds when pod needs it
```

## Testing the Behavior

### Write Test Data
```bash
# Connect to test-retain-pod and write a file
kubectl exec -n exercise-3 test-retain-pod -- sh -c \
  "echo 'Retain me!' > /data/important.txt"

# Connect to test-delete-pod and write a file
kubectl exec -n exercise-3 test-delete-pod -- sh -c \
  "echo 'Delete me!' > /data/temporary.txt"

# Verify data exists
kubectl exec -n exercise-3 test-retain-pod -- ls -la /data/
kubectl exec -n exercise-3 test-delete-pod -- ls -la /data/
```

### Check PV Details
```bash
# Before deletion
kubectl get pv | grep exercise-3
kubectl describe pv $RETAIN_PV
kubectl describe pv $DELETE_PV

# Note the claimRef sections
```

### After Deletion
```bash
# Retain PV still exists with data
kubectl get pv $RETAIN_PV
# Status: Released
# claimRef: still present (but PVC is deleted)

# Delete PV is gone
kubectl get pv $DELETE_PV
# Error: not found
```

## Troubleshooting

### PVCs stuck in Terminating
```bash
# Check what's blocking deletion
kubectl describe pvc -n exercise-3 retain-policy-pvc

# Force delete if necessary
kubectl delete pvc -n exercise-3 --all --grace-period=0 --force
```

### Cannot see the difference
```bash
# Make sure to delete PVCs first
kubectl delete pvc -n exercise-3 --all

# Then check PVs
kubectl get pv
# Retain PV should still be there
```

### PVs taking up disk space
```bash
# Check which PVs are orphaned
kubectl get pv -o json | jq '.items[] | select(.status.phase=="Released")'

# Delete if not needed
kubectl delete pv pvc-xxxxxxxx
```

## Learning Outcomes

After completing this exercise, you should understand:
- ✅ What reclaim policies are and why they exist
- ✅ Difference between Retain and Delete policies
- ✅ How PVs behave when PVCs are deleted
- ✅ When to use each policy
- ✅ How to clean up retained PVs
- ✅ Implications for data safety and cost

## Cleanup

### Remove Everything
```bash
# If PVCs still exist
kubectl delete pvc -n exercise-3 --all

# Delete StorageClasses
kubectl delete sc retain-policy-sc delete-policy-sc

# Delete namespace
kubectl delete namespace exercise-3
```

### If PVs are Orphaned
```bash
# List orphaned PVs
kubectl get pv | grep Released

# If safe to delete
kubectl delete pv pvc-xxxxxxxx pvc-yyyyyyyy
```

## References

- [Kubernetes Reclaim Policies](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaim-policy)
- [PersistentVolume Lifecycle](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#lifecycle)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)