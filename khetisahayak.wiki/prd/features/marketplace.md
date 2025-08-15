# Feature: Marketplace

## 1. Introduction

The Marketplace feature provides a digital platform within "Kheti Sahayak" for farmers, vendors, and potentially other users to buy and sell agricultural products, inputs (seeds, fertilizers, pesticides), tools, and related services. It aims to create a transparent, efficient, and accessible market, reducing reliance on traditional intermediaries and empowering users with more choices and better pricing.

### 1.1 Indian Context & Challenges

- Many rural farmers face limited access to quality agri-inputs and fair markets for their produce.
- Trust, digital literacy, and language barriers are significant. The platform must be accessible, transparent, and offer support for low-literacy users (icons, local language, voice prompts).
- Reliable logistics and payment options (including COD) are essential for rural adoption.

### 1.2 User Stories

- As a farmer, I want to easily browse and buy seeds, fertilizers, and tools in my local language, with clear pricing and delivery info.
- As a vendor, I want to reach farmers across regions, list my products, and manage orders from my phone.
- As a farmer-seller, I want to list my fresh produce for local buyers, with a simple process and trust signals.
- As a buyer with low literacy, I want to use voice search and icon-based navigation.
- As a user with poor connectivity, I want my order to be saved and processed when I reconnect.
- As an admin, I want to review vendor documents, resolve disputes, and monitor suspicious activity.
- As a user, I want to report a product or vendor if I suspect fraud or misrepresentation.

## 2. Goals

- Enable farmers to sell their produce directly or buy necessary inputs conveniently.
- Provide vendors with a platform to reach a large, targeted audience of farmers.
- Facilitate transparent pricing and secure transactions.
- Offer efficient search and discovery of products and services.
- Build trust through user ratings, reviews, and vendor verification.
- Integrate logistics support for efficient delivery (optional for v1.0, TBD).

## 3. User Roles in Marketplace

- **Buyers:** For v1.0, primarily **Farmers** purchasing inputs/equipment. Consider enabling **Local Consumers/Small Businesses** to buy produce if farmer selling is implemented. [TODO: Finalize buyer scope for v1.0, Wholesalers likely future scope].
- **Sellers:** Can be **Verified Vendors** (businesses selling inputs/equipment/services) or **Farmers** (selling their own produce, if enabled in v1.0).
- **Platform Administrators:** Oversee marketplace operations, vendor verification, content moderation, dispute resolution, etc.

## 4. Functional Requirements

### 4.1 Vendor/Seller Management

- **FR4.1.1 Vendor Registration & Verification:**
  - Vendors must register via the app/portal, providing business name, contact details (mobile number required, email optional), address, and relevant business documents.
  - **Verification Process:**
    - Mobile number verification via OTP.
    - Document submission (e.g., Business Registration proof, GSTIN if applicable, ID proof of owner, Address proof).
    - Admin review and approval of submitted documents. Use a checklist and fraud-detection heuristics (e.g., duplicate docs, mismatched names).
  - Verified vendors must receive a "Verified" badge displayed on their profile and listings.
  - [Edge case] If documents are rejected, notify vendor with reason and allow resubmission.

- **FR4.1.2 Vendor Profiles:**
  - Vendors must have a dedicated profile page displaying: Business Name, Verification Status, Average Rating, Link to all listings, Business Description, Contact Information (masked partially if needed), Return Policy summary, Location.

- **FR4.1.3 Seller Dashboard:**
  - Provide sellers (Vendors and potentially Farmers) with a dashboard to: Manage product listings (add/edit/pause/delete), View/manage orders (accept/reject, update status), Track inventory levels, View sales analytics (e.g., total sales, popular items), Manage customer communications/queries related to orders.

- **FR4.1.4 Farmer as Seller:** [If enabled in v1.0]
  - Allow registered farmers to list specific categories of products (e.g., Fresh Produce from their farm).
  - Implement a simplified listing process, potentially linked to their Farm Profile. Use local language and icons for guidance.
  - Verification might rely initially on community ratings/reporting or a simpler document check (e.g., ID proof). Clearly differentiate farmer sellers from verified vendors.

### 4.2 Product Listing & Cataloguing

- **FR4.2.1 Create Listing:** Sellers must be able to create detailed product listings including:
  - Clear Title & Description (specifications, usage, benefits). Support local language input and voice-to-text.
  - High-Quality Images (multiple angles, zoom). Video support is desirable.
  - Accurate Category & Subcategory selection (see v1.0 categories below).
  - Pricing (per unit, potential bulk discounts).
  - Stock Availability / Inventory level.
  - Origin (for produce).
  - Certifications (e.g., organic).
  - Shipping options and costs (if applicable).

- **FR4.2.2 Manage Listings:** Sellers must be able to edit, pause, or delete their listings.

- **FR4.2.3 Product Categories:** Implement a clear hierarchical categorization for all products and services.
  - **v1.0 Categories:**
    - Seeds: Vegetable, Grain, Flower
    - Fertilizers: Organic, Chemical
    - Pesticides: Insecticides, Herbicides
    - Tools: Hand Tools, Small Machinery
    - Fresh Produce: Vegetables, Fruits (if farmer selling enabled)
    - Services: Soil Testing, Equipment Rental

### 4.3 Search & Discovery

