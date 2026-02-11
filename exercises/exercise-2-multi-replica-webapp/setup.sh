#!/bin/bash

echo "=== Exercise 2: RWX Storage Setup ==="

# Parse arguments
if [ "$1" == "clean" ]; then
    echo "Cleaning up Exercise 2 resources..."
    kubectl delete -f 02-webapp-deployment.yaml --ignore-not-found 2>/dev/null
    kubectl delete -f 01-shared-storage.yaml --ignore-not-found 2>/dev/null
    echo "✅ Cleanup complete"
    exit 0
fi

if [ "$1" == "help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no args)  - Deploy Exercise 2 resources"
    echo "  clean      - Remove all Exercise 2 resources"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0           # Deploy resources"
    echo "  $0 clean     # Clean up resources"
    exit 0
fi

# Validate required files exist
echo "Checking required files..."
required_files=("01-shared-storage.yaml" "02-webapp-deployment.yaml")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Error: Missing required file: $file"
        exit 1
    fi
done
echo "✅ All required files found"

# Apply manifests in order
echo ""
echo "Applying resources..."
kubectl apply -f 01-shared-storage.yaml
kubectl apply -f 02-webapp-deployment.yaml

echo ""
echo "=== SETUP COMPLETE ==="
echo ""
echo "Deployed resources:"
kubectl get all -n exercise-2
echo ""
echo "Storage resources:"
kubectl get pv,pvc -n exercise-2
echo ""
echo "Next steps:"
echo "  1. Check pod status:  kubectl get pods -n exercise-2"
echo "  2. Run tests:         ./05-test-script.sh"
echo "  3. Port-forward:      kubectl port-forward -n exercise-2 svc/webapp-service 8080:80"
echo "  4. Clean up:          ./setup.sh clean"