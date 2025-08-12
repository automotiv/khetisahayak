# **26 Regular Entries in the Digital Logbook of "Kheti Sahayak"**

### **2.26.1 Introduction**

Regular Entries are the fundamental building blocks of the Digital Logbook. This section details the components and user experience required for farmers to easily and consistently document their daily farm activities, observations, and associated data.

### **2.26.2 Purpose of Regular Entries**

*   **FR2.26.2.1 Documentation:** To provide a structured way for farmers to record day-to-day farm tasks and events.
*   **FR2.26.2.2 History & Analysis:** To build a historical record for tracking progress, comparing seasons, analyzing input effectiveness, and informing future decisions.
*   **FR2.26.2.3 Monitoring:** To aid in monitoring crop health, resource usage, expenses, and yields over time.

### **2.26.3 Components of a Regular Entry**

*   **FR2.26.3.1 Mandatory Fields:** Each log entry must capture essential information.
*   **FR2.26.3.2 Optional Fields:** Allow for additional details for more comprehensive record-keeping.

### **2.26.4 Date & Time**

*   **FR2.26.4.1 Automatic Timestamp:** The system must automatically record the date and time when an entry is created.
*   **FR2.26.4.2 Manual Override:** Users must be able to edit the date and time if logging an activity retrospectively.
*   **UX2.26.4.3 Clear Display:** Display the date and time clearly for each entry in the logbook view.

### **2.26.5 Activity Type**

*   **FR2.26.5.1 Predefined List:** Users must select the primary activity type from a predefined, categorized list (e.g., Soil Preparation, Planting/Sowing, Irrigation, Fertilization, Pest/Disease Scouting, Pest Control Application, Weed Control, Pruning, Harvesting, Sales, Observation, Other). [TODO: Finalize standard activity list for v1.0].
*   **UX2.26.5.2 Easy Selection:** Use an intuitive dropdown or selection interface. Consider icons for common activities.

### **2.26.6 Crop/Field Association**

*   **FR2.26.6.1 Linkage:** Users must be able to associate the log entry with a specific crop, field, or plot defined in their Farm Profile. This is crucial for filtering and analysis.
*   **UX2.26.6.2 Simple Selection:** Provide an easy way to select the relevant crop/field from the user's profile.

### **2.26.7 Quantity & Measurements (Context-Dependent)**

*   **FR2.26.7.1 Input Fields:** Provide relevant fields based on the selected Activity Type. Examples:
    *   *Planting:* Seed variety, quantity (e.g., kg), planting density.
    *   *Irrigation:* Duration (hours/minutes) or Volume (liters/gallons).
    *   *Fertilization:* Fertilizer type/brand, application method, quantity (e.g., kg/acre).
    *   *Pest Control:* Pest/Disease observed, treatment product, application method, quantity/concentration.
    *   *Harvest:* Quantity harvested (e.g., kg, quintals, tonnes), quality grade (optional).
    *   *Sales:* Quantity sold, price per unit, total revenue, buyer (optional).
*   **FR2.26.7.2 Unit Support:** Support common agricultural units and allow users to potentially set defaults.

### **2.26.8 Notes / Observations**

*   **FR2.26.8.1 Free Text Field:** Provide a text area for users to add qualitative observations, weather notes, reminders, or any other relevant details not captured in structured fields.
*   **UX2.26.8.2 Ease of Input:** Support multi-line input.

### **2.26.9 Attachments**

*   **FR2.26.9.1 Media Upload:** Allow users to attach one or more photos or short videos to a log entry (e.g., photos of crop stage, pest damage, soil condition, harvest quality). Use device camera or gallery.
*   **UX2.26.9.2 Previews:** Show thumbnails of attached media within the log entry view.

### **2.26.10 User Experience Enhancements**

### **2.26.11 Templates (Optional)**

*   **UX2.26.11.1 Quick Entry:** Consider allowing users to create templates for recurring activities (e.g., "Daily Irrigation - Plot A") to pre-fill common fields.

### **2.26.12 Predictive Text / Suggestions (Optional)**

*   **UX2.26.12.1 Faster Input:** Suggest previously used input names (e.g., fertilizer brands, pest names) as the user types in relevant fields.

### **2.26.13 Voice-to-Text Input**

*   **UX2.26.13.1 Accessibility:** Integrate device voice-to-text capabilities for the Notes field to facilitate hands-free or faster input, especially in field conditions.

### **2.26.14 Technical Considerations**
*   **TR2.26.14.1 Database Schema:** Design flexible schema to handle varying fields based on activity type.
*   **TR2.26.14.2 Offline Storage:** Ensure entries created offline are stored reliably on the device before syncing.
