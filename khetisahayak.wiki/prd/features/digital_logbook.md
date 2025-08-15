# Feature: Digital Logbook

## 1. Introduction

The Digital Logbook provides farmers with a tool to systematically record, track, and review their farm activities, inputs, expenses, and yields. It replaces traditional paper logs, offering better organization, easier data retrieval, analysis capabilities, and integration with other platform features.

## 2. Goals

*   Enable farmers to easily log various farm activities (planting, irrigation, fertilization, pest control, harvesting, etc.).
*   Facilitate tracking of inputs used (seeds, fertilizers, pesticides) and associated costs.
*   Allow recording of yield data and sales revenue.
*   Provide tools for searching, filtering, and reviewing past log entries.
*   Enable data export for offline analysis, reporting, or sharing.
*   Integrate logbook data with other features like recommendations and diagnostics.

## 3. Functional Requirements

### 3.1 Log Entry Creation
*   **FR3.1.1 Activity Logging:** Users must be able to create log entries for various farm activities.
    *   Select Activity Type (e.g., Planting, Irrigation, Fertilizing, Pest Control, Observation, Harvest, Sale). [TODO: Define standard activity types.]
    *   Associate entry with a specific Crop/Field/Plot (linked to Farm Profile).
    *   Automatic Date & Time stamping (editable).
    *   Input relevant details based on activity type (e.g., for Fertilizing: type, amount; for Pest Control: pest observed, treatment applied, amount; for Harvest: quantity harvested).
    *   Add free-text Notes/Observations.
    *   Attach relevant Photos/Videos (e.g., photo of pest damage before treatment, photo of harvest).
*   **FR3.1.2 Input Tracking:** Allow logging of inputs used, including type, quantity, and cost (e.g., kg of seeds, liters of pesticide).
*   **FR3.1.3 Expense Tracking:** Allow logging of expenses related to activities or inputs (e.g., labor cost, fuel cost, input purchase cost).
*   **FR3.1.4 Yield & Revenue Tracking:** Allow logging of harvest yield (quantity) and sales revenue (amount, buyer if applicable).
*   **FR3.1.5 Templates/Quick Entry:** [Optional] Provide templates or shortcuts for frequently logged activities to speed up entry.

### 3.2 Logbook Viewing & Management
*   **FR3.2.1 Chronological View:** Display log entries chronologically.
*   **FR3.2.2 Search Functionality:** Allow users to search log entries by keyword (in notes), activity type, crop, or date range.
*   **FR3.2.3 Filtering:** Allow users to filter entries by activity type, crop, date range, or custom tags.
*   **FR3.2.4 Editing/Deleting Entries:** Users must be able to edit or delete their log entries.
*   **FR3.2.5 Summary/Reporting:** [Optional] Provide basic summary reports based on logbook data (e.g., total expenses for a crop cycle, total yield, input usage summary). [TODO: Define scope of reporting for v1.0.]

### 3.3 Data Export
*   **FR3.3.1 Export Formats:** Users must be able to export their logbook data. Supported formats should include:
    *   CSV (for spreadsheet analysis).
    *   PDF (for printable reports).
    *   [Optional] Excel (XLSX).
*   **FR3.3.2 Export Options:** Allow users to customize exports by:
    *   Selecting a date range.
    *   Filtering by crop or activity type.
    *   Choosing specific data fields to include.
    *   Optionally including attached media (or links to media).
*   **FR3.3.3 Secure Export:** [Optional] Offer password protection for exported PDF files.

### 3.4 Reminders & Scheduling
*   **FR3.4.1 Task Reminders:** Allow users to set reminders for future tasks based on log entries or schedules (e.g., remind to irrigate in 3 days, remind for next fertilizer application based on previous log).
*   **FR3.4.2 Notification Integration:** Integrate reminders with the platform's notification system.

### 3.5 Integration with Other Features
*   **FR3.5.1 Recommendations:** Logbook data (past activities, yields, inputs used) should feed into the Personalised Recommendations engine to improve advice accuracy.
*   **FR3.5.2 Crop Diagnostics:** Allow saving diagnostic results (including images) directly to the logbook.
*   **FR3.5.3 Expert Connect:** Allow users to grant temporary, view-only access to their logbook (or specific parts) to an expert during a consultation (requires explicit user permission per session).

## 4. User Experience (UX) Requirements

*   **UX4.1 Simple Data Entry:** Make logging activities quick and intuitive, minimizing required fields for basic entries.
*   **UX4.2 Clear Overview:** Provide an easy-to-scan view of recent activities and upcoming reminders.
*   **UX4.3 Easy Retrieval:** Ensure search and filtering are fast and effective.
*   **UX4.4 Visual Aids:** Use icons for different activity types. Display attached photos as thumbnails in the log view.
*   **UX4.5 Mobile First:** Design primarily for easy use on mobile devices in field conditions. Voice-to-text input for notes is desirable.

## 5. Technical Requirements / Considerations

*   **TR5.1 Database Design:** Efficient schema to store diverse log entry types, associated metadata, and relationships (to crops, users, media).
*   **TR5.2 Performance:** Optimize database queries for fast loading, searching, and filtering, especially as logbooks grow over time.
*   **TR5.3 Data Storage:** Efficiently store attached media (photos/videos).
*   **TR5.4 Offline Capability:** Log entries should be creatable offline and synced when connectivity is restored. (See `prd/features/offline_mode.md`)

## 6. Security & Privacy Requirements

*   **SP6.1 Data Ownership:** User logbook data belongs to the user.
*   **SP6.2 Secure Storage:** Encrypt logbook data at rest and in transit.
*   **SP6.3 Access Control:** Ensure users can only access their own logbook data, unless explicitly sharing with an expert (with clear permissions).
*   **SP6.4 Data Backup:** Implement regular, secure backups of logbook data to prevent loss. Cloud syncing provides user-level backup.
*   **SP6.5 Anonymization:** If logbook data is used for aggregated analysis or AI training, ensure it is properly anonymized.

## 7. Future Enhancements

*   **FE7.1 Advanced Reporting & Analytics:** Generate more detailed reports (profitability analysis, input efficiency, yield comparisons).
*   **FE7.2 Budgeting Tools:** Integrate tools for planning farm budgets based on past expenses.
*   **FE7.3 Compliance Reporting:** Help generate reports required for organic certification or government schemes.
*   **FE7.4 IoT Integration:** Automatically log data from connected farm sensors (e.g., soil moisture sensors, weather stations).

[TODO: Define the standard list of activity types for logging.]
[TODO: Specify the exact fields required for each activity type.]
[TODO: Detail the scope and format of v1.0 summary reports.]
[TODO: Finalize the data export options and formats.]
