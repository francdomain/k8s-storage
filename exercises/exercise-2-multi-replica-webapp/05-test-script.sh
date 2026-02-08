#!/bin/bash

# Test script for Exercise 2: Multi-Replica Web App
echo "Testing shared storage across multiple pods..."

# Create index.html on pod-0
echo "Creating index.html from webapp-0..."
kubectl exec -n exercise-2 deploy/webapp -c webapp -- sh -c "echo 'Shared Web App - Pod 0' > /usr/share/nginx/html/index.html"

# Write unique file from each pod
for i in 0 1 2; do
  echo "Writing from webapp pod $i..."
  kubectl exec -n exercise-2 "deploy/webapp" -c webapp -- sh -c "echo 'Hello from Pod $i - $(date)' > /data/pod-$i.txt"
done

# Verify all files are visible from each pod
echo -e "\nVerifying shared access from each pod:"
for i in 0 1 2; do
  echo -e "\n=== From Pod $i ==="
  kubectl exec -n exercise-2 "deploy/webapp" -c webapp -- sh -c "echo 'Index.html content:'; cat /usr/share/nginx/html/index.html"
  echo "Files in /data:"
  kubectl exec -n exercise-2 "deploy/webapp" -c webapp -- sh -c "ls -la /data/"
done

# Test web server access
echo -e "\nTesting web server access:"
kubectl port-forward -n exercise-2 deploy/webapp 8080:80 &
sleep 2
curl -s http://localhost:8080/
pkill -f "kubectl port-forward"