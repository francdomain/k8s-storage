#!/bin/bash

echo "=== Exercise 3: Demonstrating Reclaim Policy Differences ==="
echo ""
echo "This script shows the difference between Retain and Delete reclaim policies"
echo ""

# Get PV names
RETAIN_PV=$(kubectl get pvc retain-policy-pvc -n exercise-3 -o jsonpath='{.spec.volumeName}')
DELETE_PV=$(kubectl get pvc delete-policy-pvc -n exercise-3 -o jsonpath='{.spec.volumeName}')

echo "Current PV and PVC bindings:"
echo "  Retain Policy PV: $RETAIN_PV"
echo "  Delete Policy PV: $DELETE_PV"
echo ""

echo "PV Details BEFORE PVC deletion:"
echo "  Retain PV status:"
kubectl get pv "$RETAIN_PV" -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,RECLAIM:.spec.persistentVolumeReclaimPolicy,STATUS:.status.phase,CLAIM:.spec.claimRef.name
echo ""

echo "  Delete PV status:"
kubectl get pv "$DELETE_PV" -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,RECLAIM:.spec.persistentVolumeReclaimPolicy,STATUS:.status.phase,CLAIM:.spec.claimRef.name
echo ""

echo "=== DELETING PVCs... ==="
kubectl delete pvc retain-policy-pvc delete-policy-pvc -n exercise-3
echo "Waiting for PVC deletion to process..."
sleep 8

echo ""
echo "PV Details AFTER PVC deletion:"
echo ""

echo "Retain PV status:"
kubectl get pv "$RETAIN_PV" -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,RECLAIM:.spec.persistentVolumeReclaimPolicy,STATUS:.status.phase 2>/dev/null || echo "ERROR: Cannot get PV (may have been deleted)"

echo ""
echo "Delete PV status:"
kubectl get pv "$DELETE_PV" -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,RECLAIM:.spec.persistentVolumeReclaimPolicy,STATUS:.status.phase 2>/dev/null || echo "✅ PV WAS DELETED (as expected with Delete policy)"

echo ""
echo "=== KEY OBSERVATIONS ==="
echo ""
echo "Retain Policy ($RETAIN_PV):"
echo "  ✅ PV still exists after PVC deletion"
echo "  ✅ Status changes from 'Bound' to 'Released'"
echo "  ✅ Data is preserved on the node"
echo "  ⚠️  Must be manually cleaned up"
echo ""

echo "Delete Policy ($DELETE_PV):"
echo "  ✅ PV is automatically deleted when PVC is deleted"
echo "  ✅ Data is automatically cleaned up"
echo "  ✅ No manual cleanup needed"
echo ""

echo "=== MANUAL CLEANUP FOR RETAIN POLICY ==="
echo ""
echo "To make the retained PV available for reuse:"
echo ""
echo "1. Check the current PV:"
echo "   kubectl describe pv $RETAIN_PV"
echo ""
echo "2. Remove the claimRef to release it:"
echo "   kubectl patch pv $RETAIN_PV -p '{\"spec\":{\"claimRef\": null}}'"
echo ""
echo "3. The PV will change from 'Released' to 'Available' and can be reused"
echo ""
echo "4. To delete the PV entirely:"
echo "   kubectl delete pv $RETAIN_PV"
echo ""
