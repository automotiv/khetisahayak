# Feature: Machinery Management

## 1. Introduction

The Machinery Management feature is a specialized digital logbook designed for the automotive-focused user. It provides farmers with a dedicated module to track the health, maintenance, usage, and expenses of their valuable farm equipment, such as tractors, harvesters, and water pumps. This moves beyond a simple activity log to become a comprehensive vehicle management system.

## 2. Goals

*   Enable farmers to maintain a detailed digital record for each piece of machinery.
*   Promote preventative maintenance through scheduled service reminders.
*   Provide insights into operational costs, including fuel consumption and repairs.
*   Increase the lifespan and reliability of farm equipment.
*   Integrate seamlessly with the Marketplace for spare parts and Expert Connect for mechanical advice.

## 3. Functional Requirements

### 3.1 Vehicle/Machinery Profile
*   **FR3.1.1 Add Machinery:** Users must be able to add multiple pieces of machinery to their profile.
*   **FR3.1.2 Profile Fields:** Each machinery profile must include:
    *   Type (Tractor, Harvester, Pump, etc.)
    *   Make & Model
    *   Year of Purchase
    *   Unique Identifier (e.g., Serial Number, Registration Number)
    *   Current Usage Hours/Kilometers (editable)
    *   Photo of the machinery.
*   **FR3.1.3 Document Storage:** Allow users to upload and store digital copies of important documents for each machine (e.g., Registration Certificate, Insurance Policy, Purchase Invoice).

### 3.2 Maintenance Log
*   **FR3.2.1 Log Service/Repair:** Users must be able to log maintenance activities, including:
    *   Service Date
    *   Service Type (e.g., Oil Change, Filter Replacement, Engine Repair)
    *   Service Provider/Mechanic (can be free text or linked to a Mechanic's profile)
    *   Parts Replaced (can be linked to Marketplace items)
    *   Total Cost
    *   Notes and attached photos of receipts or work done.
*   **FR3.2.2 Service History:** Provide a chronological view of all maintenance activities for a specific machine.

### 3.3 Service Reminders
*   **FR3.3.1 Create Reminders:** Users must be able to set service reminders based on:
    *   Date (e.g., "Annual service due on Dec 1st")
    *   Usage Hours (e.g., "Service every 250 hours")
*   **FR3.3.2 Automated Reminders:** The system must send push notifications when a service reminder is due.
*   **FR3.3.3 Usage-Based Trigger:** Users must be able to update the current hours/km of a machine, which will trigger usage-based reminders.

### 3.4 Fuel Log
*   **FR3.4.1 Log Refills:** Users must be able to log fuel refills, including:
    *   Date
    *   Fuel Quantity (Liters)
    *   Total Cost
    *   Current Usage Hours/Kilometers at time of refill.
*   **FR3.4.2 Fuel Efficiency Analytics:** The system should automatically calculate and display fuel efficiency (e.g., Liters per hour) to help farmers monitor performance.

### 3.5 Integration with Other Features
*   **FR3.5.1 Marketplace:** When logging a part replacement, suggest searching for the part on the Marketplace.
*   **FR3.5.2 Expert Connect (Mechanics):** Allow users to easily share a machine's service history with a mechanic during a consultation.
*   **FR3.5.3 Sharing Platform:** A machine's public profile (for rental) should display key maintenance highlights (e.g., "Last serviced on...") to build renter trust.

## 4. User Experience (UX) Requirements

*   **UX4.1 Dedicated Dashboard:** Provide a central dashboard showing all registered machinery with key stats (e.g., next service due).
*   **UX4.2 Simple Logging:** Make the process of logging fuel or service quick and easy, with minimal fields required for a basic entry.
*   **UX4.3 Clear Visuals:** Use graphs to display fuel consumption trends and maintenance cost breakdowns.

## 5. Technical & Security Requirements

*   **TR5.1 Secure Document Storage:** All uploaded documents must be stored securely with encryption.
*   **TR5.2 Database Schema:** A robust schema to link machinery, logs, reminders, and user profiles.
*   **SP5.3 Data Privacy:** A machine's detailed service history and documents are private and should only be shared with explicit user consent.

## 6. Future Enhancements

*   **FE6.1 Spare Part Compatibility Database:** Build a database to suggest compatible spare parts based on machine make and model.
*   **FE6.2 IoT/Telematics Integration:** Allow direct integration with modern tractors that have telematics systems to automatically log usage hours and fault codes.
*   **FE6.3 Resale Value Estimation:** Provide an estimated resale value based on make, model, age, and service history.