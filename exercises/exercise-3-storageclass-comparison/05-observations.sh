#!/bin/bash

# Exercise 3: StorageClass Comparison Script

echo "=== Exercise 3: StorageClass Comparison ==="
echo ""

# Create StorageClasses
echo "1. Creating StorageClasses..."
kubectl apply -f 01-retain-storageclass.yaml
kubectl apply -f 02-delete-storageclass.yaml

echo -e "\nStorageClasses created:"
kubectl get storageclass -n exercise-3

# Create PVCs
echo -e "\n2. Creating PVCs..."
kubectl apply -f 03-pvc-retain.yaml
kubectl apply -f 04-pvc-delete.yaml

echo -e "\nWaiting for PVC binding..."
sleep 10

echo -e "\nCurrent PV and PVC status:"
kubectl get pv,pvc -n exercise-3

# Get PV names
RETAIN_PV=$(kubectl get pvc retain-policy-pvc -n exercise-3 -o jsonpath='{.spec.volumeName}')
DELETE_PV=$(kubectl get pvc delete-policy-pvc -n exercise-3 -o jsonpath='{.spec.volumeName}')

echo -e "\nRetain policy PV: $RETAIN_PV"
echo "Delete policy PV: $DELETE_PV"

# Delete PVCs
echo -e "\n3. Deleting PVCs..."
kubectl delete pvc retain-policy-pvc -n exercise-3
kubectl delete pvc delete-policy-pvc -n exercise-3

echo -e "\nWaiting for PVC deletion..."
sleep 10

# Observe PV status
echo -e "\n4. Observing PV status after PVC deletion:"
kubectl get pv

echo -e "\nRetain policy PV ($RETAIN_PV) status:"
kubectl get pv "$RETAIN_PV" -o wide

echo -e "\nDelete policy PV ($DELETE_PV) status:"
kubectl get pv "$DELETE_PV" -o wide 2>/dev/null || echo "PV $DELETE_PV not found (was deleted)"

# Manual cleanup for retained PV
echo -e "\n5. Manual cleanup of retained PV:"
echo "To release the retained PV for reuse, you need to:"
echo "1. Remove the claimRef from the PV:"
echo "   kubectl patch pv $RETAIN_PV -p '{\"spec\":{\"claimRef\": null}}'"
echo "2. Change the status from Released to Available:"
echo "   kubectl patch pv $RETAIN_PV -p '{\"spec\":{\"persistentVolumeReclaimPolicy\": \"Retain\"}}'"

# Cleanup
echo -e "\n6. Cleanup:"
read -p "Do you want to delete the StorageClasses? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete storageclass retain-policy-sc delete-policy-sc -n exercise-3
    kubectl delete namespace exercise-3
    echo "Cleanup completed."
fi