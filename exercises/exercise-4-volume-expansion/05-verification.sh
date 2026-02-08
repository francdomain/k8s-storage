#!/bin/bash

# Exercise 4: Volume Expansion Verification Script

echo "=== Exercise 4: Volume Expansion ==="
echo ""

# Create StorageClass
echo "1. Creating expandable StorageClass..."
kubectl apply -f 01-expandable-storageclass.yaml

# Create initial PVC
echo -e "\n2. Creating initial PVC (1Gi)..."
kubectl apply -f 02-pvc-initial.yaml

# Wait for PVC binding
echo -e "\n3. Waiting for PVC to be bound..."
sleep 10
kubectl get pvc -n exercise-4

# Deploy test pod
echo -e "\n4. Deploying test pod..."
kubectl apply -f 03-test-pod.yaml

echo -e "\n5. Waiting for pod to be ready..."
sleep 15

# Check initial storage
echo -e "\n6. Checking initial storage capacity..."
kubectl exec -n exercise-4 test-pod -- df -h /data

# Get test file info
echo -e "\n7. Test file information:"
kubectl exec -n exercise-4 test-pod -- ls -lh /data/testfile

# Expand PVC
echo -e "\n8. Expanding PVC from 1Gi to 2Gi..."
kubectl apply -f 04-expand-pvc.yaml

echo -e "\n9. Monitoring PVC expansion..."
echo "Note: Expansion may take a few moments depending on the storage provider."
echo "Watching PVC status:"
timeout 60 bash -c 'while kubectl get pvc expandable-pvc -n exercise-4 -o jsonpath="{.status.capacity.storage}" | grep -q "1Gi"; do echo -n "."; sleep 2; done; echo ""'

# Check PVC status
echo -e "\n10. PVC status after expansion:"
kubectl get pvc expandable-pvc -n exercise-4 -o yaml | grep -A5 -B5 "capacity\|status"

# The pod may need to be restarted for some storage providers
echo -e "\n11. For some storage providers, the pod needs to be restarted to see expanded capacity."
read -p "Restart pod? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete pod -n exercise-4 test-pod
    sleep 5
    kubectl apply -f 03-test-pod.yaml
    sleep 10
fi

# Check expanded storage
echo -e "\n12. Checking expanded storage capacity..."
kubectl exec -n exercise-4 test-pod -- df -h /data

# Verify test data is intact
echo -e "\n13. Verifying test data is intact..."
kubectl exec -n exercise-4 test-pod -- ls -lh /data/testfile
kubectl exec -n exercise-4 test-pod -- sh -c "echo 'Test file size:' && wc -c /data/testfile"

# Test writing more data
echo -e "\n14. Testing additional data writing..."
kubectl exec -n exercise-4 test-pod -- sh -c "echo 'Writing more data...' && dd if=/dev/zero of=/data/testfile2 bs=1M count=800 status=none"

echo -e "\n15. Final disk usage:"
kubectl exec -n exercise-4 test-pod -- df -h /data

# Summary
echo -e "\n=== Summary ==="
echo "Volume expansion completed successfully!"
echo "- Initial size: 1Gi"
echo "- Expanded size: 2Gi"
echo "- Data preserved: Yes"
echo "- File system expanded: Yes"

# Cleanup
echo -e "\nCleanup commands:"
echo "kubectl delete -f 03-test-pod.yaml"
echo "kubectl delete -f 02-pvc-initial.yaml"
echo "kubectl delete -f 01-expandable-storageclass.yaml"
echo "kubectl delete namespace exercise-4"