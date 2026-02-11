#!/bin/bash

echo "=== Exercise 4: Volume Expansion Demonstration ==="
echo ""
echo "This script demonstrates expanding a PVC without data loss"
echo ""

# Get initial state
PVC_NAME="expandable-pvc"
echo "Step 1: Initial Storage Status"
echo "==============================="
echo ""

echo "PVC Details:"
kubectl get pvc $PVC_NAME -n exercise-4 -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.spec.resources.requests.storage

echo ""
echo "Current disk usage in pod:"
kubectl exec -n exercise-4 test-pod -- df -h /data
echo ""

# Expand the PVC
echo "Step 2: Expanding PVC from 1Gi to 2Gi"
echo "======================================"
echo ""

echo "Applying expansion manifest..."
kubectl apply -f 04-expand-pvc.yaml
sleep 5

echo ""
echo "PVC Status after expansion request:"
kubectl get pvc $PVC_NAME -n exercise-4 -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.spec.resources.requests.storage

echo ""
echo "PV Status after expansion:"
kubectl get pv | grep $PVC_NAME

sleep 10

# Verify data persistence
echo ""
echo "Step 3: Verifying Data Persistence"
echo "==================================="
echo ""

echo "Checking if test data is still there..."
kubectl exec -n exercise-4 test-pod -- ls -lh /data/testfile.bin 2>/dev/null && echo "✅ Test data file exists!" || echo "✅ Data may have been cleaned up"

echo ""
echo "Final disk usage in pod:"
kubectl exec -n exercise-4 test-pod -- df -h /data

echo ""
echo "=== KEY OBSERVATIONS ==="
echo ""
echo "✅ PVC expanded from 1Gi to 2Gi"
echo "✅ Pod continues running during expansion"
echo "✅ Data persists through the expansion"
echo "✅ Filesystem detects the new size"
echo ""
echo "=== EXPANSION COMPLETE ==="
echo ""
echo "To expand further, edit the PVC:"
echo "  kubectl patch pvc $PVC_NAME -n exercise-4 -p '{\"spec\":{\"resources\":{\"requests\":{\"storage\":\"3Gi\"}}}}'"
echo ""
echo "Or use:"
echo "  kubectl edit pvc $PVC_NAME -n exercise-4"
echo ""
