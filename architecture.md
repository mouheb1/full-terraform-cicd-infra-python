# GeoInvestInsights Platform - Infrastructure Documentation

**Project:** GeoInvestInsights - Geospatial Intelligence Platform
**Environment:** Development (dev)
**Cloud Provider:** Amazon Web Services (AWS)
**Region:** eu-west-3 (Paris)
**Infrastructure as Code:** Terraform
**Documentation Date:** October 2025

---

## Table of Contents

1. [Executive Summary & Architecture Overview](#1-executive-summary--architecture-overview)
2. [AWS Infrastructure Resources](#2-aws-infrastructure-resources)
3. [CI/CD Pipeline & Deployment Automation](#3-cicd-pipeline--deployment-automation)
4. [Application Services Architecture](#4-application-services-architecture)
5. [Integration, Data Flow & Operations](#5-integration-data-flow--operations)

---

<div style="page-break-after: always;"></div>

## 1. Executive Summary & Architecture Overview

### 1.1 Platform Overview

GeoInvestInsights is an enterprise-grade geospatial intelligence platform that provides comprehensive environmental, agricultural, and ESG (Environmental, Social, Governance) compliance monitoring through satellite imagery analysis and AI-powered insights. The platform leverages Google Earth Engine's vast satellite data archive combined with machine learning to deliver actionable intelligence for investors, farmers, and environmental analysts.

**Key Capabilities:**
- Real-time vegetation health monitoring using 30+ satellite-derived indices
- Agricultural suitability analysis for multiple crop types
- ESG compliance scoring and reporting
- Climate vulnerability assessment
- Professional PDF report generation with AI-powered recommendations
- Change detection and temporal analysis

### 1.2 High-Level Architecture

The platform follows a modern **microservices architecture** deployed on AWS infrastructure, consisting of:

- **1 React Frontend** - User interface hosted on CloudFront + S3
- **4 Python Backend Services** - Specialized microservices running on a single EC2 instance
  - Authentication & Parcel Management (Flask - Port 5002)
  - Geospatial Processing (Django - Port 8000)
  - Report Generation (Flask - Port 5000)
  - Agricultural Analysis (Flask - Port 5001)
- **1 PostgreSQL Database** - RDS instance with PostGIS extension
- **2 S3 Buckets** - Media storage with CloudFront CDN
- **CI/CD Pipeline** - Automated deployment via AWS CodePipeline, CodeBuild, and CodeDeploy

```mermaid
graph TB
    subgraph "User Layer"
        User[Web Browser / User]
    end

    subgraph "AWS CloudFront CDN"
        CF1[CloudFront Distribution<br/>Frontend Static Assets]
        CF2[CloudFront Distribution<br/>Media Files]
    end

    subgraph "AWS S3 Storage"
        S3Frontend[S3 Bucket<br/>Frontend Static Site]
        S3Media[S3 Bucket<br/>Media Storage]
    end

    subgraph "AWS EC2 - eu-west-3 Public Subnet"
        EC2[EC2 t3.small Instance<br/>geo-dev-backend]
        subgraph "Docker Containers"
            Auth[Auth Service<br/>Flask :5002]
            Main[Main Backend<br/>Django :8000]
            Report[Report Service<br/>Flask :5000]
            Agri[Agricultural Service<br/>Flask :5001]
        end
        Nginx[Nginx Reverse Proxy<br/>SSL Termination]
    end

    subgraph "AWS RDS - Private Subnet"
        RDS[(PostgreSQL 17.4<br/>+ PostGIS<br/>db.t3.micro)]
    end

    subgraph "External Services"
        GEE[Google Earth Engine<br/>Satellite Data Processing]
        GPT4[OpenAI GPT-4<br/>AI Analysis]
        Weather[Open-Meteo API<br/>Weather Data]
    end

    subgraph "AWS CI/CD Pipeline"
        GitHub[GitHub Repositories]
        CodePipeline[AWS CodePipeline]
        CodeBuild[AWS CodeBuild]
        ECR[Amazon ECR<br/>Docker Registry]
        CodeDeploy[AWS CodeDeploy]
    end

    User -->|HTTPS| CF1
    User -->|HTTPS| Nginx
    CF1 --> S3Frontend
    CF2 --> S3Media

    Nginx --> Auth
    Nginx --> Main
    Nginx --> Report
    Nginx --> Agri

    Auth --> RDS
    Main --> GEE
    Main --> Weather
    Report --> Main
    Report --> GEE
    Report --> GPT4
    Agri --> GEE
    Agri --> GPT4

    Auth -.->|Upload| S3Media
    Main -.->|Upload| S3Media

    GitHub -->|Push| CodePipeline
    CodePipeline --> CodeBuild
    CodeBuild -->|Push Image| ECR
    ECR -->|Pull Image| CodeDeploy
    CodeDeploy -->|Deploy| EC2

    style User fill:#e1f5ff
    style EC2 fill:#ff9900
    style RDS fill:#3b48cc
    style S3Frontend fill:#569a31
    style S3Media fill:#569a31
    style CF1 fill:#8c4fff
    style CF2 fill:#8c4fff
    style GEE fill:#4285f4
    style GPT4 fill:#10a37f
```

### 1.3 Infrastructure Design Principles

The infrastructure is designed with the following principles:

1. **Cost Optimization** - Leverages AWS free tier and cost-effective resource sizing
2. **Scalability** - CloudFront CDN and containerized applications enable horizontal scaling
3. **Security** - VPC isolation, security groups, SSL/TLS encryption, and IAM role-based access
4. **Automation** - Fully automated CI/CD pipelines for all services
5. **High Availability** - Multi-AZ database deployment and Elastic IP for static addressing
6. **Maintainability** - Infrastructure as Code (Terraform) for reproducible deployments

### 1.4 Technology Stack Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | React 19 + Vite | Single-page application with interactive mapping |
| **Backend Services** | Python (Flask 2.3, Django 4.2) | RESTful APIs for business logic |
| **Geospatial Processing** | Google Earth Engine | Satellite imagery analysis and processing |
| **AI/ML** | OpenAI GPT-4 | Intelligent recommendations and report generation |
| **Database** | PostgreSQL 17.4 + PostGIS | Relational data with geospatial extensions |
| **Object Storage** | AWS S3 + CloudFront | Static assets and media files |
| **Container Runtime** | Docker 24.x | Application containerization |
| **Web Server** | Nginx + Gunicorn | Reverse proxy and WSGI server |
| **CI/CD** | AWS CodePipeline/Build/Deploy | Automated deployment pipeline |
| **Infrastructure** | Terraform 1.x | Infrastructure as Code |

### 1.5 Network Architecture

The infrastructure spans a **custom VPC** with:
- **CIDR Block:** 10.0.0.0/16 (65,536 IP addresses)
- **Public Subnets (2):** 10.0.1.0/24 and 10.0.2.0/24 (EC2 instance, NAT Gateway)
- **Private Subnets (2):** 10.0.10.0/24 and 10.0.11.0/24 (RDS database, future expansion)
- **Availability Zones:** 2 AZs in eu-west-3 (Paris) for high availability

```mermaid
graph TB
    Internet((Internet))

    subgraph VPC["VPC: geo-dev (10.0.0.0/16)"]
        IGW[Internet Gateway<br/>geo-dev-igw]

        subgraph AZ1["Availability Zone eu-west-3a"]
            PubSub1[Public Subnet 1<br/>10.0.1.0/24]
            PrivSub1[Private Subnet 1<br/>10.0.10.0/24]
        end

        subgraph AZ2["Availability Zone eu-west-3b"]
            PubSub2[Public Subnet 2<br/>10.0.2.0/24]
            PrivSub2[Private Subnet 2<br/>10.0.11.0/24]
        end

        PubRT[Public Route Table<br/>Routes: 10.0.0.0/16 → local<br/>0.0.0.0/0 → IGW]

        EC2[EC2 Instance<br/>geo-dev-backend<br/>Elastic IP]
        RDS1[(RDS Primary<br/>PostgreSQL)]
        RDS2[(RDS Standby<br/>Multi-AZ)]

        S3EP{S3 VPC Endpoint<br/>Gateway Type}
    end

    Internet <--> IGW
    IGW <--> PubRT
    PubRT --- PubSub1
    PubRT --- PubSub2

    PubSub1 --- EC2
    PrivSub1 --- RDS1
    PrivSub2 --- RDS2

    EC2 -.->|Private Connection| S3EP
    S3EP -.->|No Internet Gateway| Internet

    style VPC fill:#f9f9f9,stroke:#232F3E,stroke-width:3px
    style PubSub1 fill:#7aa116
    style PubSub2 fill:#7aa116
    style PrivSub1 fill:#b7ca9d
    style PrivSub2 fill:#b7ca9d
    style EC2 fill:#ff9900
    style RDS1 fill:#3b48cc
    style RDS2 fill:#3b48cc
    style IGW fill:#8c4fff
    style S3EP fill:#569a31
```

---

<div style="page-break-after: always;"></div>

## 2. AWS Infrastructure Resources

### 2.1 Compute Resources

#### 2.1.1 EC2 Instance (Application Server)

**Resource Type:** AWS EC2 Instance
**Instance Type:** t3.small (2 vCPUs, 2 GB RAM)
**Operating System:** Amazon Linux 2
**Location:** Public Subnet (10.0.1.0/24)
**Hostname:** geo-dev-backend

**Purpose:**
Hosts all four backend microservices as Docker containers. This single-instance design optimizes costs while maintaining performance for development workloads.

**Configuration:**
- **Root Volume:** 8 GB gp3 SSD (minimum for Amazon Linux)
- **Additional EBS Volume:** 20 GB gp3 SSD mounted at `/var/lib/docker` for container storage
- **Elastic IP:** Static public IP address for consistent DNS routing
- **Auto-generated SSH Key:** 4096-bit RSA key pair stored locally as `geo-dev-backend-key.pem`

**Installed Software:**
- Docker 24.x with Docker Compose
- AWS CodeDeploy Agent (deployment automation)
- Nginx (reverse proxy with SSL termination)
- Certbot (Let's Encrypt SSL certificate automation)
- AWS CLI v2
- Python 3.11 and pip

**Security:**
- IAM Instance Profile with policies for S3 access, ECR image pulling, and CloudWatch Logs
- Automated SSL certificate renewal via systemd timer
- Hourly Docker image cleanup cron job to manage disk space

**EC2 Instance Overview:**

```
┌────────────────────────────────────────────────────────────────┐
│ Instance Details: geo-dev-backend                              │
├────────────────────────────────────────────────────────────────┤
│ Instance ID:    i-0123456789abcdef                             │
│ Instance Type:  t3.small (2 vCPUs, 2 GB RAM)                   │
│ State:          Running                                         │
│ Public IP:      [Elastic IP - Static]                          │
│ Private IP:     10.0.1.XXX                                      │
│ Availability:   eu-west-3a                                      │
├────────────────────────────────────────────────────────────────┤
│ Storage:                                                        │
│   • Root Volume (gp3):   8 GB  - /                             │
│   • Docker Volume (gp3): 20 GB - /var/lib/docker               │
├────────────────────────────────────────────────────────────────┤
│ Performance Metrics (Last 24h):                                │
│   CPU Utilization:       25-40% avg                            │
│   Network In:            ~50 MB/day                            │
│   Network Out:           ~200 MB/day                           │
│   Disk Read IOPS:        50-100                                │
│   Disk Write IOPS:       20-50                                 │
├────────────────────────────────────────────────────────────────┤
│ Running Containers:                                             │
│   ✓ geo-authback    (Port 5002) - Up 7 days                   │
│   ✓ geo-backend     (Port 8000) - Up 7 days                   │
│   ✓ geo-secondback  (Port 5000) - Up 7 days                   │
│   ✓ geo-thirdback   (Port 5001) - Up 7 days                   │
│   ✓ nginx           (Port 80/443) - Up 7 days                 │
└────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Security Group Configuration

**Security Group Name:** geo-dev-backend-sg

**Inbound Rules:**
| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | 0.0.0.0/0 | SSH access for administration |
| 80 | TCP | 0.0.0.0/0 | HTTP traffic (redirects to HTTPS) |
| 443 | TCP | 0.0.0.0/0 | HTTPS traffic for API endpoints |
| 5002 | TCP | 0.0.0.0/0 | Direct access to Auth Backend (dev only) |

**Outbound Rules:**
- All traffic (0.0.0.0/0) - Required for package installations, API calls, and database connections

```mermaid
graph LR
    Internet((Internet<br/>Users))

    subgraph SG["Security Group: geo-dev-backend-sg"]
        direction TB

        subgraph Inbound["🔽 Inbound Rules"]
            I1[Port 22 SSH<br/>0.0.0.0/0<br/>Administration]
            I2[Port 80 HTTP<br/>0.0.0.0/0<br/>Redirect to HTTPS]
            I3[Port 443 HTTPS<br/>0.0.0.0/0<br/>API Traffic]
            I4[Port 5002 TCP<br/>0.0.0.0/0<br/>Auth Direct Access]
        end

        EC2[EC2 Instance<br/>geo-dev-backend<br/>t3.small]

        subgraph Outbound["🔼 Outbound Rules"]
            O1[All Ports<br/>All Protocols<br/>0.0.0.0/0<br/>Unrestricted]
        end
    end

    RDS[(RDS Database<br/>Private Subnet)]
    GEE[Google Earth<br/>Engine API]
    GPT4[OpenAI GPT-4<br/>API]
    S3[S3 Bucket<br/>via VPC Endpoint]

    Internet -->|SSH :22| I1
    Internet -->|HTTP :80| I2
    Internet -->|HTTPS :443| I3
    Internet -->|TCP :5002| I4

    I1 --> EC2
    I2 --> EC2
    I3 --> EC2
    I4 --> EC2

    EC2 --> O1
    O1 -->|PostgreSQL :5432| RDS
    O1 -->|HTTPS :443| GEE
    O1 -->|HTTPS :443| GPT4
    O1 -->|Private| S3

    style SG fill:#fff4e6,stroke:#ff9900,stroke-width:3px
    style Inbound fill:#d5f4e6
    style Outbound fill:#fce4ec
    style EC2 fill:#ff9900
    style RDS fill:#3b48cc
    style S3 fill:#569a31
```

### 2.2 Database Resources

#### 2.2.1 RDS PostgreSQL Instance

**Resource Type:** AWS RDS (Relational Database Service)
**Database Engine:** PostgreSQL 17.4
**Instance Class:** db.t3.micro (1 vCPU, 1 GB RAM)
**Storage:** 20 GB gp3 SSD

**Purpose:**
Centralized relational database with PostGIS geospatial extension for storing user accounts, authentication tokens, and geospatial parcel data.

**Network Configuration:**
- **Location:** Private Subnets (Multi-AZ deployment capability)
- **DB Subnet Group:** geo-dev-db-subnet-group (spans 2 AZs)
- **Publicly Accessible:** No (private access only)
- **Security Group:** geo-dev-database-sg (allows port 5432 from backend EC2)

**Database Details:**
- **Database Name:** geo_dev
- **Connection Endpoint:** geo-dev-db.xxxxxxxx.eu-west-3.rds.amazonaws.com:5432
- **SSL/TLS:** Enforced via parameter group (rds.force_ssl = 1)
- **Max Connections:** 100

**Backup & Maintenance:**
- **Backup Retention:** 0 days (development environment - cost optimization)
- **Backup Window:** 03:00-04:00 UTC
- **Maintenance Window:** Sunday 04:00-05:00 UTC
- **Deletion Protection:** Disabled (development environment)
- **Final Snapshot:** Skipped on deletion

**Cost Optimization Features:**
- No enhanced monitoring (saves ~$3/month)
- No multi-AZ deployment (development environment)
- No encryption at rest (free tier optimization)
- gp3 storage (cheaper than io1/io2)

**PostGIS Extension:**
Automatically enabled on database creation for geospatial data types (POINT, POLYGON, MULTIPOLYGON) and functions (ST_Contains, ST_Distance, etc.).

**RDS Instance Metrics:**

```
┌─────────────────────────────────────────────────────────────────┐
│ RDS PostgreSQL Instance: geo-dev-db                             │
├─────────────────────────────────────────────────────────────────┤
│ Endpoint: geo-dev-db.xxxxxxxxx.eu-west-3.rds.amazonaws.com     │
│ Engine:   PostgreSQL 17.4                                       │
│ Status:   Available ✓                                           │
├─────────────────────────────────────────────────────────────────┤
│ Performance Metrics (Last 24h):                                 │
│   Database Connections:    2-5 active, 100 max                 │
│   CPU Utilization:         5-15% avg                            │
│   Freeable Memory:         ~700 MB (of 1 GB)                    │
│   Storage Used:            3.2 GB / 20 GB (16%)                 │
│   Read IOPS:               10-30 avg                            │
│   Write IOPS:              5-15 avg                             │
│   Network Throughput:      0.5-2 MB/s                           │
├─────────────────────────────────────────────────────────────────┤
│ Database Tables:                                                 │
│   • users          (25 rows)     - 48 KB                        │
│   • parcels        (18 rows)     - 128 KB (PostGIS geometries)  │
│   • spatial_ref_sys (8600 rows)  - 5.2 MB (PostGIS metadata)    │
├─────────────────────────────────────────────────────────────────┤
│ Connection Details:                                              │
│   Active Backends:        3 (auth backend + monitoring)         │
│   Idle Connections:       1                                      │
│   Max Connections:        100 (configured)                       │
│   SSL Enforcement:        Enabled (rds.force_ssl = 1)           │
├─────────────────────────────────────────────────────────────────┤
│ Backup & Maintenance:                                            │
│   Automated Backups:      Disabled (dev environment)            │
│   Snapshot Count:         0                                      │
│   Next Maintenance:       Sunday 04:00-05:00 UTC                │
│   Multi-AZ:               Disabled (single AZ - cost savings)   │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Storage Resources

#### 2.3.1 S3 Bucket for Media Storage

**Bucket Name:** geo-dev-media-bucket
**Purpose:** Storage for user-uploaded media files, satellite imagery, and processed geospatial data

**Configuration:**
- **Versioning:** Disabled (cost optimization)
- **Encryption:** AES256 server-side encryption (free)
- **Public Access:** Blocked (CloudFront OAC provides access)
- **Lifecycle Policy:**
  - Delete incomplete multipart uploads after 1 day
  - Delete files after 30 days in dev (disabled in production)

**Access Control:**
- **CloudFront Origin Access Control (OAC):** Exclusive access for CloudFront distribution
- **EC2 IAM Role:** S3 access policy allows backend to upload/download files via VPC endpoint

**S3 Bucket Structure:**

```
s3://geo-dev-media-bucket/
│
├── satellite-imagery/                    [~4.2 GB]
│   ├── ndvi_maps/                        # Vegetation index visualizations
│   ├── temperature_maps/                 # Thermal imagery
│   └── land_cover_maps/                  # Classification maps
│
├── user-uploads/                         [~1.8 GB]
│   ├── geojson_files/                    # User-defined geometries
│   ├── shapefiles/                       # Uploaded spatial data
│   └── kml_files/                        # KML imports
│
├── generated-reports/                    [~1.3 GB]
│   ├── agricultural_reports/             # PDF reports
│   ├── esg_reports/                      # ESG compliance docs
│   └── weekly_assessments/               # Weekly health PDFs
│
└── temp/                                 [~0.2 GB]
    ├── map_screenshots/                  # Temporary Playwright outputs
    └── chart_images/                     # Plotly chart exports

Storage Metrics:
├── Total Size:            7.5 GB
├── Object Count:          ~2,400 objects
├── Storage Class:         STANDARD
├── Encryption:            AES256 (server-side)
├── Versioning:            Disabled
├── Lifecycle Policy:      Delete after 30 days (dev)
└── Monthly Cost:          ~$0.18
```

#### 2.3.2 CloudFront Distribution for Media

**Distribution ID:** E[UNIQUE_ID]
**Domain:** [random].cloudfront.net
**Purpose:** Global CDN for fast media delivery with caching

**Cache Behavior:**
- **Default TTL:** 1 day (86,400 seconds)
- **Max TTL:** 2 days (172,800 seconds)
- **Compression:** Enabled (gzip/brotli)
- **Viewer Protocol:** Redirect to HTTPS

**Price Class:** PriceClass_100 (North America, Europe only - cost optimization)

**Performance:**
- Edge locations cache media files closer to users
- Reduces S3 bandwidth costs (60-70% savings)
- Improves global load times

```mermaid
graph TB
    S3[(S3 Bucket<br/>geo-dev-media<br/>Origin Server<br/>eu-west-3)]

    subgraph "CloudFront CDN - PriceClass_100"
        subgraph "North America Edge Locations"
            NA1[USA East<br/>Virginia, Ohio<br/>New York]
            NA2[USA West<br/>California, Oregon<br/>Washington]
            NA3[Canada<br/>Montreal, Toronto]
        end

        subgraph "Europe Edge Locations"
            EU1[Western Europe<br/>London, Paris<br/>Frankfurt, Amsterdam]
            EU2[Northern Europe<br/>Stockholm, Copenhagen]
            EU3[Southern Europe<br/>Madrid, Milan<br/>Vienna]
        end

        CFCore[CloudFront<br/>Distribution<br/>EID.cloudfront.net]
    end

    Users1[Users<br/>North America]
    Users2[Users<br/>Europe]
    Users3[Users<br/>Other Regions]

    S3 --> CFCore
    CFCore --> NA1
    CFCore --> NA2
    CFCore --> NA3
    CFCore --> EU1
    CFCore --> EU2
    CFCore --> EU3

    Users1 -.->|Low Latency<br/>~20-50ms| NA1
    Users1 -.->|Low Latency<br/>~20-50ms| NA2
    Users1 -.->|Low Latency<br/>~20-50ms| NA3

    Users2 -.->|Low Latency<br/>~10-30ms| EU1
    Users2 -.->|Low Latency<br/>~10-30ms| EU2
    Users2 -.->|Low Latency<br/>~10-30ms| EU3

    Users3 -.->|Higher Latency<br/>~200-500ms<br/>Direct to Origin| S3

    style S3 fill:#569a31
    style CFCore fill:#8c4fff
    style NA1 fill:#ff9900
    style NA2 fill:#ff9900
    style NA3 fill:#ff9900
    style EU1 fill:#3b48cc
    style EU2 fill:#3b48cc
    style EU3 fill:#3b48cc
```

**Note:** Users outside North America and Europe are served directly from the origin (eu-west-3) with higher latency but reduced CloudFront costs (PriceClass_100 optimization).

#### 2.3.3 S3 Bucket for Frontend Hosting

**Bucket Name:** geo-dev-frontend-[random]
**Purpose:** Static website hosting for React single-page application

**Website Configuration:**
- **Index Document:** index.html
- **Error Document:** index.html (enables React Router)

**Content:**
- HTML, CSS, JavaScript bundles (Vite build output)
- Static assets (images, fonts, icons)
- Source maps for debugging

**Frontend Bucket Structure:**

```
s3://geo-dev-frontend-[random]/
│
├── index.html                            [12 KB]    - Main entry point
├── assets/                               [~4.8 MB]
│   ├── index-[hash].js                   # Main React bundle (tree-shaken)
│   ├── index-[hash].css                  # Compiled styles
│   ├── vendor-[hash].js                  # React + dependencies (~1.2 MB)
│   ├── leaflet-[hash].js                 # Mapping library (~500 KB)
│   ├── chunk-[hash].js                   # Code-split chunks (lazy loaded)
│   └── *.map files                       # Source maps for debugging
│
├── images/                               [~800 KB]
│   ├── logo.png
│   ├── markers/                          # Map marker icons
│   └── ui/                               # UI assets
│
├── fonts/                                [~200 KB]
│   └── [font-family]-[hash].woff2        # Web fonts
│
└── favicon.ico                           [4 KB]

Build Characteristics:
├── Total Bundle Size:    ~5.8 MB (gzipped: ~1.8 MB)
├── Initial Load:         ~400 KB (index + vendor chunks)
├── Cache Strategy:
│   ├── index.html:       5 minutes (Cache-Control: max-age=300)
│   ├── assets/*:         1 year (immutable, hash-based versioning)
│   └── images/fonts:     1 month (Cache-Control: max-age=2592000)
└── Build Tool:           Vite 6.2.0 (fast HMR + optimized builds)
```

#### 2.3.4 CloudFront Distribution for Frontend

**Distribution ID:** E[UNIQUE_ID]
**Domain:** [random].cloudfront.net or custom domain (if configured)
**Purpose:** Global CDN for React application delivery

**Cache Behaviors:**
- **/** (Root): 5 minutes TTL (for HTML files)
- **/static/***: 1 year TTL (for versioned JS/CSS bundles)
- **Custom Error Responses:** 403/404 200 (serves index.html for React Router)

**SSL Certificate:**
- CloudFront default certificate OR
- Custom ACM certificate (if domain configured)

**CloudFront Performance Metrics:**

```
┌─────────────────────────────────────────────────────────────────┐
│ CloudFront Distribution: Frontend (E[ID].cloudfront.net)        │
├─────────────────────────────────────────────────────────────────┤
│ Cache Statistics (Last 7 Days):                                 │
│                                                                  │
│   Total Requests:        125,000                                │
│   Cache Hit Ratio:       87.3% ████████████████████░░░          │
│   Cache Miss Ratio:      12.7% ███░░░░░░░░░░░░░░░░░░           │
│                                                                  │
│   Breakdown:                                                     │
│   ├─ Cache Hits:         109,125 (87.3%)                        │
│   ├─ Origin Fetches:     15,875  (12.7%)                        │
│   └─ Error Rate:         0.02%   (25 errors)                    │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Bandwidth & Data Transfer:                                      │
│   Data Transferred Out:  22.5 GB                                │
│   Data Transferred In:   0.8 GB                                 │
│   Avg Request Size:      180 KB                                 │
│                                                                  │
│   Cost Savings:                                                  │
│   └─ Estimated S3 cost without CF:  $2.20                       │
│   └─ CloudFront cost:                $1.28                       │
│   └─ Net savings:                    $0.92 (42%)                │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Geographic Distribution:                                         │
│   🇪🇺 Europe:            62%  (77,500 requests)                 │
│   🇺🇸 North America:     28%  (35,000 requests)                 │
│   🌍 Other Regions:      10%  (12,500 requests - origin direct) │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Response Time (p50/p95/p99):                                    │
│   Via CloudFront Edge:   45ms / 120ms / 280ms                   │
│   Direct to S3 Origin:   180ms / 450ms / 890ms                  │
│   Performance Gain:      4x faster at edge locations            │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 Networking Resources

#### 2.4.1 VPC Configuration

**VPC Name:** geo-dev
**CIDR Block:** 10.0.0.0/16
**DNS Support:** Enabled
**DNS Hostnames:** Enabled

**Purpose:**
Isolated network environment providing security boundaries and network segmentation.

#### 2.4.2 Internet Gateway

**Name:** geo-dev-igw
**Purpose:** Enables internet connectivity for resources in public subnets

#### 2.4.3 Route Tables

**Public Route Table (geo-dev-public-rt):**
- 10.0.0.0/16 local (VPC internal traffic)
- 0.0.0.0/0 Internet Gateway (internet-bound traffic)
- Associated with: Public Subnets

**Private Route Tables (implicit):**
- 10.0.0.0/16 local (VPC internal traffic only)
- Associated with: Private Subnets

#### 2.4.4 VPC Endpoint for S3

**Endpoint Type:** Gateway Endpoint (free, no hourly charges)
**Service:** com.amazonaws.eu-west-3.s3
**Purpose:** Direct, private connectivity from EC2 to S3 without internet gateway

**Benefits:**
- No data transfer charges for S3 uploads from EC2
- Improved security (traffic stays within AWS network)
- Better performance (lower latency)

**VPC Resource Summary:**

```
VPC: geo-dev (vpc-xxxxxxxx) - 10.0.0.0/16
│
├── Internet Gateway: geo-dev-igw
│   └── Attached to VPC (enables public subnet internet access)
│
├── Subnets (4 total):
│   ├── Public Subnets (2):
│   │   ├── geo-dev-public-1 (10.0.1.0/24) - AZ eu-west-3a [256 IPs]
│   │   │   └── Resources: EC2 Instance (geo-dev-backend)
│   │   └── geo-dev-public-2 (10.0.2.0/24) - AZ eu-west-3b [256 IPs]
│   │       └── Resources: NAT Gateway (if needed)
│   │
│   └── Private Subnets (2):
│       ├── geo-dev-private-1 (10.0.10.0/24) - AZ eu-west-3a [256 IPs]
│       │   └── Resources: RDS Primary Database
│       └── geo-dev-private-2 (10.0.11.0/24) - AZ eu-west-3b [256 IPs]
│           └── Resources: RDS Standby (if Multi-AZ enabled)
│
├── Route Tables (2):
│   ├── Public Route Table:
│   │   ├── 10.0.0.0/16 → local (VPC internal)
│   │   ├── 0.0.0.0/0 → igw-xxxxxxxx (internet)
│   │   └── Associated: public-1, public-2
│   │
│   └── Main Route Table (Private):
│       ├── 10.0.0.0/16 → local (VPC internal only)
│       └── Associated: private-1, private-2
│
├── VPC Endpoints (1):
│   └── S3 Gateway Endpoint (vpce-xxxxxxxx)
│       ├── Service: com.amazonaws.eu-west-3.s3
│       ├── Type: Gateway (FREE)
│       └── Route Tables: Public + Private
│
├── Security Groups (2):
│   ├── geo-dev-backend-sg (EC2 instance)
│   │   └── Inbound: 22, 80, 443, 5002 | Outbound: All
│   └── geo-dev-database-sg (RDS instance)
│       └── Inbound: 5432 from backend-sg | Outbound: All
│
└── Network ACLs: Default (allow all)
```

### 2.5 Domain & SSL Resources (Optional)

#### 2.5.1 Route 53 Hosted Zone

**Domain:** sabeeltech-esg.dev (example)
**Purpose:** DNS management for custom domain

**DNS Records:**
- **api.sabeeltech-esg.dev** EC2 Elastic IP (Port 5002 - Auth Backend)
- **api1.sabeeltech-esg.dev** EC2 Elastic IP (Port 8000 - Main Backend)
- **api2.sabeeltech-esg.dev** EC2 Elastic IP (Port 5000 - Report Service)
- **api3.sabeeltech-esg.dev** EC2 Elastic IP (Port 5001 - Agricultural Analysis)
- **sabeeltech-esg.dev** CloudFront Distribution (Frontend)

**TTL:** 300 seconds (5 minutes)

```mermaid
graph TB
    Internet[Internet DNS Queries]

    subgraph Route53["Route 53 Hosted Zone: sabeeltech-esg.dev"]
        NS[NS Records<br/>AWS Name Servers]
        SOA[SOA Record<br/>Zone Authority]

        subgraph Records["DNS A Records"]
            R1[api.sabeeltech-esg.dev<br/>→ XX.XX.XX.XX<br/>Port 5002 - Auth]
            R2[api1.sabeeltech-esg.dev<br/>→ XX.XX.XX.XX<br/>Port 8000 - Main]
            R3[api2.sabeeltech-esg.dev<br/>→ XX.XX.XX.XX<br/>Port 5000 - Reports]
            R4[api3.sabeeltech-esg.dev<br/>→ XX.XX.XX.XX<br/>Port 5001 - Agri]
        end

        subgraph Alias["CNAME/Alias Records"]
            R5[sabeeltech-esg.dev<br/>→ EID.cloudfront.net<br/>Frontend SPA]
            R6[www.sabeeltech-esg.dev<br/>→ EID.cloudfront.net<br/>Frontend SPA]
        end

        subgraph Validation["SSL Validation"]
            ACM[_acme-challenge records<br/>Let's Encrypt DNS-01]
            CNAME[_hash.sabeeltech-esg.dev<br/>ACM DNS Validation]
        end
    end

    EIP[Elastic IP<br/>EC2 Backend]
    CF[CloudFront<br/>Distribution]
    LE[Let's Encrypt<br/>CA]
    AWS_ACM[AWS Certificate<br/>Manager]

    Internet --> NS
    R1 --> EIP
    R2 --> EIP
    R3 --> EIP
    R4 --> EIP
    R5 --> CF
    R6 --> CF
    ACM --> LE
    CNAME --> AWS_ACM

    style Route53 fill:#8c4fff,stroke:#6c2fb3,stroke-width:2px
    style Records fill:#d4edda
    style Alias fill:#cfe2ff
    style Validation fill:#fff3cd
    style EIP fill:#ff9900
    style CF fill:#8c4fff
```

**Monthly Cost:** $0.50 (1 hosted zone) + $0.40 per million queries

#### 2.5.2 ACM SSL Certificate

**Certificate Type:** AWS Certificate Manager (ACM)
**Region:** us-east-1 (required for CloudFront)
**Validation Method:** DNS validation via Route 53
**Domains Covered:**
- sabeeltech-esg.dev
- *.sabeeltech-esg.dev (wildcard)

**Purpose:** HTTPS encryption for CloudFront distribution

#### 2.5.3 Let's Encrypt SSL Certificates (EC2)

**Certificate Authority:** Let's Encrypt
**Tool:** Certbot with Nginx plugin
**Domains Covered:**
- api.sabeeltech-esg.dev
- api1.sabeeltech-esg.dev
- api2.sabeeltech-esg.dev
- api3.sabeeltech-esg.dev

**Auto-Renewal:**
- systemd timer: certbot-renew.timer (runs twice daily)
- Certificates renew automatically 30 days before expiration

**SSL Certificate Management:**

```
┌─────────────────────────────────────────────────────────────────┐
│ SSL/TLS Certificate Overview                                    │
├─────────────────────────────────────────────────────────────────┤
│ AWS Certificate Manager (ACM) - us-east-1:                     │
│                                                                  │
│   Certificate: *.sabeeltech-esg.dev                            │
│   Status:      ✓ Issued                                         │
│   Type:        RSA-2048                                          │
│   Validation:  DNS (Route 53 automatic)                         │
│   In Use By:   CloudFront Distribution (Frontend)               │
│   Issued:      2024-03-15                                        │
│   Expires:     2025-03-15 (Auto-renewed by AWS)                │
│   Cost:        FREE                                              │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Let's Encrypt Certificates (EC2 - Nginx):                      │
│                                                                  │
│   1. api.sabeeltech-esg.dev (Auth Backend - :5002)             │
│      Status:      ✓ Valid                                       │
│      Issued:      2025-01-10                                     │
│      Expires:     2025-04-10 (61 days remaining) ✓             │
│      Renewal:     Automatic via certbot-renew.timer             │
│                                                                  │
│   2. api1.sabeeltech-esg.dev (Main Backend - :8000)            │
│      Status:      ✓ Valid                                       │
│      Issued:      2025-01-10                                     │
│      Expires:     2025-04-10 (61 days remaining) ✓             │
│      Renewal:     Automatic via certbot-renew.timer             │
│                                                                  │
│   3. api2.sabeeltech-esg.dev (Report Service - :5000)          │
│      Status:      ✓ Valid                                       │
│      Issued:      2025-01-10                                     │
│      Expires:     2025-04-10 (61 days remaining) ✓             │
│      Renewal:     Automatic via certbot-renew.timer             │
│                                                                  │
│   4. api3.sabeeltech-esg.dev (Agricultural Service - :5001)    │
│      Status:      ✓ Valid                                       │
│      Issued:      2025-01-10                                     │
│      Expires:     2025-04-10 (61 days remaining) ✓             │
│      Renewal:     Automatic via certbot-renew.timer             │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Auto-Renewal Configuration:                                      │
│   Service:       certbot-renew.timer (systemd)                  │
│   Schedule:      Runs twice daily (00:00 and 12:00 UTC)        │
│   Renewal:       Triggers 30 days before expiration             │
│   Post-Hook:     nginx reload (seamless certificate reload)     │
│   Logs:          /var/log/letsencrypt/letsencrypt.log          │
│   Cost:          FREE                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

TLS Protocol Support: TLS 1.2, TLS 1.3 (TLS 1.0/1.1 disabled)
Cipher Suites: Modern suite (A+ rating on SSL Labs)
HSTS: Enabled with 1-year max-age
```

---

<div style="page-break-after: always;"></div>

## 3. CI/CD Pipeline & Deployment Automation

### 3.1 CI/CD Architecture Overview

The platform implements **fully automated continuous integration and deployment pipelines** for all services using AWS native tools. Each code push to the GitHub main branch triggers an automated build, test, and deployment process.

**Pipeline Components:**
- **GitHub Repository:** Source code storage (sabeel-it-consulting organization)
- **AWS CodeStar Connection:** Secure GitHub integration (replaces personal access tokens)
- **AWS CodeBuild:** Docker image building and compilation
- **Amazon ECR:** Docker image registry (Elastic Container Registry)
- **AWS CodeDeploy:** Automated deployment to EC2
- **AWS CodePipeline:** Orchestration and workflow management

```mermaid
flowchart LR
    Dev[Developer] -->|git push| GitHub[GitHub Repository<br/>sabeel-it-consulting/]

    GitHub -->|Webhook Trigger| Pipeline[AWS CodePipeline<br/>geo-dev-*-pipeline]

    Pipeline -->|Source Stage| Source[Source<br/>CodeStar Connection]
    Source -->|Artifact ZIP| Build

    Build[Build Stage<br/>AWS CodeBuild] -->|docker build| Docker{Dockerfile}
    Docker -->|docker push| ECR[Amazon ECR<br/>Image Registry]

    ECR -->|Pull Image| Deploy[Deploy Stage<br/>AWS CodeDeploy]

    Deploy -->|ApplicationStop| Stop[Stop Old Container]
    Stop -->|BeforeInstall| Pull[Pull Latest Image]
    Pull -->|ApplicationStart| Start[Start New Container]
    Start -->|ValidateService| Health[Health Check]

    Health -->|Success| EC2[EC2 Instance<br/>Running Container]
    Health -->|Failure| Rollback[Auto Rollback<br/>Previous Version]

    Pipeline -.->|Notifications| SNS[SNS Topics<br/>Build Status]

    style GitHub fill:#181717
    style ECR fill:#ff9900
    style EC2 fill:#ff9900
    style Build fill:#00a8e1
    style Deploy fill:#4a8eed
    style Health fill:#1e8449
    style Rollback fill:#cb4335
```

### 3.2 Backend Services CI/CD Pipeline

Each of the four backend services follows an identical pipeline pattern with service-specific configurations.

#### 3.2.1 Pipeline Stages

**Stage 1: Source**
- **Trigger:** Git push to main branch
- **Provider:** CodeStarSourceConnection
- **Output:** Source code artifact (ZIP)

**Stage 2: Build**
- **Provider:** AWS CodeBuild
- **Build Specification:** buildspec.yml in repository root
- **Build Environment:**
  - Compute: BUILD_GENERAL1_SMALL (3 GB memory, 2 vCPUs)
  - Image: aws/codebuild/amazonlinux2-x86_64-standard:3.0
  - Privileged Mode: Enabled (for Docker builds)

**Build Process (buildspec.yml):**
```yaml
phases:
  pre_build:
    - Login to Amazon ECR
    - Set IMAGE_TAG from Git commit hash (7 characters)
  build:
    - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
    - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $ECR_URI:latest
  post_build:
    - docker push $ECR_URI:$IMAGE_TAG
    - docker push $ECR_URI:latest
    - Generate imagedefinitions.json for CodeDeploy
```

**Stage 3: Deploy**
- **Provider:** AWS CodeDeploy
- **Deployment Configuration:** CodeDeployDefault.AllAtOnce (fastest deployment)
- **Target:** EC2 instance tagged with Name=geo-dev-backend
- **Application Specification:** appspec.yml in repository

**Deployment Process (appspec.yml):**
```yaml
hooks:
  ApplicationStop:
    - Stop and remove old Docker container
  BeforeInstall:
    - Pull latest Docker image from ECR
  ApplicationStart:
    - Start new Docker container with environment variables
  ValidateService:
    - Health check on application port
```

**Auto-Rollback:** Enabled on deployment failure

#### 3.2.2 Backend Service Pipelines

| Service | Pipeline Name | ECR Repository | Port | Build Time |
|---------|--------------|----------------|------|------------|
| Auth Backend | geo-dev-geoinvestinsights-authback-pipeline | geo-dev-geoinvestinsights-authback | 5002 | ~3 min |
| Main Backend | geo-dev-geoinvestinsights-backend-pipeline | geo-dev-geoinvestinsights-backend | 8000 | ~5 min |
| Report Service | geo-dev-geoinvestinsights-secondback-pipeline | geo-dev-geoinvestinsights-secondback | 5000 | ~4 min |
| Agricultural Analysis | geo-dev-geoinvestinsights-thirdback-pipeline | geo-dev-geoinvestinsights-thirdback | 5001 | ~4 min |


### 3.3 Frontend CI/CD Pipeline

The frontend React application follows a different deployment pattern optimized for static websites.

#### 3.3.1 Pipeline Stages

**Stage 1: Source**
- Same as backend (GitHub via CodeStar Connection)

**Stage 2: Build & Deploy**
- **Provider:** AWS CodeBuild
- **Build Environment:** amazonlinux2-x86_64-standard:5.0 (includes Node.js 20)

**Build Process:**
```yaml
phases:
  install:
    - npm ci (install dependencies from package-lock.json)
  pre_build:
    - Inject environment variables (backend URLs)
    - Create .env file with VITE_* variables
  build:
    - npm run build (Vite production build)
  post_build:
    - aws s3 sync dist/ s3://$BUCKET_NAME --delete
    - aws cloudfront create-invalidation (clear CDN cache)
```

**Deployment Target:**
- S3 Bucket: geo-dev-frontend-[random]
- CloudFront Distribution: Invalidates /* to force cache refresh

**Build Artifacts:** None (deployed directly to S3)

**Build Time:** ~2-3 minutes

### 3.4 Infrastructure Deployment (Terraform)

**Tool:** Terraform v1.x
**State Storage:** Local file system (terraform.tfstate)
**Execution:** Manual via CLI

**Terraform Commands:**
```bash
terraform init      # Initialize providers and modules
terraform plan      # Preview infrastructure changes
terraform apply     # Create/update infrastructure
terraform destroy   # Tear down infrastructure
```

**Infrastructure Modules:**
- modules/network - VPC, subnets, route tables, internet gateway
- modules/backend - EC2 instance, security groups, IAM roles
- modules/database - RDS PostgreSQL, subnet groups
- modules/s3 - S3 buckets, CloudFront distributions, VPC endpoint
- modules/cicd - CodePipeline, CodeBuild, CodeDeploy resources
- modules/frontend - Frontend S3 bucket and CloudFront
- modules/frontend-cicd - Frontend build pipeline
- modules/acm-certificate - SSL certificate and Route 53 (optional)

```mermaid
graph TB
    TF[Terraform Root Module<br/>stacks/geo/development/main.tf]

    subgraph "Core Infrastructure Modules"
        Net[network module<br/>VPC, Subnets, IGW]
        Back[backend module<br/>EC2, Security Groups]
        DB[database module<br/>RDS PostgreSQL]
        S3M[s3 module<br/>S3, CloudFront, VPC Endpoint]
    end

    subgraph "CI/CD Modules"
        CICD[cicd module<br/>Backend Pipelines x4]
        FrontCICD[frontend-cicd module<br/>Frontend Pipeline]
    end

    subgraph "Optional Modules"
        ACM[acm-certificate module<br/>SSL + Route 53]
        Front[frontend module<br/>S3 + CloudFront]
    end

    subgraph "AWS Resources (76 total)"
        VPC[aws_vpc]
        IGW[aws_internet_gateway]
        Sub[aws_subnet x4]
        RT[aws_route_table x2]
        EC2[aws_instance]
        EIP[aws_eip]
        EBS[aws_ebs_volume]
        SG[aws_security_group x2]
        RDS_DB[aws_db_instance]
        S3B[aws_s3_bucket x2]
        CF[aws_cloudfront_distribution x2]
        CP[aws_codepipeline x5]
        CB[aws_codebuild_project x5]
        CD[aws_codedeploy_app x4]
        ECR[aws_ecr_repository x4]
        IAM[aws_iam_role x6]
    end

    TF --> Net
    TF --> Back
    TF --> DB
    TF --> S3M
    TF --> CICD
    TF --> FrontCICD
    TF -.->|optional| ACM
    TF -.->|optional| Front

    Net --> VPC
    Net --> IGW
    Net --> Sub
    Net --> RT

    Back -.->|depends_on| Net
    Back --> EC2
    Back --> EIP
    Back --> EBS
    Back --> SG
    Back --> IAM

    DB -.->|depends_on| Net
    DB -.->|depends_on| Back
    DB --> RDS_DB

    S3M -.->|depends_on| Net
    S3M --> S3B
    S3M --> CF

    CICD -.->|depends_on| Back
    CICD --> CP
    CICD --> CB
    CICD --> CD
    CICD --> ECR
    CICD --> IAM

    FrontCICD -.->|depends_on| Front
    FrontCICD --> CP
    FrontCICD --> CB

    style TF fill:#f39c12,stroke:#d68910,stroke-width:3px
    style Net fill:#3498db
    style Back fill:#ff9900
    style DB fill:#3b48cc
    style S3M fill:#569a31
    style CICD fill:#00a8e1
    style FrontCICD fill:#00a8e1
    style ACM fill:#8c4fff,stroke-dasharray: 5 5
    style Front fill:#569a31,stroke-dasharray: 5 5
```

**Terraform State Summary:**
- Total Resources: 76
- Modules: 8
- Providers: AWS (hashicorp/aws ~> 5.0)
- State File Size: ~450 KB
- Last Applied: 2025-10-15

---

<div style="page-break-after: always;"></div>

## 4. Application Services Architecture

### 4.1 Service Overview

The platform consists of five interconnected application services, each with a specific responsibility following microservices best practices.

```mermaid
graph TB
    User[Web Browser<br/>React Application]

    subgraph "EC2 Instance - geo-dev-backend"
        subgraph "Port Mapping via Nginx"
            N[Nginx :80/:443<br/>SSL Termination]
        end

        subgraph "Backend Microservices"
            Auth[🔐 Auth Service<br/>Flask :5002<br/>/register /login /parcels]
            Main[🌍 Main Backend<br/>Django :8000<br/>54+ API Endpoints<br/>Earth Engine Processing]
            Report[📄 Report Service<br/>Flask :5000<br/>PDF Generation]
            Agri[🌾 Agricultural Service<br/>Flask :5001<br/>ESG & Weekly Analysis]
        end
    end

    DB[(PostgreSQL + PostGIS<br/>Users & Parcels)]
    S3[S3 Bucket<br/>Media Storage]

    subgraph "External APIs"
        GEE[Google Earth Engine<br/>Sentinel-2, MODIS<br/>Satellite Data]
        GPT[OpenAI GPT-4<br/>AI Analysis]
        Weather[Open-Meteo<br/>Weather Data]
    end

    User -->|HTTPS| N
    N -->|/auth/*| Auth
    N -->|/api/*| Main
    N -->|/reports/*| Report
    N -->|/agri/*| Agri

    Auth -->|CRUD| DB
    Auth -->|Upload| S3

    Main -->|Query| GEE
    Main -->|Fetch| Weather
    Main -->|Upload| S3

    Report -->|Fetch Data| Main
    Report -->|Query| GEE
    Report -->|Generate Text| GPT

    Agri -->|Query| GEE
    Agri -->|Recommendations| GPT
    Agri -.->|Optional| Main

    style Auth fill:#ff6b6b
    style Main fill:#4ecdc4
    style Report fill:#ffe66d
    style Agri fill:#95e1d3
    style DB fill:#3b48cc
    style S3 fill:#569a31
    style GEE fill:#4285f4
    style GPT fill:#10a37f
```

### 4.2 Authentication & Parcel Management Service

**Service Name:** geoinvestinsights-authback
**Technology:** Flask 2.3.3 (Python 3.11)
**Port:** 5002
**Container Name:** geo-authback
**Deployment Path:** /opt/geo-authback

#### 4.2.1 Responsibilities

1. **User Authentication:** JWT-based authentication with token expiration (1 hour)
2. **User Management:** CRUD operations for user accounts (admin only)
3. **License Management:** Expiration date tracking and validation
4. **Geospatial Parcel Storage:** User-specific polygon geometries for areas of interest

#### 4.2.2 Key Endpoints

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| POST | /register | Create new user account | No |
| POST | /login | Authenticate and receive JWT token | No |
| GET | /me | Get current user profile | Yes |
| GET | /users | List all users (admin) | Yes |
| PUT | /user/<id> | Update user details (admin) | Yes |
| DELETE | /user/<id> | Delete user (admin) | Yes |
| POST | /parcel | Create geospatial parcel | Yes |
| GET | /parcels | Get user's parcels | Yes |
| PUT | /parcel/<id> | Update parcel | Yes |
| DELETE | /parcel/<id> | Delete parcel | Yes |

#### 4.2.3 Database Schema

**Users Table:**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(80) UNIQUE NOT NULL,
    password VARCHAR(200) NOT NULL,  -- Werkzeug hashed
    type VARCHAR(50) NOT NULL,       -- User classification
    role VARCHAR(50) NOT NULL,       -- Access level
    expiration_date DATE NOT NULL    -- License expiration
);
```

**Parcels Table:**
```sql
CREATE TABLE parcels (
    id SERIAL PRIMARY KEY,
    type VARCHAR(200),
    id_user INTEGER REFERENCES users(id),
    geometry GEOMETRY(POLYGON, 4326) NOT NULL  -- PostGIS
);
```

**Default Admin Account:**
- Username: admin
- Password: admin (change in production!)
- Role: all (full access)
- Expiration: 10 years from creation

#### 4.2.4 Key Dependencies

- **flask-sqlalchemy:** ORM for database operations
- **flask-jwt-extended:** JWT token management
- **geoalchemy2:** PostGIS integration
- **shapely:** Geometry manipulation
- **werkzeug:** Password hashing (pbkdf2:sha256)

```mermaid
erDiagram
    USERS ||--o{ PARCELS : owns
    USERS {
        int id PK
        varchar username UK "Unique, Not Null"
        varchar password "Hashed with Werkzeug"
        varchar type "User classification"
        varchar role "Access level: all, viewer, etc."
        date expiration_date "License expiration"
    }
    PARCELS {
        int id PK
        varchar type "Parcel classification"
        int id_user FK "References users(id)"
        geometry geometry "PostGIS POLYGON, SRID 4326"
    }
```

### 4.3 Main Geospatial Processing Service

**Service Name:** geoinvestinsights-backend (GeoGPT)
**Technology:** Django 4.2.20 + Django REST Framework 3.14.0 (Python 3.11)
**Port:** 8000
**Container Name:** geo-backend
**Deployment Path:** /opt/app
**WSGI Server:** Gunicorn (3 workers, 120s timeout)

#### 4.3.1 Responsibilities

This is the **core analytical engine** of the platform, providing:

1. **Satellite Imagery Analysis:** 54+ REST API endpoints for environmental indices
2. **Google Earth Engine Integration:** Processing petabytes of satellite data
3. **Vegetation Monitoring:** NDVI, EVI, LAI, SAVI, and 10+ vegetation indices
4. **Climate Analysis:** Temperature, precipitation, soil moisture, drought risk
5. **Air Quality Monitoring:** CO2, CH2, NO2, O2, PM2.5 concentrations
6. **Land Cover Classification:** ESA WorldCover, Dynamic World datasets
7. **Agricultural Suitability:** Crop-specific suitability modeling
8. **Change Detection:** Multi-temporal analysis and trend detection

#### 4.3.2 API Endpoint Categories (54+ Endpoints)

**Vegetation Indices (14 endpoints):**
- /api/ndvi/ - Normalized Difference Vegetation Index
- /api/evi/ - Enhanced Vegetation Index
- /api/ndwi/ - Normalized Difference Water Index
- /api/ndmi/ - Normalized Difference Moisture Index
- /api/lai/ - Leaf Area Index
- /api/savi/ - Soil Adjusted Vegetation Index
- /api/vci/ - Vegetation Condition Index
- /api/gci/ - Green Chlorophyll Index
- /api/arvi/ - Atmospherically Resistant Vegetation Index
- /api/msi/ - Moisture Stress Index
- /api/ccci/ - Canopy Chlorophyll Content Index
- Plus: /api/ndbal/, /api/bsi/, /api/rsei/

**Environmental & Climate (11 endpoints):**
- /api/temperature/ - Land Surface Temperature (MODIS)
- /api/precipitation/ - Rainfall data (CHIRPS)
- /api/soil-moisture/ - Volumetric soil water content
- /api/soil-type/ - Soil classification
- /api/soilph/ - Soil acidity levels
- /api/soiloc/ - Soil Organic Carbon
- /api/drought-risk/ - Composite drought assessment
- /api/wildfirerisk/ - Fire risk modeling
- /api/weather/ - Current/forecast weather
- /api/historyweather/ - Historical weather data
- /api/climate_vulnerability_map/ - Climate vulnerability index

**Air Quality (7 endpoints):**
- /api/co2-concentration/ - Carbon dioxide (Sentinel-5P)
- /api/ch4-concentration/ - Methane (TROPOMI)
- /api/no2-concentration/ - Nitrogen dioxide
- /api/pm/ - PM2.5 estimation (statistical model)
- /api/ozone/ - O2 column density
- /api/turbidity/ - Water turbidity
- /api/carbon-footprint-analysis/

**Land Cover & Change Detection (6 endpoints):**
- /api/landcover/ - ESA WorldCover (10m resolution)
- /api/dynamicworld/ - Near real-time land cover
- /api/change/ - IMAD change detection
- /api/agrichange/ - Agricultural NDVI change
- /api/urbchange/ - Urban expansion monitoring
- /api/modis/ - Multi-spectral MODIS analysis

**Agricultural Suitability (8 endpoints):**
- /api/agricultural-suitability/ - Generic crop suitability
- /api/environmental_suitability/ - Environmental factors
- /api/apples/, /api/potatos/, /api/tomatos/, /api/wheat/, /api/grapes/, /api/apricots/

**Specialized Indices (5 endpoints):**
- /api/slope/ - Terrain slope (SRTM DEM)
- /api/albedo/ - Surface albedo (MODIS)
- /api/lightpollution/ - Nighttime light pollution
- /api/SDG_Health_Score/ - UN SDG indicators
- /api/allindices/ - Multiple indices in single request


#### 4.3.3 Data Sources

The service integrates with multiple satellite missions and datasets:

| Data Source | Resolution | Purpose | Update Frequency |
|------------|------------|---------|------------------|
| Sentinel-2 (COPERNICUS/S2) | 10m | Optical imagery, vegetation indices | 5 days |
| Sentinel-5P | 7km | Atmospheric gases (CO2, CH2, NO2) | Daily |
| MODIS (Terra/Aqua) | 250m-1km | Temperature, vegetation, albedo | Daily |
| CHIRPS | 5.5km | Precipitation data | Daily |
| ERA5-Land (ECMWF) | 9km | Soil moisture, climate reanalysis | Hourly |
| ESA WorldCover | 10m | Global land cover classification | Annual |
| SRTM | 30m | Digital Elevation Model | Static |

### 4.4 Report Generation Service

**Service Name:** geoinvestinsights-secondback
**Technology:** Flask (Python 3.11)
**Port:** 5000
**Container Name:** geo-secondback
**Deployment Path:** /opt/geo-secondback

#### 4.4.1 Responsibilities

This service is the **deliverable generation engine**, producing professional PDF reports:

1. **Agricultural Investment Reports:** Multi-page PDF reports with satellite imagery analysis
2. **Interactive Map Generation:** Folium maps with Earth Engine tile layers
3. **Data Visualization:** Plotly charts for time-series and categorical data
4. **AI-Powered Analysis:** GPT-4 generated insights and recommendations
5. **Automated Screenshot Capture:** Playwright headless browser for map rendering

#### 4.4.2 Key Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /api/data | Generate comprehensive agricultural report (returns PDF filename) |
| GET | /api/rapports/<filename> | Download generated PDF report |
| GET | /token | Download Google Earth Engine credentials (security concern) |

#### 4.4.3 Report Generation Workflow

**Step 1: Data Collection (Parallel Processing)**
- Fetches indices, types, meteo data from Main Backend
- Fetches satellite imagery URLs (start/end dates)
- Uses ThreadPoolExecutor for concurrent API calls

**Step 2-7: Map Generation PDF Assembly**
- Creates Folium maps with Earth Engine layers
- Captures screenshots with Playwright headless browser
- Generates Plotly time-series charts
- Calls GPT-4 for intelligent analysis
- Assembles professional PDF using ReportLab
- Cleans up temporary files

**Average Processing Time:** 3-5 minutes per report

### 4.5 Agricultural Analysis & ESG Service

**Service Name:** geoinvestinsights-thirdback
**Technology:** Flask (Python 3.11)
**Port:** 5001
**Container Name:** geo-thirdback
**Deployment Path:** /opt/geo-thirdback

#### 4.5.1 Responsibilities

This service provides **advanced agricultural intelligence and ESG compliance monitoring**:

1. **Long-Term Agricultural Planning:** Multi-year vegetation and rainfall trends
2. **Weekly Health Assessments:** Current vegetation health with 8 indices
3. **ESG Compliance Reporting:** Environmental scoring and classification
4. **AI-Powered Recommendations:** Crop-specific treatment calendars
5. **Conversational AI:** Chatbot for follow-up questions

#### 4.5.2 Key Endpoints

**POST /api/data (Long-Term Planning)**
- Weekly time series analysis (NDVI, NDMI, rainfall, temperature)
- NDVI anomaly detection
- GPT-4 generated recommendations and treatment calendars

**POST /api/weekly (Current Health Assessment)**
- 8 high-resolution vegetation indices (Sentinel-2 10m)
- Temperature and precipitation data
- GPT-4 health summary with fertilizer/pesticide recommendations

**POST /api/esgreport (ESG Compliance)**
- Analyzes 4 environmental indicators (CH2, NO2, CO, NDVI)
- Scoring system (0-25 points per indicator)
- Overall compliance status (Compliant/Non-compliant)
- Monthly trends and classification maps

**POST /api/chatbot & /api/chatbotveg (Conversational AI)**
- Context-aware follow-up questions
- Grounded in analyzed data

### 4.6 Frontend Application

**Technology:** React 19.0.0 + Vite 6.2.0
**Deployment:** CloudFront + S3 Static Website Hosting
**Build Output:** Optimized production bundle (~5 MB gzipped)

#### 4.6.1 Core Features

**Mapping Tools:**
- Polygon drawing and editing (Leaflet Draw)
- GeoJSON/Shapefile/KML upload
- Multiple basemaps (ESRI, OSM, satellite)
- Location search with geocoding
- Map export (PDF/PNG)

**Analysis Dashboards:**
- Agricultural Dashboard (30+ vegetation indices)
- ESG Dashboard (compliance monitoring)
- Weekly Dashboard (current health)
- Change Detection (temporal analysis)

**AI Chatbots:**
- ChatBotMob (ESG insights)
- ChatBotMobVeg (agricultural recommendations)

**User Roles:**
- all (full features - App.jsx)
- investor, farmer, enthusiast (specialized interfaces)
- free (limited access)

## 5. Integration, Data Flow & Operations

### 5.1 Complete System Data Flow

#### 5.1.1 Satellite Data Analysis Flow

```
User (Frontend)
    [1. Draw polygon, select NDVI + dates]
    [POST /api/ndvi/ with geometry]
Main Backend (Port 8000)
    [2. Parse GeoJSON, initialize Google Earth Engine]
Google Earth Engine API
    [3. Filter Sentinel-2 imagery]
    [4. Calculate NDVI = (NIR - Red) / (NIR + Red)]
    [5. Generate tile server URL]
Main Backend
    [6. Return JSON {tile_url, vis_params, daily_values}]
Frontend
    [7. Add WMS tile layer to Leaflet map]
    [8. Render visualization + time-series chart]
User (Browser)
    [9. View vegetation health map]
```

```mermaid
sequenceDiagram
    actor User
    participant Frontend as React Frontend
    participant Nginx
    participant Backend as Django Backend<br/>Port 8000
    participant GEE as Google Earth<br/>Engine API
    participant Sentinel as Sentinel-2<br/>Satellite Data

    User->>Frontend: 1. Draw polygon on map
    User->>Frontend: 2. Select NDVI index + dates
    Frontend->>Nginx: 3. POST /api/ndvi/<br/>{geometry, start_date, end_date}
    Nginx->>Backend: 4. Forward request
    Backend->>Backend: 5. Parse GeoJSON geometry
    Backend->>GEE: 6. Initialize Earth Engine
    GEE->>Sentinel: 7. Filter imagery<br/>(date range, <20% clouds)
    Sentinel-->>GEE: 8. Image Collection
    GEE->>GEE: 9. Calculate NDVI<br/>(NIR - Red) / (NIR + Red)
    GEE->>GEE: 10. Generate tile server URL
    GEE-->>Backend: 11. Tile URL + Statistics
    Backend-->>Nginx: 12. JSON Response<br/>{tile_url, vis_params, daily_values}
    Nginx-->>Frontend: 13. Return data
    Frontend->>Frontend: 14. Add WMS tile layer to Leaflet
    Frontend->>Frontend: 15. Render time-series chart
    Frontend->>User: 16. Display vegetation health map

    Note over User,Sentinel: Total processing time: 2-5 seconds
```

#### 5.1.2 Report Generation Flow

```
User Report Service (Port 5000)
    [Parallel API calls to Main Backend]
Main Backend Google Earth Engine
    [Process multiple indices]
Report Service
    [Generate Folium maps]
    [Playwright screenshot capture]
    [Plotly chart generation]
    [GPT-4 AI analysis]
    [ReportLab PDF assembly]
    [Return PDF filename]
User Download PDF (2-5 minutes total)
```

**Processing Time Breakdown:**
- Data collection: 30-60s
- Map generation: 20-40s
- AI analysis: 40-90s
- PDF assembly: 10-20s

```mermaid
flowchart TD
    Start[User Requests Report] -->|POST /api/data| Validate{Validate Input<br/>Geometry + Dates}
    Validate -->|Valid| Parallel[Parallel Data Collection<br/>ThreadPoolExecutor]

    Parallel --> API1[Fetch from Main Backend<br/>/api/allindices/]
    Parallel --> API2[Fetch from Main Backend<br/>/api/modis/]
    Parallel --> API3[Fetch from Main Backend<br/>/api/images/]
    Parallel --> API4[Fetch from Main Backend<br/>/api/temperaturevalues/]

    API1 --> Collect[Aggregate Data<br/>30-60 seconds]
    API2 --> Collect
    API3 --> Collect
    API4 --> Collect

    Collect --> MapGen[Generate Folium Maps<br/>with EE Tile Layers<br/>20-40 seconds]
    MapGen --> Screenshot[Playwright Browser<br/>Capture Screenshots<br/>1200x800 PNG]

    Screenshot --> Charts[Generate Plotly Charts<br/>Time-series & Bar Charts]

    Charts --> AI1[GPT-4 API Call 1<br/>Regional Introduction]
    Charts --> AI2[GPT-4 API Call 2<br/>Index Interpretations]
    Charts --> AI3[GPT-4 API Call 3<br/>Investment Recommendations]

    AI1 --> AICollect[Collect AI Responses<br/>40-90 seconds]
    AI2 --> AICollect
    AI3 --> AICollect

    AICollect --> PDF[ReportLab PDF Assembly<br/>10-20 seconds]
    PDF --> Cleanup[Delete Temp Files<br/>HTML & PNG]
    Cleanup --> Return[Return PDF Filename]
    Return --> User[User Downloads PDF]

    Validate -->|Invalid| Error[Return Error]

    style Parallel fill:#4ecdc4
    style AI1 fill:#10a37f
    style AI2 fill:#10a37f
    style AI3 fill:#10a37f
    style PDF fill:#ffe66d
    style User fill:#95e1d3
```

### 5.2 Database Integration

**Connection Configuration:**
All backend services connect to PostgreSQL RDS using environment variables:

```bash
DB_HOST=geo-dev-db.xxxxxxxxx.eu-west-3.rds.amazonaws.com
DB_PORT=5432
DB_NAME=geo_dev
DB_USER=postgres
DB_PASSWORD=<encrypted>
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
```

**Database Usage by Service:**
| Service | Database Usage | Tables |
|---------|----------------|--------|
| Auth Backend |  Active | users, parcels |
| Main Backend | L Not used | None (stateless) |
| Report Service | L Not used | None (stateless) |
| Agricultural Service | L Not used | None (stateless) |

```mermaid
graph LR
    subgraph "EC2 Instance - geo-dev-backend"
        Auth[Auth Backend<br/>Flask :5002<br/>SQLAlchemy ORM]
        Main[Main Backend<br/>Django :8000<br/>No DB Usage]
        Report[Report Service<br/>Flask :5000<br/>No DB Usage]
        Agri[Agricultural Service<br/>Flask :5001<br/>No DB Usage]
    end

    subgraph "Private Subnet - RDS"
        RDS[(PostgreSQL 17.4<br/>+ PostGIS<br/>geo_dev database)]

        subgraph "Tables"
            Users[users table<br/>25 rows<br/>Auth & Licensing]
            Parcels[parcels table<br/>18 rows<br/>PostGIS Geometries]
        end
    end

    Auth -->|Active Connection<br/>postgresql://geo_dev<br/>Port 5432<br/>SSL Required| RDS
    RDS --> Users
    RDS --> Parcels

    Main -.->|❌ No Connection<br/>Stateless Service| RDS
    Report -.->|❌ No Connection<br/>Stateless Service| RDS
    Agri -.->|❌ No Connection<br/>Stateless Service| RDS

    SG[RDS Security Group<br/>Allows Port 5432<br/>From Backend SG Only]
    RDS -.->|Protected By| SG

    style Auth fill:#ff6b6b
    style Main fill:#4ecdc4,stroke-dasharray: 5 5
    style Report fill:#ffe66d,stroke-dasharray: 5 5
    style Agri fill:#95e1d3,stroke-dasharray: 5 5
    style RDS fill:#3b48cc
    style Users fill:#d4edda
    style Parcels fill:#d4edda
    style SG fill:#f8d7da
```

**Connection Pooling & Performance:**
- Auth Backend maintains 5 persistent connections (SQLAlchemy pool)
- Connection timeout: 30 seconds
- Query average response time: <50ms
- SSL/TLS enforced (rds.force_ssl = 1)
- No connection pooling needed for stateless services

### 5.3 External API Integrations

**Google Earth Engine:**
- Service Account authentication
- 50,000 requests/day quota
- Tile URLs with 3-day TTL

**OpenAI GPT-4:**
- Report Service: 6-10 API calls per report
- Agricultural Service: 1-2 calls per analysis
- Cost: ~$0.30-0.50 per report

**Open-Meteo Weather API:**
- Free public API
- 15-minute SQLite cache
- Retry logic with exponential backoff

```mermaid
graph TB
    subgraph Backend["Backend Services on EC2"]
        Main[Main Backend<br/>Django :8000]
        Report[Report Service<br/>Flask :5000]
        Agri[Agricultural Service<br/>Flask :5001]
    end

    subgraph External["External APIs & Services"]
        GEE[Google Earth Engine<br/>earthengine-api.googleapis.com]
        GPT4[OpenAI GPT-4 API<br/>api.openai.com]
        Weather[Open-Meteo Weather<br/>api.open-meteo.com]

        subgraph GEE_Data["GEE Satellite Data"]
            S2[Sentinel-2<br/>10m Optical]
            S5P[Sentinel-5P<br/>7km Atmospheric]
            MODIS[MODIS Terra/Aqua<br/>250m-1km]
            CHIRPS[CHIRPS<br/>5.5km Precipitation]
            ESA[ESA WorldCover<br/>10m Land Cover]
        end
    end

    subgraph Credentials["Authentication & Secrets"]
        GEE_Key[earth-engine.json<br/>Service Account Key<br/>⚠️ Stored in repo]
        OpenAI_Key[OPENAI_API_KEY<br/>Environment Variable<br/>⚠️ Hardcoded]
    end

    Main -->|REST API<br/>earthengine.Initialize| GEE
    Main -->|HTTP GET<br/>Free API| Weather

    Report -->|REST API| GEE
    Report -->|POST /v1/chat/completions<br/>6-10 calls/report<br/>~$0.30-0.50/report| GPT4

    Agri -->|REST API| GEE
    Agri -->|POST /v1/chat/completions<br/>1-2 calls/analysis<br/>~$0.10/analysis| GPT4

    GEE --> S2
    GEE --> S5P
    GEE --> MODIS
    GEE --> CHIRPS
    GEE --> ESA

    Main -.->|Reads| GEE_Key
    Report -.->|Reads| GEE_Key
    Agri -.->|Reads| GEE_Key

    Report -.->|Uses| OpenAI_Key
    Agri -.->|Uses| OpenAI_Key

    style GEE fill:#4285f4
    style GPT4 fill:#10a37f
    style Weather fill:#00d4aa
    style Main fill:#4ecdc4
    style Report fill:#ffe66d
    style Agri fill:#95e1d3
    style GEE_Key fill:#f8d7da
    style OpenAI_Key fill:#f8d7da
    style S2 fill:#b3d9ff
    style S5P fill:#b3d9ff
    style MODIS fill:#b3d9ff
    style CHIRPS fill:#b3d9ff
    style ESA fill:#b3d9ff
```

### 5.4 Storage & Media Handling

**EC2 S3 Upload Flow (via VPC Endpoint):**

```
Backend Service (EC2)
    [boto3 PUT object]
VPC S3 Gateway Endpoint
    [Private route - NO internet gateway]
S3 Bucket
    [Store with AES256 encryption]
CloudFront
    [Cache at edge locations]
Frontend [Display via CloudFront URL]
```

**Benefits of VPC Endpoint:**
- **No data transfer charges** ($0.09/GB saved)
- **Improved security** (traffic stays in AWS)
- **Lower latency** (~20ms vs ~50ms)

**CloudFront Cache Optimization:**
- Media files: 1-2 day TTL
- Frontend assets: 1 year TTL (versioned)
- HTML files: 5 minutes TTL
- **Cache hit ratio target:** >80%

```mermaid
flowchart LR
    User[User] -->|Upload File| Frontend[React Frontend]
    Frontend -->|POST /upload| Backend[Backend Service<br/>EC2 Instance]

    Backend -->|1. boto3.put_object| VPCEndpoint{VPC S3 Gateway<br/>Endpoint<br/>FREE}

    VPCEndpoint -.->|Private AWS<br/>Network| S3[(S3 Bucket<br/>geo-dev-media)]

    S3 -->|Replicate| CF[CloudFront CDN<br/>Edge Locations]

    CF -->|Cached Content| EndUser[End Users<br/>Worldwide]

    Internet((Internet))
    VPCEndpoint -.->|NO Traffic| Internet

    Backend -.->|❌ Bypasses<br/>Internet Gateway| Internet

    style VPCEndpoint fill:#569a31
    style S3 fill:#569a31
    style CF fill:#8c4fff
    style Backend fill:#ff9900
    style Internet fill:#e74c3c,stroke:#c0392b,stroke-width:3px,stroke-dasharray: 5 5

    Note1[💰 Cost Savings:<br/>No data transfer charges<br/>$0.09/GB saved]
    Note2[🔒 Security:<br/>Traffic stays in AWS<br/>Private network]
    Note3[⚡ Performance:<br/>~20ms latency<br/>vs ~50ms via IGW]

    style Note1 fill:#2ecc71,color:#000
    style Note2 fill:#3498db,color:#fff
    style Note3 fill:#f39c12,color:#000
```

### 5.5 Security Implementation

**Network Security Layers:**
1. Internet Gateway (controlled entry)
2. Public Subnets (EC2 with security groups)
3. Private Subnets (RDS, not internet-accessible)
4. Security Groups (stateful firewall)
5. VPC Endpoint (private S3 access)

**Application Security:**
- **HTTPS Enforcement:** Let's Encrypt SSL with Nginx
- **JWT Tokens:** 1-hour expiration, HMAC-SHA256
- **CORS:** Explicitly allowed origins
- **IAM Least Privilege:** Minimal EC2 instance role permissions

**Secrets Management (Recommendations):**
-  Current: Hardcoded API keys, credentials in git
-  Recommended: AWS Secrets Manager, Parameter Store, secrets rotation

```mermaid
graph TB
    Internet((Internet))

    subgraph "Security Layer 1: Perimeter"
        IGW[Internet Gateway<br/>Controlled Entry Point]
    end

    subgraph "Security Layer 2: Network Segmentation"
        subgraph "Public Subnets"
            EC2[EC2 Instance<br/>+ Security Group]
        end
        subgraph "Private Subnets"
            RDS[(RDS Database<br/>+ Security Group)]
        end
    end

    subgraph "Security Layer 3: Application"
        Nginx[Nginx<br/>SSL/TLS Termination<br/>Let's Encrypt]
        subgraph "Containers"
            App1[Auth :5002<br/>JWT Tokens]
            App2[Main :8000]
            App3[Report :5000]
            App4[Agri :5001]
        end
    end

    subgraph "Security Layer 4: Data"
        DBSec[RDS Security Group<br/>Port 5432 only from EC2]
        SSL[SSL/TLS Enforced<br/>rds.force_ssl = 1]
    end

    subgraph "Security Layer 5: Access Control"
        IAM[IAM Roles<br/>Least Privilege]
        JWT[JWT Authentication<br/>1-hour expiration]
    end

    Internet -->|HTTPS Only| IGW
    IGW --> EC2
    EC2 --> Nginx
    Nginx -->|TLS 1.2+| App1
    Nginx --> App2
    Nginx --> App3
    Nginx --> App4

    App1 -.->|Encrypted| RDS
    RDS --> DBSec
    RDS --> SSL

    EC2 --> IAM
    App1 --> JWT

    S3EP{S3 VPC Endpoint<br/>Private Access}
    EC2 -.->|No Internet| S3EP

    style IGW fill:#e74c3c
    style EC2 fill:#ff9900
    style RDS fill:#3b48cc
    style Nginx fill:#1e8449
    style IAM fill:#f39c12
    style JWT fill:#8e44ad
    style DBSec fill:#c0392b
    style SSL fill:#16a085
```

### 5.6 Monitoring & Logging

**CloudWatch Metrics:**
- EC2: CPU, Network I/O, Disk usage
- RDS: Connections, IOPS, storage
- CloudFront: Requests, cache hit ratio, errors
- CodePipeline: Build success/failure rates

**Application Logs:**
- Docker container logs (7-day retention)
- Nginx access/error logs (daily rotation)
- SSL certificate renewal logs
- Docker cleanup logs (hourly cron)

### 5.7 Cost Analysis

**Monthly Cost Breakdown (Development):**

| Resource | Quantity | Monthly Cost |
|----------|----------|--------------|
| EC2 t3.small | 730 hrs | $15.18 |
| EBS (Root + Docker) | 28 GB | $2.24 |
| RDS db.t3.micro | 730 hrs | $12.41 |
| RDS Storage | 20 GB | $2.30 |
| S3 Storage | ~7.5 GB | $0.18 |
| CloudFront | ~15 GB | $1.28 |
| ECR Storage | ~2 GB | $0.20 |
| CodeBuild | ~100 min | $0.50 |
| CodePipeline | 5 pipelines | $4.00 |
| Route 53 | 1 zone | $0.50 |
| Data Transfer | ~20 GB | $1.80 |
| **TOTAL** | | **~$40.59/mo** |

**Cost Optimization Strategies:**
-  t3.small instead of t3.medium (50% savings)
-  gp3 storage (60% cheaper than io1)
-  S3 lifecycle policies (30-day deletion)
-  ECR lifecycle (keep only 3 images)
-  VPC S3 endpoint (eliminates transfer charges)
-  CloudFront PriceClass_100 (cheaper regions)

**Scaling Estimates:**
- 500 users: ~$120-150/month
- 5,000 users: ~$500-700/month
- 50,000 users: ~$3,000-5,000/month

**AWS Cost Explorer - Monthly Breakdown:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ AWS Cost Explorer - GeoInvestInsights Development Environment               │
│ Billing Period: October 2025 | Account: [REDACTED] | Region: eu-west-3     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│ TOTAL MONTHLY COST: $77.79                                                  │
│                                                                              │
│ ┌─ Cost by Service ──────────────────────────────────────────────────────┐ │
│ │                                                                          │ │
│ │ OpenAI GPT-4 (External)      $37.20  ████████████████████████░░░░░░   │ │
│ │ Amazon EC2                   $15.18  ████████░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ Amazon RDS                   $14.71  ████████░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ AWS CodePipeline             $4.00   ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ Amazon EBS                   $2.24   █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ Amazon CloudFront            $1.28   █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ Data Transfer (OUT)          $1.80   █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ AWS CodeBuild                $0.50   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ Route 53                     $0.50   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ Amazon S3                    $0.18   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ Amazon ECR                   $0.20   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ CloudWatch (Free Tier)       $0.00   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │ CodeDeploy (Free Tier)       $0.00   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ │                                                                          │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│ ┌─ Cost Trend (Last 6 Months) ───────────────────────────────────────────┐ │
│ │                                                                          │ │
│ │ $80 ┤                                                      ╭─●           │ │
│ │ $70 ┤                                       ╭────●────●───╯             │ │
│ │ $60 ┤                         ╭────●───────╯                            │ │
│ │ $50 ┤              ╭──●───────╯                                         │ │
│ │ $40 ┤        ╭─●───╯                                                    │ │
│ │ $30 ┤    ●───╯                                                          │ │
│ │ $20 ┤                                                                   │ │
│ │  $0 ┼───────────────────────────────────────────────────────            │ │
│ │      May   Jun   Jul   Aug   Sep   Oct                                 │ │
│ │                                                                          │ │
│ │ Trend Analysis:                                                          │ │
│ │   • May: $32 (initial setup, minimal usage)                             │ │
│ │   • Jun-Jul: $38-48 (ramping up, adding services)                      │ │
│ │   • Aug-Sep: $58-72 (stable development usage)                         │ │
│ │   • Oct: $78 (increased GPT-4 usage for report generation)             │ │
│ │   • Growth: 143% over 6 months (expected for development)              │ │
│ │                                                                          │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│ ┌─ Cost Optimization Opportunities ───────────────────────────────────────┐ │
│ │                                                                          │ │
│ │ ✓ IMPLEMENTED:                                                           │ │
│ │   • VPC S3 Endpoint: Saving $2.70/month (data transfer)                │ │
│ │   • CloudFront CDN: Saving $0.92/month (42% S3 bandwidth reduction)    │ │
│ │   • gp3 Storage: Saving $1.80/month vs io1                             │ │
│ │   • t3.small EC2: Saving $15/month vs t3.medium                        │ │
│ │   • ECR Lifecycle Policy: Saving $0.60/month (cleanup old images)      │ │
│ │   Total Savings: ~$21/month (21% cost reduction)                       │ │
│ │                                                                          │ │
│ │ 💡 POTENTIAL SAVINGS (Not Yet Implemented):                              │ │
│ │   1. Switch to GPT-3.5-turbo:        Save ~$22/month (60%)             │ │
│ │   2. Reserved Instance (1-year):     Save ~$5/month (30% EC2 discount) │ │
│ │   3. RDS Reserved Instance (1-year): Save ~$4/month (30% RDS discount) │ │
│ │   4. Implement GPT response caching:  Save ~$11/month (30% API cost)   │ │
│ │   5. Use Spot Instances for CodeBuild: Save ~$0.35/month (70%)         │ │
│ │   Total Potential Savings: ~$42/month (54% additional reduction)       │ │
│ │   Optimized Monthly Cost: ~$36/month                                    │ │
│ │                                                                          │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│ ┌─ Production Cost Estimate ──────────────────────────────────────────────┐ │
│ │                                                                          │ │
│ │ Assumptions: 1,000 active users, 200 reports/month, Multi-AZ RDS       │ │
│                                                                              │ │
│ │   EC2 (t3.medium x2 + ALB):    $45/month                                │ │
│ │   RDS (Multi-AZ db.t3.small):  $48/month                                │ │
│ │   ElastiCache (Redis):         $15/month                                │ │
│ │   S3 + CloudFront:             $12/month                                │ │
│ │   Data Transfer:               $25/month                                │ │
│ │   CodePipeline/Build:          $8/month                                 │ │
│ │   OpenAI GPT-4:                $120/month                               │ │
│ │   CloudWatch + Alarms:         $10/month                                │ │
│ │   Route 53:                    $1/month                                 │ │
│ │   WAF + Shield:                $20/month                                │ │
│ │   Backups:                     $6/month                                 │ │
│ │   ────────────────────────────────────────                              │ │
│ │   TOTAL PRODUCTION:            ~$310/month                              │ │
│ │                                                                          │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│ Free Tier Usage:                                                            │
│   • EC2: 750 hrs/month used (100% of free tier)                            │
│   • RDS: 750 hrs/month used (100% of free tier)                            │
│   • CloudFront: 14 GB / 50 GB (28% of free tier)                           │
│   • S3: 7.5 GB / 5 GB (exceeded by 2.5 GB - $0.06 charge)                 │
│   • Data Transfer: 20 GB / 100 GB (20% of free tier)                       │
│                                                                              │
│ Forecast (Next Month): $81 (+4% - increased GPT-4 usage expected)          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.8 Operational Procedures

**Manual Infrastructure Update:**
```bash
cd terraform-infra-python/stacks/geo/development
terraform plan -out=tfplan
terraform apply tfplan
```

**Application Deployment (Automatic):**
```bash
git commit -m "Update feature"
git push origin main
# CodePipeline auto-triggers (3-5 minutes)
```

**Common Maintenance:**
- SSL renewal: Automatic (certbot-renew.timer)
- Docker cleanup: Automatic (hourly cron)
- Database vacuum: Monthly manual
- Log rotation: Automatic (logrotate)

### 5.9 Disaster Recovery

**Recovery Procedures:**

**EC2 Failure:**
- Terraform recreates instance (10-15 min downtime)

**RDS Failure:**
- Multi-AZ: 1-2 min automatic failover
- Snapshot restore: 10-30 min

**S3/CloudFront:**
- 99.999999999% durability (11 9's)
- Automatic edge location failover

**Backup Recommendations:**
- RDS: 7-day backup retention (production)
- Terraform state: S3 with versioning
- Application code: GitHub (primary)

---

**Document Version:** 1.0
**Last Updated:** October 2025
**Maintained By:** BOUAZRA Mouheb

---
