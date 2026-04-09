#!/bin/bash

echo "=== Kubernetes Security Validation Tests ==="
echo

# Test 1: Pod Security Standards Compliance
echo "1. Testing Pod Security Standards Compliance..."
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.runAsNonRoot}{"\t"}{.spec.containers[*].securityContext.allowPrivilegeEscalation}{"\n"}{end}' | while read pod runAsNonRoot allowPrivEsc; do
    if [[ "$runAsNonRoot" == "true" && "$allowPrivEsc" == "false" ]]; then
        echo "✓ $pod: Compliant with security standards"
    else
        echo "✗ $pod: Non-compliant with security standards"
    fi
done

echo

# Test 2: Network Policy Enforcement
echo "2. Testing Network Policy Enforcement..."

# Get pod names
FRONTEND_POD=$(kubectl get pod -l app=secure-web-frontend -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pod -l app=secure-api-backend -o jsonpath='{.items[0].metadata.name}')

# Test frontend to backend (should work)
if kubectl exec $FRONTEND_POD -- wget -qO- --timeout=5 http://secure-api-service:8080 >/dev/null 2>&1; then
    echo "✓ Frontend → Backend: Allowed (correct)"
else
    echo "✗ Frontend → Backend: Blocked (incorrect)"
fi

# Test frontend to database (should be blocked)
if kubectl exec $FRONTEND_POD -- nc -zv secure-mysql-service 3306 >/dev/null 2>&1; then
    echo "✗ Frontend → Database: Allowed (security risk!)"
else
    echo "✓ Frontend → Database: Blocked (correct)"
fi

# Test backend to database (should work)
if kubectl exec $BACKEND_POD -- nc -zv secure-mysql-service 3306 >/dev/null 2>&1; then
    echo "✓ Backend → Database: Allowed (correct)"
else
    echo "✗ Backend → Database: Blocked (incorrect)"
fi

echo

# Test 3: Resource Limits
echo "3. Testing Resource Limits..."
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources.limits}{"\n"}{end}' | while read pod limits; do
    if [[ "$limits" != "{}" && "$limits" != "" ]]; then
        echo "✓ $pod: Has resource limits defined"
    else
        echo "✗ $pod: Missing resource limits"
    fi
done

echo

# Test 4: Secret Usage
echo "4. Testing Secret Usage..."
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].env[?(@.valueFrom.secretKeyRef)]}{"\n"}{end}' | while read pod secrets; do
    if [[ "$secrets" != "" ]]; then
        echo "✓ $pod: Uses secrets for sensitive data"
    else
        echo "? $pod: May have hardcoded credentials"
    fi
done

echo
echo "=== Security Validation Complete ==="
