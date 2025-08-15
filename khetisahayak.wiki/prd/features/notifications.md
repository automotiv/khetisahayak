# Feature: Notifications

## 1. Introduction

Notifications are a key mechanism for proactively communicating timely and relevant information to "Kheti Sahayak" users. They serve to alert users about important events, updates, reminders, and activities within the platform, enhancing engagement and ensuring users don't miss critical information.

## 2. Goals

*   Keep users informed about relevant updates and events in a timely manner.
*   Drive user engagement by prompting relevant actions within the app.
*   Provide customization options to avoid notification fatigue.
*   Deliver notifications reliably across different platforms (Android, iOS).
*   Ensure notifications respect user privacy and preferences.

## 3. Notification Types & Triggers

Notifications can be categorized as Push Notifications (delivered even when the app is not active) or In-App Notifications (displayed while the user is using the app).

*   **Weather Alerts:** (Push) Severe weather warnings for user's location(s). (Triggered by Weather API data). (See `prd/features/weather_forecast.md`)
*   **New Government Schemes:** (Push/In-App) Alert when a new scheme matching user profile/region is added. (Triggered by Scheme Portal updates). (See `prd/features/govt_schemes.md`)
*   **Scheme Deadlines:** (Push/In-App) Reminders for application deadlines of bookmarked schemes. (Triggered by scheduled jobs based on scheme data).
*   **Marketplace Updates:**
    *   Order Confirmations/Status Changes: (Push/In-App) Updates on purchases or sales. (Triggered by order status changes). (See `prd/features/marketplace.md`)
    *   Price Alerts (Optional): (Push) Notify if the price of a wishlisted item changes. [TODO: Decide on price alerts for v1.0.]
    *   New Message from Buyer/Seller: (Push/In-App) Alert for new messages related to an order.
*   **Equipment/Labor Sharing Updates:**
    *   Booking Requests/Confirmations: (Push/In-App) Alerts for rental/hire requests and confirmations. (Triggered by booking status changes). (See `prd/features/sharing_platform.md`)
    *   Rental/Work Reminders: (Push/In-App) Reminders for start/end dates. (Triggered by scheduled jobs).
*   **Expert Connect Updates:**
    *   New Chat Messages: (Push/In-App) Alert for new messages from experts. (Triggered by new chat messages). (See `prd/features/expert_connect.md`)
    *   Appointment Confirmations/Reminders: (Push/In-App) Alerts for scheduled consultations. (Triggered by appointment status/schedule).
    *   Upcoming Webinars: (Push/In-App) Notification about relevant upcoming webinars. (Triggered by webinar schedule).
*   **Community Forum Activity:**
    *   Reply to User's Thread/Post: (Push/In-App) Alert when someone replies. (Triggered by new replies). (See `prd/features/community_forum.md`)
    *   @Mention Notification: (Push/In-App) Alert when mentioned by another user. (Triggered by mentions).
    *   Activity in Followed Thread/Topic: (Push/In-App) Alert for new posts in subscribed threads/topics. (Triggered by new posts in subscriptions).
*   **Digital Logbook Reminders:** (Push/In-App) Reminders set by the user for farm tasks. (Triggered by user-set schedule). (See `prd/features/digital_logbook.md`)
*   **New Educational Content:** (Push/In-App) Alert when new content relevant to user's profile/interests is published. (Triggered by new content publication). (See `prd/features/educational_content.md`)
*   **Platform Announcements:** (Push/In-App) Important updates or announcements from the Kheti Sahayak team. (Triggered manually by Admins).

## 4. Functional Requirements

### 4.1 Notification Delivery
*   **FR4.1.1 Push Notifications:** Implement using platform-specific services (FCM for Android, APNS for iOS).
*   **FR4.1.2 In-App Notifications:** Display non-intrusively within the app interface (e.g., banners, badges on icons).
*   **FR4.1.3 Reliability:** Ensure reliable delivery of notifications. Implement retry mechanisms if needed.
*   **FR4.1.4 Targeting:** Deliver notifications based on user preferences, profile data (location, crops), and activity.

### 4.2 User Preferences & Control
*   **FR4.2.1 Notification Settings:** Provide a dedicated settings screen where users can enable/disable different categories of notifications (e.g., turn off forum notifications, keep weather alerts).
*   **FR4.2.2 Granularity:** Offer fine-grained control where appropriate (e.g., choose frequency for certain alerts).
*   **FR4.2.3 Opt-in/Opt-out:** Default settings should be reasonable, but users must have clear control to opt-out. System-critical notifications might be mandatory.

### 4.3 Notification Content & Actions
*   **FR4.3.1 Clear Content:** Notification text must be concise, clear, and relevant, provided in the user's preferred language.
*   **FR4.3.2 Deep Linking:** Tapping a notification should take the user directly to the relevant screen or content within the app (e.g., a weather alert opens the weather screen, a new message notification opens the chat).
*   **FR4.3.3 Actionable Notifications (Optional):** Allow users to perform quick actions directly from the notification where feasible (e.g., "Mark as Read", "Reply").

### 4.4 Backend Management
*   **FR4.4.1 Notification Service:** Backend service responsible for triggering and sending notifications based on events or schedules.
*   **FR4.4.2 User Targeting Logic:** Implement logic to target notifications effectively based on user segments and preferences.
*   **FR4.4.3 Scheduling:** Ability to schedule notifications (e.g., reminders, announcements).
*   **FR4.4.4 Analytics:** Track notification delivery rates, open rates, and engagement to optimize the strategy.

