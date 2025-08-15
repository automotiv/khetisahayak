# Kheti Sahayak - Technical Strategy & Roadmap

## 1. Introduction

This document outlines the technical strategy for developing the Kheti Sahayak platform. It details the architectural approach, technology choices, and implementation roadmap for each core feature area, ensuring alignment with our strategic goals of building a scalable, reliable, and farmer-centric platform.

## 2. Core Architectural Principles

- **Microservices-First:** All features will be built as independent, scalable microservices.
- **Mobile-First & Offline-Capable:** The primary user interface is the mobile app, which must function reliably in low-connectivity environments.
- **Cloud-Native:** We will leverage cloud infrastructure for scalability, reliability, and managed services (e.g., databases, object storage).
- **Open-Source Preference:** We will prioritize well-supported open-source technologies to maintain flexibility and control over our stack.
- **Data-Driven:** All features will be designed to collect data that can be used to improve our services and provide better insights to farmers.

## 3. Feature Area Strategies

### 3.1 AI Crop Health Monitoring

- **Strategic Approach:** We will build a proprietary AI/ML model in-house to ensure it is highly tuned to Indian crops and conditions. We will use a combination of open-source libraries for model development and a cloud-based platform for training and deployment. This aligns with the approach of specialized tools like Plantix but gives us full control.
- **Technology Recommendations:**
    - **ML Framework:** TensorFlow or PyTorch for model development.
    - **Image Processing:** OpenCV.
    - **Deployment:** TensorFlow Serving or a custom Python (Flask/FastAPI) service deployed on a Kubernetes cluster with GPU support.
    - **Data Annotation:** An open-source tool like LabelImg or a platform like Labelbox.
- **Integration Plan:** The `Crop Diagnostics Service` will call the deployed `AI/ML Module` via a secure internal API.

### 3.2 IoT & Remote Sensing

- **Strategic Approach:** As a future enhancement (Phase 4), we will not build our own IoT platform. We will integrate with open-source IoT platforms like **ThingsBoard** (as mentioned in the reference image) to ingest data from various sensors. This allows us to focus on the application layer rather than the complex infrastructure of IoT data ingestion.
- **Technology Recommendations:**
    - **IoT Platform:** ThingsBoard (Open Source) for device management and data collection.
    - **Protocol:** MQTT for lightweight device-to-cloud communication.
- **Integration Plan:** A new `IoT Integration Service` will be developed to connect to the ThingsBoard API, process the sensor data, and feed it into the `Recommendation Engine`.

### 3.3 Market Access & Supply Chain

- **Strategic Approach:** We will build our own marketplace to control the user experience and business logic. For market price data, we will integrate with government APIs like the **Government Mandi APIs** to provide real-time, trusted information.
- **Technology Recommendations:**
    - **Backend:** Node.js for the `Marketplace Service`.
    - **Database:** PostgreSQL for transactional data (orders, payments).
    - **Integration:** A dedicated module within the `Integration Service` to fetch and cache data from government APIs.
- **Integration Plan:** The `Marketplace Service` will handle all business logic, while the `Integration Service` will provide the external market data.

### 3.4 Offline & Mobile App Development

- **Strategic Approach:** We will continue to use **Flutter** for cross-platform mobile development. For offline support, we will implement a robust local caching and synchronization strategy using a local database. This avoids reliance on low-code/no-code platforms like Appsmith or AppsGeyser, giving us full control over the native experience.
- **Technology Recommendations:**
    - **Framework:** Flutter.
    - **Local Database:** SQLite (`sqflite` package) or a higher-level solution like Drift/Moor.
    - **State Management:** Provider or Riverpod for managing app state, including sync status.
- **Integration Plan:** The mobile app will have a dedicated `Sync Engine` module that communicates with the backend API gateway to push and pull data when connectivity is available.

### 3.5 Multilingual Voice AI

- **Strategic Approach:** As a future enhancement, we will integrate with third-party Text-to-Speech (TTS) and Speech-to-Text (STT) providers. Building our own voice models is not core to our business. We can leverage free tiers of services like **Murf AI** or **Resemble AI** for initial prototyping.
- **Technology Recommendations:**
    - **TTS/STT Provider:** Google Cloud Speech-to-Text & Text-to-Speech, or other specialized providers.
- **Integration Plan:** A new `Voice Service` microservice will be created to handle the API interactions with the external voice provider, providing a simple interface for the mobile app.

## 4. Strategic Roadmap Alignment

This technical strategy directly supports the strategic roadmap outlined in the `README.md`:

- **Phase 1 (Foundation & Launch):** Focuses on building the core in-house services for AI Diagnostics and the Marketplace, using the recommended technologies.
- **Phase 2 (Scale & Enhance):** The microservices architecture allows us to easily enhance the AI models and add new features like Expert Connect without disrupting the existing system.
- **Phase 4 (Innovation & Expansion):** The plan to integrate with external platforms like ThingsBoard for IoT and third-party APIs for Voice AI aligns perfectly with the innovation goals of this phase.

This document will serve as a living guide for our technical decisions as we move forward with the implementation.