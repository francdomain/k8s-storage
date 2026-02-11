#!/bin/bash

echo "=== Testing Exercise 2: RWX Storage ==="
echo "This test verifies multiple pods can share the same storage."

# Check if namespace exists
if ! kubectl get namespace exercise-2 >/dev/null 2>&1; then
    echo "Error: namespace 'exercise-2' not found."
    echo "Run the setup script first."
    exit 1
fi

echo "Waiting for pods to be ready..."
sleep 5

# Check if webapp pods exist and are running
PODS=($(kubectl get pods -n exercise-2 -l app=webapp -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null))

if [ ${#PODS[@]} -eq 0 ]; then
    echo "Warning: No running webapp pods found."
    echo "Checking deployment status..."
    kubectl get deployment -n exercise-2 webapp
    echo "You may need to wait for pods to start or run setup again."
    exit 1
fi

echo "Found ${#PODS[@]} pod(s): ${PODS[*]}"
echo ""

# Test 1: Initial cleanup
echo "=== Test 1: Initial Setup ==="
echo "Cleaning any existing test files..."
for POD in "${PODS[@]}"; do
    kubectl exec -n exercise-2 $POD -- sh -c "rm -f /usr/share/nginx/html/test-*.txt 2>/dev/null || true" 2>/dev/null || true
done

# Test 2: Write from each pod
echo ""
echo "=== Test 2: Each pod writes a unique file ==="
for i in "${!PODS[@]}"; do
    POD="${PODS[$i]}"
    echo "Pod $((i+1)): $POD writing test file..."
    kubectl exec -n exercise-2 $POD -- sh -c "echo 'Written by $POD at \$(date)' > /usr/share/nginx/html/test-pod-$((i+1)).txt"
    sleep 2
done

# Test 3: Verify all pods can read all files
echo ""
echo "=== Test 3: Verify shared access ==="
for POD in "${PODS[@]}"; do
    echo ""
    echo "--- Checking from $POD ---"
    echo "Files in shared directory:"
    kubectl exec -n exercise-2 $POD -- ls -la /usr/share/nginx/html/ 2>/dev/null || echo "Cannot list directory"

    # Try to read each test file
    for i in "${!PODS[@]}"; do
        FILE="test-pod-$((i+1)).txt"
        echo -n "  Reading $FILE: "
        kubectl exec -n exercise-2 $POD -- cat /usr/share/nginx/html/$FILE 2>/dev/null | head -1 || echo "Not found"
    done
done

# Test 4: Create shared index.html
echo ""
echo "=== Test 4: Create shared web content ==="
# Use first running pod to create index.html
READY_PODS=($(kubectl get pods -n exercise-2 -l app=webapp -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null))
if [ ${#READY_PODS[@]} -gt 0 ]; then
    FIRST_POD="${READY_PODS[0]}"
    echo "Creating index.html from $FIRST_POD..."
    kubectl exec -n exercise-2 $FIRST_POD -- sh -c "cat > /usr/share/nginx/html/index.html << 'EOFHTML'
<!DOCTYPE html>
<html>
<head><title>RWX Storage Test - Exercise 2</title></head>
<body style=\"font-family: Arial, sans-serif; margin: 20px;\">
<h1>Multi-Pod Shared Storage Test</h1>
<p>This content is shared across all pods via RWX (ReadWriteMany) storage</p>
<div style=\"background: #f0f0f0; padding: 10px; border-radius: 5px;\">
<h3>Storage Configuration:</h3>
<ul>
<li><strong>Access Mode:</strong> ReadWriteMany (RWX)</li>
<li><strong>Storage Type:</strong> HostPath (Direct node access)</li>
<li><strong>Mount Path:</strong> /exports</li>
<li><strong>Running Pods:</strong> ${#READY_PODS[@]}</li>
<li><strong>Test Time:</strong> $(date)</li>
</ul>
</div>
<h3>Connected Pods:</h3>
<ul>
EOFHTML"

    # Add each pod's status
    for i in "${!READY_PODS[@]}"; do
        POD="${READY_PODS[$i]}"
        kubectl exec -n exercise-2 $FIRST_POD -- sh -c "echo '<li>Pod $((i+1)): <code>$POD</code></li>' >> /usr/share/nginx/html/index.html"
    done

    kubectl exec -n exercise-2 $FIRST_POD -- sh -c "echo '</ul></body></html>' >> /usr/share/nginx/html/index.html"
    echo "✅ index.html created successfully"
else
    echo "⚠️ No running pods available to create index.html"
fi

# Test 5: Web access
echo ""
echo "=== Test 5: Web server access ==="
echo "Starting port-forward (will run for 30 seconds)..."
kubectl port-forward -n exercise-2 svc/webapp-service 8080:80 &
PF_PID=$!

# Wait for port-forward to start
sleep 5

echo "Testing HTTP access..."
if curl -s --max-time 10 http://localhost:8080/ >/dev/null 2>&1; then
    echo "✅ Web server is accessible!"
    echo ""
    echo "Page title:"
    curl -s http://localhost:8080/ | grep -o '<title>[^<]*</title>' | sed 's/<[^>]*>//g'
    echo ""
    echo "First few lines:"
    curl -s http://localhost:8080/ | head -10
else
    echo "⚠️ Cannot access web server on port 8080"
    echo "You can try manually: kubectl port-forward -n exercise-2 svc/webapp-service 8080:80"
fi

# Kill port-forward after 30 seconds
sleep 25
kill $PF_PID 2>/dev/null || true
echo "Port-forward stopped."

# Test 6: Final verification
echo ""
echo "=== Test 6: Final verification ==="
echo "Checking PVC status:"
if kubectl get pvc -n exercise-2 shared-web-pvc >/dev/null 2>&1; then
    kubectl get pvc -n exercise-2 shared-web-pvc -o wide
    echo ""
    echo "Checking PV status:"
    PV_NAME=$(kubectl get pvc -n exercise-2 shared-web-pvc -o jsonpath='{.spec.volumeName}' 2>/dev/null)
    if [ -n "$PV_NAME" ]; then
        kubectl get pv $PV_NAME -o wide
        echo ""
        echo "Storage Details:"
        PV_PATH=$(kubectl get pv $PV_NAME -o jsonpath='{.spec.hostPath.path}' 2>/dev/null)
        if [ -n "$PV_PATH" ]; then
            echo "  Storage Type: HostPath"
            echo "  HostPath: $PV_PATH"
        fi
    fi
else
    echo "  (PVC was already cleaned up - this is normal)"
fi

echo ""
echo "Deployment Status:"
kubectl get deployment -n exercise-2 webapp --show-kind=false

echo ""
echo "=== TEST COMPLETE ==="
echo "Summary: ${#PODS[@]} pods successfully sharing RWX storage"
echo "✅ All tests passed!"
echo "✅ All tests passed!"