- **FR4.3.1 Search:** Full-text, voice, and icon-based search options.
- **FR4.3.2 Filters & Sorting:** Category, price, rating, location, and availability.
- **FR4.3.3 Recommendations:** Suggest products based on user profile, purchase history, and diagnostics.

### 4.4 Ordering & Transaction

- **FR4.4.1 Cart & Checkout:** Simple, step-by-step checkout. Save cart for offline users, process when online.
- **FR4.4.2 Payment Options:** Support UPI, cards, wallets, and Cash on Delivery (COD). Clearly indicate COD availability and fees.
- **FR4.4.3 Order Confirmation:** Show order ID, summary, and send notifications (in-app, SMS/email) to buyer and seller.
- **FR4.4.4 Refunds & Returns:** Allow buyers to initiate returns and refunds within a defined window. Clearly communicate policies.
- **FR4.4.5 Fraud Prevention:**
  - Automated checks for fake listings, suspicious pricing, and vendor behavior.
  - User reporting and admin review workflows.

### 4.5 Ratings, Reviews & Moderation

- **FR4.5.1 Buyer Reviews:** Buyers can rate and review products and vendors after delivery.
- **FR4.5.2 Seller Response:** Sellers can post one public response to each review.
- **FR4.5.3 Moderation:**
  - User reporting/flagging of suspicious or inappropriate reviews.
  - Automated spam/profanity checks.
  - Admin review and removal as needed.

### 4.6 Communication

- **FR4.6.1 In-App Messaging:** Secure, order-linked messaging channel for buyers and sellers. Mask personal contact info.

### 4.7 Logistics & Shipping (v1.0 Scope: Seller Responsibility)

- **FR4.7.1 Seller-Managed Delivery:** Sellers specify delivery areas and timelines. Platform provides guidance/templates.
- **FR4.7.2 Logistics Integration (Future):** Plan for API integration with logistics partners.

### 4.8 Dispute Resolution

- **FR4.8.1 Reporting Issues:** "Report Issue" button in order details for both parties. Structured reason selection and evidence upload.
- **FR4.8.2 Mediation Workflow:**
  1. Issue reported -> Notify both parties.
  2. Mandatory communication window (48-72 hours).
  3. Escalation to admin if unresolved.
  4. Admin reviews case and evidence; makes binding decision.
  5. Communicate outcome and next steps.

## 5. User Experience (UX) Requirements

- **UX5.1 Intuitive Navigation:** Easy browsing, clear categories, prominent search, and filter options.
- **UX5.2 Accessibility:** Support for local languages, voice prompts, large buttons, and icon-based flows for low-literacy users.
- **UX5.3 Product Presentation:** High-quality images, structured info, and trust badges.
- **UX5.4 Seamless Checkout:** Minimize steps, save cart offline, clear payment options.
- **UX5.5 Trust Signals:** Display vendor verification, ratings, reviews, and return policies.
- **UX5.6 Mobile Optimization:** Ensure smooth experience on low-end Android devices and slow networks.

## 6. Technical Requirements / Considerations

- **TR6.1 Scalability:** Handle large user, listing, and transaction volumes. Use cloud-native architecture.
- **TR6.2 Database Design:** Efficient schema for users, products, orders, reviews, and disputes.
- **TR6.3 Performance:** Fast search, listing load, and checkout even on low bandwidth.
- **TR6.4 Payment Security:** PCI-DSS compliance or use of certified third-party gateways.
- **TR6.5 Inventory Sync:** Real-time or near-real-time updates to prevent overselling.
- **TR6.6 Localization:** All UI and help content in supported local languages.

## 7. Security & Privacy Requirements

- **SP7.1 Secure Transactions:** Encrypt all financial transactions and sensitive user data.
- **SP7.2 Data Protection:** Comply with Indian IT Act and GDPR for personal and transaction data.
- **SP7.3 Fraud Prevention:** Automated and manual checks for fake listings, suspicious activity, and account takeovers.

## 8. KPIs & Impact Metrics

- Order completion rate
- Repeat purchase rate
- Average delivery time
- Vendor onboarding and verification rate
- User satisfaction (NPS, survey)
- Incidence of fraud/disputes per 1000 orders

## 9. Rollout & Pilot Plan

- Launch pilot in select districts with a mix of vendors and farmers
- Onboard trusted vendors first, then expand to farmer-sellers
- Collect feedback on usability, trust, and logistics
- Iterate on features and policies based on pilot data

## 10. Future Enhancements

- **FE10.1 Advanced Analytics for Sellers:** Deeper sales and customer insights.
- **FE10.2 Logistics Integration:** API-based shipping and tracking.
- **FE10.3 Auctions/Bidding:** Enable for select categories.
- **FE10.4 Bulk Ordering:** Features for wholesale buyers.
- **FE10.5 AI Recommendations:** Suggest products based on user profile, diagnostics, and season.

## 11. Open Questions / TODOs

- **Product Categories for v1.0:** (see above for recommended list)
- **Vendor Commission Structure:** Recommend starting with a small percentage per transaction; evaluate fixed fees/subscription as scale grows.
- **Logistics:** v1.0 is seller-managed; plan for platform integration in future.

git remote set-url origin https://github.com/automotiv/khetisahayak.git
