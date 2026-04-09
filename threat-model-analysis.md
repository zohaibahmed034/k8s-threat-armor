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

