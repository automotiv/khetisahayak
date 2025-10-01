package com.khetisahayak.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;

/**
 * Forum Reply Model for Kheti Sahayak Agricultural Platform
 * Represents replies/answers to forum topics from farmers and experts
 */
@Entity
@Table(name = "forum_replies")
public class ForumReply {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull(message = "Topic ID is required")
    @Column(name = "topic_id", nullable = false)
    private Long topicId;

    @NotNull(message = "User ID is required")
    @Column(name = "user_id", nullable = false)
    private Long userId;

    @NotBlank(message = "Content is required")
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "is_expert_answer")
    private Boolean isExpertAnswer = false;

    @Column(name = "is_accepted_answer")
    private Boolean isAcceptedAnswer = false;

    @Column(name = "upvote_count")
    private Integer upvoteCount = 0;

    @Column(name = "downvote_count")
    private Integer downvoteCount = 0;

    @Column(name = "is_edited")
    private Boolean isEdited = false;

    @Column(name = "edited_at")
    private LocalDateTime editedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Constructors
    public ForumReply() {
    }

    public ForumReply(Long topicId, Long userId, String content) {
        this.topicId = topicId;
        this.userId = userId;
        this.content = content;
    }

    // Lifecycle callbacks
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
        isEdited = true;
        editedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getTopicId() {
        return topicId;
    }

    public void setTopicId(Long topicId) {
        this.topicId = topicId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Boolean getIsExpertAnswer() {
        return isExpertAnswer;
    }

    public void setIsExpertAnswer(Boolean isExpertAnswer) {
        this.isExpertAnswer = isExpertAnswer;
    }

    public Boolean getIsAcceptedAnswer() {
        return isAcceptedAnswer;
    }

    public void setIsAcceptedAnswer(Boolean isAcceptedAnswer) {
        this.isAcceptedAnswer = isAcceptedAnswer;
    }

    public Integer getUpvoteCount() {
        return upvoteCount;
    }

    public void setUpvoteCount(Integer upvoteCount) {
        this.upvoteCount = upvoteCount;
    }

    public Integer getDownvoteCount() {
        return downvoteCount;
    }

    public void setDownvoteCount(Integer downvoteCount) {
        this.downvoteCount = downvoteCount;
    }

    public Boolean getIsEdited() {
        return isEdited;
    }

    public void setIsEdited(Boolean isEdited) {
        this.isEdited = isEdited;
    }

    public LocalDateTime getEditedAt() {
        return editedAt;
    }

    public void setEditedAt(LocalDateTime editedAt) {
        this.editedAt = editedAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    // Helper methods
    public void incrementUpvoteCount() {
        this.upvoteCount++;
    }

    public void decrementUpvoteCount() {
        if (this.upvoteCount > 0) {
            this.upvoteCount--;
        }
    }

    public void incrementDownvoteCount() {
        this.downvoteCount++;
    }

    public void decrementDownvoteCount() {
        if (this.downvoteCount > 0) {
            this.downvoteCount--;
        }
    }

    public void markAsAccepted() {
        this.isAcceptedAnswer = true;
    }

    public void unmarkAsAccepted() {
        this.isAcceptedAnswer = false;
    }
}

