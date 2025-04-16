# **17 Categorisation in "Kheti Sahayak"**

### **2.17.1 Introduction**

Content Categorisation provides the structure for organizing the educational materials within "Kheti Sahayak." A logical and intuitive categorization system is essential for users to easily browse, discover, and filter content relevant to their needs.

### **2.17.2 Key Features**

### **2.17.3 Hierarchical Structure**

*   **FR2.17.3.1 Primary Categories:** Define broad, top-level categories for content (e.g., Crop Management, Soil Health, Pest & Disease Control, Water Management, Organic Farming, Machinery, Market Information, Government Schemes). [TODO: Finalize v1.0 primary categories].
*   **FR2.17.3.2 Subcategories:** Allow for multiple levels of subcategories under primary categories for finer granularity (e.g., Crop Management > Cereals > Wheat > Sowing Techniques).
*   **FR2.17.3.3 Content Assignment:** Content items (articles, videos) must be assignable to one or more relevant categories/subcategories during the upload/editing process.

### **2.17.4 Dynamic Management (Admin)**

*   **FR2.17.4.1 Admin Controls:** Provide backend tools for administrators to create, edit, delete, merge, and reorder categories and subcategories as the platform evolves.
*   **FR2.17.4.2 Content Re-assignment:** When categories are modified or merged, provide tools to efficiently re-assign existing content items.

### **2.17.5 Tagging System**

*   **FR2.17.5.1 Keyword Tags:** Complement categories with a flexible tagging system. Allow content creators to associate multiple relevant keyword tags (e.g., "irrigation", "fertilizer", "kharif", "organic pesticide") with each content item.
*   **FR2.17.5.2 Tag Management (Admin):** Provide tools for admins to manage tags (e.g., merge synonyms, remove unused tags).
*   **FR2.17.5.3 Tag-Based Discovery:** Allow users to discover content by clicking on tags or filtering search results by tags.

### **2.17.6 Visual Indicators (UX)**

*   **UX2.17.6.1 Icons/Thumbnails:** Consider using distinct icons or representative thumbnails for primary categories to enhance visual navigation.

### **2.17.7 Backend Features**

### **2.17.8 Content Mapping**

*   **TR2.17.8.1 Automatic Suggestion (Optional):** The system could potentially suggest relevant categories/tags based on content analysis (keywords in title/description) during upload, subject to creator review.
*   **TR2.17.8.2 Manual Assignment:** Ensure content creators/admins can easily select and assign categories/tags manually.

### **2.17.9 Analytics**

*   **TR2.17.9.1 Usage Data:** Track user engagement with different categories and tags (views, clicks) to understand content popularity and inform future content strategy.
*   **TR2.17.9.2 Search Analytics:** Analyze search queries related to categories/tags to identify gaps or areas for improvement in the structure.

### **2.17.10 User Experience**

### **2.17.11 Search Integration**

*   **FR2.17.11.1 Category/Tag Filters:** Search results must be filterable by category and/or tag.
*   **UX2.17.11.2 Faceted Search:** Display relevant category/tag filters alongside search results to allow users to easily refine their query.

### **2.17.12 Browsing Interface**

*   **UX2.17.12.1 Clear Navigation:** Provide an intuitive interface (e.g., dedicated section, expandable menus) for users to browse content hierarchically through categories and subcategories.
*   **UX2.17.12.2 Category Landing Pages:** Each category/subcategory page should display the content assigned to it, potentially with further filtering options.

### **2.17.13 Integration with Other Features**

### **2.17.14 Content Upload**

*   **FR2.17.14.1 Mandatory Assignment:** Make category assignment mandatory during the content upload process to ensure all content is organized. Tagging might be optional but encouraged. (See `prd/section_16_content_upload.md`)

### **2.17.15 Personalised Recommendations**

*   **TR2.17.15.1 User Preferences:** Track user interactions with categories/tags to infer interests and improve personalized content recommendations. (See `prd/features/recommendations.md`)

### **2.17.16 Challenges & Solutions** *(Considerations)*

### **2.17.17 Overlapping Content / Granularity**

*   **Process:** Allow content to belong to multiple categories/tags where appropriate. Regularly review the category structure to ensure it remains logical and not overly complex or too shallow. Use tags for cross-cutting themes.

### **2.17.18 Scalability & Maintenance**

*   **Process:** Establish clear guidelines for creating new categories/tags. Periodically review and prune the structure to maintain usability as content grows. Ensure backend tools support efficient management.
