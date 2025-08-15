# **22 Thread Creation in "Kheti Sahayak's" Community Forum**

### **2.22.1 Introduction**

Thread creation is the primary mechanism for users to initiate discussions, ask questions, or share information within the "Kheti Sahayak" Community Forum. A clear and functional thread creation process encourages participation and ensures discussions are well-organized.

### **2.22.2 Key Features**

### **2.22.3 Topic/Category Selection**

*   **FR2.22.3.1 Mandatory Selection:** Users must select an appropriate forum category/topic before creating a new thread. This ensures proper organization.
*   **UX2.22.3.2 Clear Choices:** Present categories in a clear, understandable list or dropdown menu.

### **2.22.4 User-friendly Editor**

*   **FR2.22.4.1 Title Input:** Require a clear, concise title for the thread.
*   **FR2.22.4.2 Body Input:** Provide a main text area for the user to elaborate on their question or discussion point.
*   **FR2.22.4.3 Rich Text Formatting:** Offer basic formatting options (bold, italics, bullet points, numbered lists, hyperlinks) to improve readability.
*   **FR2.22.4.4 Media Attachments:** Allow users to attach relevant media (images, potentially short videos) to provide context. Implement size and type restrictions.

### **2.22.5 Preview & Editing**

*   **FR2.22.5.1 Draft Saving (Optional):** Consider allowing users to save drafts of their threads.
*   **UX2.22.5.2 Preview Option:** Allow users to preview how their thread will look before publishing.
*   **FR2.22.5.3 Post-Publication Editing:** Allow the original poster to edit their thread (primarily the body content, perhaps not the title after replies exist) within a limited time window (e.g., 15-30 minutes) to correct typos or minor errors.

### **2.22.6 Visibility Options (Optional)**

*   **FR2.22.6.1 Public Default:** By default, threads should be public and visible to all forum users.
*   **FR2.22.6.2 Private Threads (Future):** Consider future support for private/group-specific threads if sub-communities are implemented.

### **2.22.7 User Experience**

### **2.22.8 Thread Templates (Optional)**

*   **UX2.22.8.1 Guided Input:** For common query types (e.g., "Ask a Question", "Share Experience"), consider providing simple templates or prompts to guide users in providing necessary information (e.g., "What crop are you asking about?", "What symptoms have you observed?").

### **2.22.9 Thread Analytics (for Creator)**

*   **UX2.22.9.1 Engagement Metrics:** Display basic metrics like view count and reply count on the user's own threads.

### **2.22.10 Notifications Integration**

*   **FR2.22.10.1 Activity Alerts:** Integrate with the notification system to alert the thread creator about new replies or ratings on their thread. (See `prd/features/notifications.md`).

### **2.22.11 Moderation & Quality Control Integration**

### **2.22.12 Auto-moderation Checks**

*   **TR2.22.12.1 Spam/Keyword Check:** Run submitted thread content through basic spam filters or keyword checks before publication or flagging for review.

### **2.22.13 Flagging & Reporting Link**

*   **UX2.22.13.1 Visibility:** Ensure the option to flag/report a thread is accessible (though this relates more to viewing threads than creation).

### **2.22.14 Technical Considerations**
*   **TR2.22.14.1 Editor Component:** Select or build a reliable rich text editor component suitable for mobile and potentially web use.
*   **TR2.22.14.2 Media Handling:** Robust backend process for handling media uploads associated with threads (storage, optimization).
