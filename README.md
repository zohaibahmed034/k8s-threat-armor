# E-commerce Application Threat Model

## System Architecture Overview

### Components:
1. **Web Frontend (web-frontend)**
   - Technology: Nginx
   - Replicas: 3
   - Exposure: LoadBalancer service
   - Trust Level: Public-facing (Untrusted)

2. **API Backend (api-backend)**
   - Technology: Nginx (simulating API server)
   - Replicas: 2
   - Exposure: ClusterIP service
   - Trust Level: Internal (Semi-trusted)

3. **Database (mysql-db)**
   - Technology: MySQL 8.0
   - Replicas: 1
   - Exposure: ClusterIP service
   - Trust Level: Internal (Trusted)

### Trust Boundaries Identified:
1. **Internet → Frontend**: External users to web application
2. **Frontend → Backend**: Web tier to application tier
3. **Backend → Database**: Application tier to data tier
4. **Pod → Node**: Container to host system
5. **Namespace → Cluster**: Application boundary within cluster


## Data Flow Analysis

### Primary Data Flows:
1. **User Request Flow**:
   Internet → LoadBalancer → web-frontend → api-service → api-backend → mysql-service → mysql-db

2. **Response Flow**:
   mysql-db → mysql-service → api-backend → api-service → web-frontend → LoadBalancer → Internet

3. **Internal Communication**:
   - Frontend pods communicate with API service (HTTP/8080)
   - Backend pods communicate with MySQL service (TCP/3306)
   - All communication within cluster network

### Data Types:
- User credentials and session data
- Product catalog information
- Order and payment data
- Application logs and metrics


## Attack Vector Analysis

### 1. Privilege Escalation Risks

#### Current Security Posture:
- **No security contexts defined**: Containers run with default privileges
- **Root access**: Containers may run as root user
- **Privileged capabilities**: Default capabilities may be excessive
- **Host access**: No restrictions on host filesystem access

#### Potential Attack Vectors:
1. **Container Breakout**: Attacker gains access to host system
2. **Privilege Escalation**: Escalate from container user to root
3. **Capability Abuse**: Misuse of Linux capabilities
4. **Host Path Mounting**: Access to sensitive host directories


### 2. Lateral Movement Risks

#### Network Segmentation Analysis:
- **No network policies**: All pods can communicate with all services
- **Flat network**: No micro-segmentation between tiers
- **Service discovery**: All services discoverable via DNS
- **Port accessibility**: All service ports accessible cluster-wide

#### Potential Attack Vectors:
1. **Cross-tier access**: Frontend can directly access database
2. **Service enumeration**: Attackers can discover all services
3. **Protocol abuse**: Unrestricted protocol usage
4. **Data exfiltration**: Direct database access from compromised frontend


### 3. Container Security Risks

#### Image Security Issues:
- **Base image vulnerabilities**: Using standard images without security scanning
- **Outdated packages**: Potential unpatched vulnerabilities
- **Unnecessary packages**: Increased attack surface

#### Configuration Issues:
- **Hardcoded credentials**: Database passwords in environment variables
- **No resource limits**: Potential for resource exhaustion attacks
- **Default configurations**: Using default settings without hardening

#### Runtime Security Issues:
- **No admission controls**: No validation of pod security standards
- **Unrestricted capabilities**: Containers have default Linux capabilities
- **No AppArmor/SELinux**: Missing mandatory access controls

# Kubernetes Security Assessment Report

## Executive Summary
This report documents the security assessment and hardening of the e-commerce application deployed on Kubernetes.

## Security Improvements Implemented

### 1. Pod Security Standards
- **Implemented**: Restricted Pod Security Standards
- **Controls**: 
  - runAsNonRoot: true
  - allowPrivilegeEscalation: false
  - readOnlyRootFilesystem: true (where possible)
  - Dropped all capabilities, added only necessary ones
  - Seccomp profile: RuntimeDefault

### 2. Network Segmentation
- **Implemented**: Network policies for micro-segmentation
- **Controls**:
  - Default deny all ingress traffic
  - Allow frontend → backend communication (port 8080)
  - Allow backend → database communication (port 3306)
  - Block direct frontend → database communication

### 3. Secret Management
- **Implemented**: Kubernetes secrets for sensitive data
- **Controls**:
  - Database credentials stored in secrets
  - Environment variables reference secrets
  - No hardcoded passwords in deployments

### 4. Resource Management
- **Implemented**: Resource quotas and limits
- **Controls**:
  - CPU and memory limits per container
  - Namespace-level resource quotas
  - Prevention of resource exhaustion attacks

## Risk Mitigation Summary

| Risk Category | Before | After | Mitigation |
|---------------|--------|-------|------------|
| Privilege Escalation | High | Low | Pod Security Standards |
| Lateral Movement | High | Low | Network Policies |
| Resource Exhaustion | Medium | Low | Resource Limits |
| Credential Exposure | High | Low | Secret Management |
| Container Breakout | High | Medium | Security Contexts |

## Recommendations for Further Improvement

1. **Image Security**:
   - Implement image vulnerability scanning
   - Use minimal base images (distroless)
   - Sign and verify container images

2. **Runtime Security**:
   - Deploy runtime security monitoring (Falco)
   - Implement admission controllers (OPA Gatekeeper)
   - Enable audit logging

3. **Access Control**:
   - Implement RBAC with least privilege
   - Use service accounts with minimal permissions
   - Enable Pod Security Admission