## 5. User Experience (UX) Requirements

*   **UX5.1 Relevance:** Notifications should be perceived as valuable and relevant, not spammy.
*   **UX5.2 Timeliness:** Deliver alerts and updates promptly.
*   **UX5.3 Non-Intrusiveness:** Balance informativeness with minimizing disruption to the user. Use appropriate notification channels (push vs. in-app).
*   **UX5.4 Clarity:** Easy to understand the purpose and context of each notification.
*   **UX5.5 Control:** Users should feel in control of the notifications they receive.

## 6. Technical Requirements / Considerations

*   **TR6.1 Push Notification Services:** Integrate with Firebase Cloud Messaging (FCM) and Apple Push Notification Service (APNS).
*   **TR6.2 Scalability:** The notification system must scale to handle a large user base and potentially high volume of notifications.
*   **TR6.3 Delivery Tracking:** Implement mechanisms to track successful delivery (where possible).
*   **TR6.4 Throttling/Rate Limiting:** Avoid sending too many notifications in a short period.

## 7. Security & Privacy Requirements

*   **SP7.1 Data Privacy:** Do not include sensitive personal information directly in notification payloads.
*   **SP7.2 Secure Delivery:** Ensure secure communication with push notification services.
*   **SP7.3 Preference Respect:** Strictly adhere to user's notification preferences.

## 8. Future Enhancements

*   **FE8.1 Rich Push Notifications:** Utilize images or interactive elements within push notifications.
*   **FE8.2 Geo-targeted Notifications:** Send notifications based on user's real-time location (with consent) for hyper-local alerts.
*   **FE8.3 AI-Powered Personalization:** Use ML to predict the best time and content for individual user notifications.

## 9. Notification Settings (v1.0)

To fulfill **FR4.2.1**, users will have a dedicated settings screen to manage their notification preferences. The following categories and sub-categories will be available with on/off toggles for v1.0:

*   **Weather Alerts** (Push)
*   **Government Schemes** (Push & In-App)
    *   New Schemes
    *   Application Deadlines (for bookmarked schemes)
*   **Marketplace** (Push & In-App)
    *   Order Updates
    *   New Messages
*   **Sharing Platform** (Push & In-App)
    *   Booking Updates
    *   Reminders
*   **Expert Connect** (Push & In-App)
    *   New Messages
    *   Appointment Reminders
*   **Community Forum** (Push & In-App)
    *   Replies to my posts
    *   @Mentions
*   **My Farm** (Push & In-App)
    *   Digital Logbook Reminders
*   **News & Content** (Push & In-App)
    *   New Educational Content
    *   Platform Announcements

## 10. Default Settings for New Users

To comply with **FR4.2.3**, default settings will be enabled for high-value notifications, while ensuring the user is not overwhelmed.

| Category               | Sub-Category                | Default     | Rationale                                                                    |
| ---------------------- | --------------------------- | ----------- | ---------------------------------------------------------------------------- |
| Weather Alerts         | -                           | **ON**      | Critical for farm planning and safety.                                       |
| Government Schemes     | New Schemes                 | **ON**      | High-value information for farmers.                                          |
|                        | Application Deadlines       | **ON**      | High-value reminders for schemes the user has shown interest in.             |
| Marketplace            | Order Updates               | **ON**      | Essential for transaction status.                                            |
|                        | New Messages                | **ON**      | Essential for communication between buyers/sellers.                          |
| Sharing Platform       | Booking Updates             | **ON**      | Essential for rental/hire status.                                            |
|                        | Reminders                   | **ON**      | Helpful reminders for scheduled activities.                                  |
| Expert Connect         | New Messages                | **ON**      | Essential for communication with experts.                                    |
|                        | Appointment Reminders       | **ON**      | High-value reminders.                                                        |
| Community Forum        | Replies to my posts         | **ON**      | Encourages direct engagement.                                                |
|                        | @Mentions                   | **ON**      | Direct communication, important to see.                                      |
| My Farm                | Digital Logbook Reminders   | (User-set)  | These are explicitly created by the user, so they are inherently "on".       |
| News & Content         | New Educational Content     | **ON**      | Core value proposition of the app. Can be disabled if the user finds it noisy. |
|                        | Platform Announcements      | **ON**      | Important platform-wide information that should not be missed.               |

## 11. Notification Content Templates

To fulfill **FR4.3.1** and **FR4.3.2**, notification content will be clear, concise, and link directly to the relevant in-app content.

*   **Type**: Weather Alert
    *   **Title**: ⛈️ Weather Alert
    *   **Body**: Heavy rainfall is expected in your area for the next 3 hours.
    *   **Deep Link**: Weather Forecast Screen
*   **Type**: Scheme Deadline
    *   **Title**: 🔔 Scheme Deadline Reminder
    *   **Body**: Application for PM Kisan Yojana closes in 2 days. Don't miss out!
    *   **Deep Link**: Specific Government Scheme Details Screen
*   **Type**: Marketplace Message
    *   **Title**: 💬 New Message from Ramesh
    *   **Body**: "Is the tractor available for rent next Tuesday?"
    *   **Deep Link**: Chat Screen with Ramesh
*   **Type**: Community Reply
    *   **Title**: 💬 New Reply on your post
    *   **Body**: Sunita replied to your post: "How to deal with pest attacks?"
    *   **Deep Link**: Specific Forum Thread
