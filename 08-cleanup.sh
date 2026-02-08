#!/bin/bash
# Cleanup script for storage labs

set -e

CLUSTER_NAME="storage-lab"

echo "=== Cleaning up Storage Lab Resources ==="

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "Cluster '${CLUSTER_NAME}' does not exist. Nothing to clean up."
    exit 0
fi

# Switch to the right context
kubectl config use-context kind-${CLUSTER_NAME} 2>/dev/null || true

echo "Deleting all lab resources..."

# Delete resources in reverse order of creation
echo "- Deleting pods..."
kubectl delete pods --all --all-namespaces --ignore-not-found 2>/dev/null || true

echo "- Deleting StatefulSets..."
kubectl delete statefulsets --all --ignore-not-found 2>/dev/null || true

echo "- Deleting Deployments..."
kubectl delete deployments --all --ignore-not-found 2>/dev/null || true

echo "- Deleting Services..."
kubectl delete services --all --ignore-not-found 2>/dev/null || true

echo "- Deleting PVCs..."
kubectl delete pvc --all --all-namespaces --ignore-not-found 2>/dev/null || true

echo "- Deleting PVs..."
kubectl delete pv --all --ignore-not-found 2>/dev/null || true

echo "- Deleting custom StorageClasses..."
kubectl delete storageclass --ignore-not-found \
    retain-storage-class \
    delete-storage-class \
    expandable-storage-class \
    2>/dev/null || true

# Clean up Rook-Ceph if installed
if kubectl get namespace rook-ceph &>/dev/null; then
    echo "- Cleaning up Rook-Ceph..."
    kubectl delete -n rook-ceph cephcluster --all --ignore-not-found 2>/dev/null || true
    kubectl delete -n rook-ceph cephblockpool --all --ignore-not-found 2>/dev/null || true
    kubectl delete -n rook-ceph cephfilesystem --all --ignore-not-found 2>/dev/null || true
    kubectl delete -n rook-ceph cephobjectstore --all --ignore-not-found 2>/dev/null || true

    # Wait for cleanup
    sleep 5

    kubectl delete namespace rook-ceph --ignore-not-found 2>/dev/null || true
fi

echo ""
read -p "Delete the KinD cluster '${CLUSTER_NAME}'? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting KinD cluster..."
    kind delete cluster --name ${CLUSTER_NAME}
    echo "Cluster deleted."
else
    echo "Cluster preserved. Resources cleaned up."
fi

echo ""
echo "=== Cleanup Complete ==="
