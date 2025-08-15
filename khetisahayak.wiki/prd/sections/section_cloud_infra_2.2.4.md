# **2.2.4 Cloud Infrastructure**

*(Note: This section details the cloud hosting environment. Related NFRs are in `prd/03_non_functional_requirements.md`)*

*   **TR2.2.4.1 Hosting Platform:** The application backend, databases, and supporting services must be hosted on a major cloud platform (e.g., AWS, Google Cloud, Azure) to leverage scalability, reliability, managed services, and global reach. [TODO: Finalize cloud provider choice].
*   **TR2.2.4.2 Compute Services:** Utilize appropriate compute services based on the architectural choice:
    *   Virtual Machines (e.g., EC2, Google Compute Engine) for traditional deployments.
    *   Container Orchestration (e.g., Kubernetes - EKS, GKE, AKS) for containerized applications, enabling better scaling and management.
    *   Serverless Functions (e.g., Lambda, Cloud Functions) for event-driven processing or specific microservices (e.g., image processing triggers, notification dispatch).
*   **TR2.2.4.3 Database Services:** Leverage managed database services for operational efficiency and scalability:
    *   Managed Relational Databases (e.g., RDS, Cloud SQL).
    *   Managed NoSQL Databases (e.g., DynamoDB, Firestore, Atlas).
*   **TR2.2.4.4 Storage Services:**
    *   Object Storage (e.g., S3, Google Cloud Storage) for storing static assets like images, videos, documents, and potentially backups. Must be configured for durability and appropriate access control.
*   **TR2.2.4.5 Networking:** Configure secure virtual private clouds (VPCs), subnets, security groups/firewalls, and potentially load balancers to manage traffic and secure the infrastructure.
*   **TR2.2.4.6 Content Delivery Network (CDN):** Utilize a CDN (e.g., CloudFront, Google Cloud CDN) to cache and deliver static assets (images, frontend code) closer to users, improving load times and reducing server load.
*   **TR2.2.4.7 Scalability Mechanisms:** Implement auto-scaling for compute resources based on metrics like CPU utilization or request count to handle varying loads efficiently. Utilize load balancing to distribute traffic across multiple instances.
*   **TR2.2.4.8 Monitoring & Logging:** Integrate cloud provider's monitoring (e.g., CloudWatch, Google Cloud Monitoring) and logging (e.g., CloudWatch Logs, Google Cloud Logging) services, alongside application-level monitoring tools.
