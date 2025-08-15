# **13 Listing & Rental Agreements in "Kheti Sahayak"**

### **2.13.1 Introduction**

Listing & Rental Agreements are crucial for establishing clear terms, responsibilities, and trust between equipment owners (listers) and renters within the "Kheti Sahayak" sharing platform. These agreements aim to minimize disputes by outlining the conditions of the rental transaction. While potentially legally binding (subject to local laws and platform terms), their primary goal is to set clear expectations.

### **2.13.2 Key Components of an Equipment Rental Agreement**

### **2.13.3 Equipment Details**

*   **FR2.13.3.1 Identification:** The agreement must clearly identify the rented equipment, matching the listing details (Type, Brand, Model, unique identifier if available).
*   **FR2.13.3.2 Condition:** The agreement must state the equipment's agreed-upon condition at the start of the rental (e.g., referencing pre-rental checks or photos).

### **2.13.4 Rental Duration**

*   **FR2.13.4.1 Start Date & Time:** The agreement must specify the exact start date and time of the rental period.
*   **FR2.13.4.2 End Date & Time:** The agreement must specify the exact end date and time when the equipment is due for return.
*   **FR2.13.4.3 Location:** The agreement must specify the agreed pick-up and return location(s).

### **2.13.5 Pricing and Payment Terms**

*   **FR2.13.5.1 Rental Rate:** The agreement must state the agreed rental price (per hour/day or total).
*   **FR2.13.5.2 Security Deposit:** The agreement must specify the security deposit amount and the conditions for its refund or forfeiture.
*   **FR2.13.5.3 Payment Schedule:** The agreement must outline when payments (rental fee, deposit) are due.
*   **FR2.13.5.4 Additional Charges:** The agreement must list any potential additional charges (e.g., late fees, fuel, cleaning).

### **2.13.6 Maintenance and Usage**

*   **FR2.13.6.1 Permitted Use:** The agreement must define the intended and permitted use of the equipment.
*   **FR2.13.6.2 Renter's Responsibilities:** The agreement must outline the renter's responsibilities regarding basic care and immediate reporting of issues.
*   **FR2.13.6.3 Owner's Responsibilities:** The agreement must outline the owner's responsibility to provide equipment in the agreed condition.
*   **FR2.13.6.4 Breakdown Procedure:** The agreement must specify the procedure in case of equipment malfunction during the rental period.

### **2.13.7 Termination Clauses**

*   **FR2.13.7.1 Cancellation Policy:** The agreement must detail the conditions and consequences (fees, refunds) for cancellation by either party before the rental starts.
*   **FR2.13.7.2 Early Termination:** The agreement must outline conditions for ending the rental early and the associated financial implications.

### **2.13.8 Dispute Resolution**

*   **FR2.13.8.1 Process:** The agreement must reference the platform's defined dispute resolution process (e.g., mediation).
*   **FR2.13.8.2 Liability:** The agreement should clarify liability for damages based on cause (e.g., misuse vs. normal wear).

### **2.13.9 User Experience (Agreement Generation & Signing)**

### **2.13.10 Digital Agreements**

*   **FR2.13.10.1 Template Generation:** The system must automatically generate a standardized agreement based on the confirmed booking details.
*   **UX2.13.10.2 Review:** Both parties must be able to easily review the generated agreement before acceptance.
*   **FR2.13.10.3 Acceptance/E-signature:** Implement a clear digital acceptance mechanism (e.g., checkbox, button click confirming "I Agree", or simple e-signature) for both parties. [TODO: Confirm legal validity requirements].

### **2.13.11 Transparency and Clarity**

*   **UX2.13.11.1 Simple Language:** Agreements should use clear, simple language, minimizing legal jargon. Consider providing summaries or explanations in local languages.
*   **UX2.13.11.2 Key Terms Highlight:** Key financial terms, dates, and responsibilities should be highlighted or summarized for easy understanding.
*   **UX2.13.11.3 Accessibility:** Agreements must be easily accessible for review within the app at any time during the rental process.

### **2.13.12 Backend Integration & Document Management** 
*(Cross-reference with FR4.1.5 in `prd/features/sharing_platform.md`)*

*   **TR2.13.12.1 Secure Storage:** Finalized agreements must be stored securely and tamper-proof, linked to the booking record.
*   **TR2.13.12.2 Easy Retrieval:** Users must be able to easily view and download their agreements (e.g., as PDF).
*   **TR2.13.12.3 Version Control:** If amendments are permitted (requiring re-acceptance by both parties), the system must track agreement versions.

### **2.13.13 Challenges & Solutions** 
*(Considerations)*

*   **Enforcement:** Define clear platform policies regarding consequences for agreement breaches (linked to ratings, deposits, potential suspension).
*   **Understanding:** Utilize multilingual support and potentially visual aids or summaries to ensure users understand the terms they are agreeing to.
