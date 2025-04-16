# **19 Real-time Chat in "Kheti Sahayak"**

### **2.19.1 Introduction**

The Real-time Chat feature is a core component of Expert Connect, enabling direct, one-on-one, text-based communication between farmers and verified agricultural experts. It allows farmers to ask specific questions, share context (like images), and receive timely advice.

### **2.19.2 Key Features**

### **2.19.3 Instant Messaging**

*   **FR2.19.3.1 One-to-One Chat:** Facilitate private, real-time text messaging between a farmer and an expert they choose to connect with.
*   **FR2.19.3.2 Typing Indicators:** Show when the other party is typing to improve conversational flow.
*   **FR2.19.3.3 Message Status:** Display indicators for message sent, delivered, and read statuses.
*   **FR2.19.3.4 Push Notifications:** Notify users of new incoming messages when they are outside the app or chat screen (See `prd/features/notifications.md`).

### **2.19.4 Media Sharing**

*   **FR2.19.4.1 Image Sharing:** Allow users (especially farmers) to easily share images from their gallery or camera directly within the chat to provide visual context (e.g., photos of affected crops).
*   **FR2.19.4.2 Video Sharing (Optional):** Consider allowing sharing of short video clips. [TODO: Decide on video sharing scope for v1.0].
*   **FR2.19.4.3 Document Sharing (Optional):** Consider allowing sharing of relevant documents (e.g., soil test reports as PDF). [TODO: Decide on document sharing scope for v1.0].
*   **UX2.19.4.4 Media Previews:** Display thumbnails or previews of shared media within the chat interface.

### **2.19.5 End-to-End Encryption (E2EE)**

*   **SP2.19.5.1 Security:** Implement E2EE for all chat messages and media shared to ensure conversation privacy and confidentiality. Only the sender and recipient should be able to decrypt the content. [Note: This has implications for admin monitoring if required for dispute resolution].
*   **SP2.19.5.2 Verification (Optional):** Consider implementing safety number verification or similar mechanisms to allow users to verify the E2EE connection.

### **2.19.6 Chat History**

*   **FR2.19.6.1 Conversation Archiving:** Automatically save chat history for both users.
*   **FR2.19.6.2 History Access:** Allow users to easily access and scroll through their past conversations with specific experts.
*   **FR2.19.6.3 Search within Chat:** Provide functionality to search for keywords within a specific chat conversation history.
*   **FR2.19.6.4 Deletion (Optional):** Define policy on message deletion (e.g., delete for self, delete for everyone within a time limit). [TODO: Define deletion policy].

### **2.19.7 User Experience**

### **2.19.8 Intuitive Design**

*   **UX2.19.8.1 Familiar Interface:** Adopt a standard, familiar chat interface layout (message bubbles, timestamps, input field).
*   **UX2.19.8.2 Online Status:** Display the online/offline/away status of the expert, if feasible and agreed upon by experts.
*   **UX2.19.8.3 Easy Initiation:** Simple process to initiate a chat from an expert's profile.

### **2.19.9 Offline Mode Considerations**

*   **FR2.19.9.1 Message Queueing:** Messages sent while offline must be queued and sent automatically when connectivity is restored.
*   **FR2.19.9.2 Offline Access:** Users should be able to view their existing chat history while offline. (See `prd/features/offline_mode.md`)

### **2.19.10 Integration with Other Features**

### **2.19.11 Expert Profiles**

*   **FR2.19.11.1 Initiate Chat:** Chat functionality must be accessible directly from expert profiles. (See `prd/features/expert_connect.md`)

### **2.19.12 AI-Powered Assistance (Future Enhancement)**

*   **FE2.19.12.1 Chatbots:** Integrate chatbots for initial query handling or suggesting relevant FAQs before connecting to a human expert.
*   **FE2.19.12.2 Contextual Suggestions:** AI could potentially suggest relevant articles or diagnostic tools to the farmer or provide context to the expert based on the conversation (with privacy considerations).

### **2.19.13 Challenges & Solutions** *(Considerations)*

### **2.19.14 Connectivity Issues**

*   **TR2.19.14.1 Robust Delivery:** Implement reliable message queueing and delivery mechanisms to handle intermittent connectivity. Optimize data usage for chat.

### **2.19.15 Language Diversity**

*   **TR2.19.15.1 Translation Tools (Optional):** Consider integrating real-time machine translation features within the chat if experts and farmers speak different languages. Display translations with disclaimers about accuracy. (See `prd/features/multilingual.md`)

### **2.19.16 Technical Considerations**
*   **TR2.19.16.1 Technology Stack:** Choose appropriate real-time communication technologies (e.g., WebSockets, MQTT, Firebase Realtime Database/Firestore).
*   **TR2.19.16.2 Scalability:** Ensure the chat infrastructure can handle a large number of concurrent connections and messages.
*   **TR2.19.16.3 E2EE Implementation:** Select and implement a robust E2EE protocol (e.g., Signal Protocol).
