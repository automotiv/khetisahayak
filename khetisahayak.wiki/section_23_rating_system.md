# **23 Rating System in "Kheti Sahayak's" Community Forum**

### **2.23.1 Introduction**

The rating system within the Community Forum allows users to collectively evaluate the usefulness and relevance of threads and replies. It helps surface valuable content, encourages quality contributions, and provides a quick indicator of community consensus.

### **2.23.2 Key Features**

### **2.23.3 Upvotes & Downvotes**

*   **FR2.23.3.1 Voting Mechanism:** Users must be able to cast an upvote on threads and replies they find helpful or informative.
*   **FR2.23.3.2 Downvotes (Optional):** Consider allowing users to downvote content they deem unhelpful, incorrect, or irrelevant. [TODO: Decide on downvote implementation and its impact, e.g., does it reduce visibility?].
*   **UX2.23.3.3 Clear Interface:** Provide clear, easily tappable buttons for upvoting (and downvoting, if implemented). Users should see their own vote status (e.g., highlighted button).
*   **FR2.23.3.4 Vote Toggling:** Users must be able to change or remove their vote.
*   **FR2.23.3.5 Net Score Calculation:** The system must calculate a net score for each post/thread (e.g., Upvotes - Downvotes, or just Upvotes if no downvotes).

### **2.23.4 Highlighting Top Content/Contributors**

*   **FR2.23.4.1 Thread Ranking:** Allow sorting forum threads based on their net rating score (e.g., "Top Rated", "Most Helpful").
*   **FR2.23.4.2 Comment Ranking:** Within a thread, replies can be sorted based on their rating to highlight the most helpful answers.
*   **FR2.23.4.3 Top Contributors (Optional):** Consider displaying top contributors on a leaderboard or via profile badges based on the cumulative rating of their posts/replies. (See `prd/features/community_forum.md`).

### **2.23.5 Comments Rating**

*   **FR2.23.5.1 Apply to Comments:** The rating system (upvotes/downvotes) must apply individually to each reply/comment within a thread, not just the initial thread post.

### **2.23.6 Thread Ranking (Visibility)**

*   **TR2.23.6.1 Sorting Logic:** Implement backend logic to sort threads based on calculated rating scores. Consider factors like time decay if desired (newer highly-rated posts rank higher).

### **2.23.7 User Experience**

### **2.23.8 Transparency**

*   **UX2.23.8.1 Vote Count Display:** Display the net score clearly next to each thread/reply. Consider showing separate upvote/downvote counts for more transparency.
*   **UX2.23.8.2 Non-Anonymous Voting:** Votes are typically tied to user accounts (not anonymous) to prevent manipulation, though the list of voters for a specific post is usually not displayed publicly.

### **2.23.9 Rating Limitations & Anti-Abuse**

*   **TR2.23.9.1 Vote Restrictions:** Prevent users from voting on their own posts/threads.
*   **TR2.23.9.2 Rate Limiting (Optional):** Consider implementing limits on the number of votes a user can cast within a certain timeframe to prevent spamming.
*   **TR2.23.9.3 Fraud Detection:** Implement backend checks to detect suspicious voting patterns (e.g., mass voting from new accounts, coordinated voting rings).

### **2.23.10 Feedback Loop (Optional)**

*   **UX2.23.10.1 Reason for Downvote:** If downvotes are implemented, consider an optional, anonymous mechanism for users to provide a brief reason (e.g., "Incorrect", "Unclear", "Off-topic") to provide feedback to the author and moderators.

### **2.23.11 Moderation & Quality Control Integration**

### **2.23.12 Rating Review & Action**

*   **TR2.23.12.1 Low Score Flagging:** Posts/threads falling below a certain negative rating threshold could be automatically flagged for moderator review.
*   **TR2.23.12.2 Moderator Tools:** Moderators should be able to see vote counts and potentially identify suspicious voting activity.

### **2.23.13 Content Promotion/Demotion**

*   **TR2.23.13.1 Visibility Impact:** The rating score directly influences content visibility through sorting options. Extremely low-rated content might be automatically collapsed or hidden pending review.
