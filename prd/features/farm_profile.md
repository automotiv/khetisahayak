# Feature: Farm Profiles

## 1. Introduction

The Farm Profile serves as the foundational data layer for personalizing the "Kheti Sahayak" experience. It allows farmers to input and maintain detailed information about their farm's characteristics, resources, and history. This data is crucial for features like Personalized Recommendations, targeted alerts, and relevant content delivery.

## 2. Goals

*   Enable farmers to easily create and manage a comprehensive digital profile of their farm(s).
*   Capture key data points relevant to agricultural decision-making (location, size, soil, crops, irrigation, equipment).
*   Provide a basis for personalized features within the app.
*   Ensure data accuracy through easy updates.
*   Maintain user privacy and control over their farm data.

## 3. Functional Requirements

### 3.1 Profile Creation & Management
*   **FR3.1.1 Profile Setup:** Guide users through an initial setup process to capture essential farm details upon first use or when accessing related features.
*   **FR3.1.2 Multiple Farms (Optional):** Allow users to manage profiles for multiple distinct farms or plots if applicable. [TODO: Decide on multi-farm support for v1.0.]
*   **FR3.1.3 Editing Profile:** Users must be able to easily view and edit all sections of their farm profile at any time.
*   **FR3.1.4 Data Input Fields:** The profile must allow input for the following data points (categorized for clarity):
    *   **Basic Information:**
        *   Farm Name (User-defined).
        *   Location (GPS capture + manual adjustment/entry, potentially drawing boundaries on a map).
        *   Total Farm Size (Area - e.g., acres, hectares, bigha). [TODO: Support multiple units].
    *   **Crop Details:**
        *   Current Crops (Select from predefined list, specify area planted, planting date).
        *   Crop History (Log of previously grown crops, season, yield - potentially linked to Digital Logbook).
        *   Crop Rotation practices (User input or derived from history).
    *   **Soil Information:**
        *   Soil Type (Select from predefined list - e.g., Sandy, Loamy, Clayey, Silt).
        *   Soil Test Results (Allow manual input of pH, N, P, K levels, organic matter %, date of test).
        *   [Optional] Ability to upload soil test report documents.
    *   **Water & Irrigation:**
        *   Primary Water Source (Select: Well, Borewell, Canal, River, Rain-fed, Pond, etc.).
        *   Irrigation Method(s) Used (Select: Drip, Sprinkler, Flood, Furrow, Manual, etc.).
    *   **Equipment & Infrastructure:**
        *   Equipment Owned (Select/List: Tractor, Plough, Seeder, Harvester, Sprayer, etc.).
        *   Storage Facilities (Select/Describe: Silo, Cold Storage, Warehouse, Open Storage).
    *   **Labor:**
        *   Number of Permanent Laborers.
        *   Typical Seasonal Labor requirements.
*   **FR3.1.5 Data Validation:** Implement basic validation for inputs (e.g., numeric fields, date formats).
*   **FR3.1.6 Profile Completeness Indicator:** [Optional] Show users how complete their profile is and encourage filling out more details for better recommendations.

### 3.2 Data Usage & Integration
*   **FR3.2.1 Personalization Engine:** Farm profile data must be accessible to the Personalised Recommendations engine. (See `prd/features/recommendations.md`)
*   **FR3.2.2 Feature Filtering:** Data like location and crops grown should be used to filter relevant content, schemes, and alerts.
*   **FR3.2.3 Logbook Integration:** Link profile elements (crops, fields) to Digital Logbook entries for better organization. (See `prd/features/digital_logbook.md`)

### 3.3 Data Privacy & Control
*   **FR3.3.1 User Control:** Users must have full control over editing and deleting their farm profile data.
*   **FR3.3.2 Consent Management:** Obtain explicit user consent before using profile data for specific features (e.g., personalized recommendations, sharing anonymized data).
*   **FR3.3.3 Data Sharing:** Farm profile details should not be shared publicly or with other users without explicit permission (e.g., potentially sharing basic info in the sharing platform).

## 4. User Experience (UX) Requirements

*   **UX4.1 Guided Setup:** Make the initial profile creation process easy and non-intimidating, possibly allowing users to skip sections and complete later.
*   **UX4.2 Clear Sections:** Organize profile information into logical, easy-to-navigate sections.
*   **UX4.3 Simple Inputs:** Use dropdowns, selectors, and clear labels for data entry where possible. Minimize free-text input where structured data is needed.
*   **UX4.4 Visual Aids:** Use maps for location input, potentially icons for equipment or irrigation types.
*   **UX4.5 Easy Updates:** Make it straightforward for users to update information as their farm conditions change.

## 5. Technical Requirements / Considerations

*   **TR5.1 Database Schema:** Flexible database design to accommodate various farm data points and potential future additions.
*   **TR5.2 Geolocation Handling:** Accurate capture and storage of location data. Consider using standard GeoJSON format.
*   **TR5.3 Data Relationships:** Efficiently link farm profile data with other entities like users, logbook entries, recommendations.
*   **TR5.4 Predefined Lists:** Manage predefined lists (soil types, crop types, equipment types, etc.) effectively, potentially allowing admin updates.

## 6. Security & Privacy Requirements

*   **SP6.1 Secure Storage:** Encrypt sensitive farm profile data (especially location) at rest and in transit.
*   **SP6.2 Access Control:** Ensure strict access control so only the user (and authorized system components) can access their detailed profile data.
*   **SP6.3 Anonymization:** If profile data is used for aggregated analytics, ensure it is properly anonymized.

## 7. Future Enhancements

*   **FE7.1 Map-Based Interface:** Allow users to draw farm boundaries on a map interface.
*   **FE7.2 Multi-Plot Management:** More granular management for farmers with multiple distinct plots having different characteristics.
*   **FE7.3 Integration with External Data:** Automatically populate some profile fields based on location using external datasets (e.g., typical soil type for the region - user confirms).
*   **FE7.4 Historical Snapshots:** Allow users to view how their farm profile has changed over time.

[TODO: Finalize the list of mandatory vs. optional profile fields for v1.0.]
[TODO: Define the predefined lists for selection fields (soil types, crop types, etc.).]
[TODO: Decide on multi-farm support for v1.0.]
