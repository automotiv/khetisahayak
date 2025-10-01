package com.khetisahayak.repository;

import com.khetisahayak.model.ForumTopic;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ForumTopicRepository extends JpaRepository<ForumTopic, Long> {

    // Find all active topics
    Page<ForumTopic> findByStatusOrderByLastActivityAtDesc(ForumTopic.TopicStatus status, Pageable pageable);

    // Find topics by category
    Page<ForumTopic> findByCategoryAndStatusOrderByLastActivityAtDesc(
        String category, ForumTopic.TopicStatus status, Pageable pageable);

    // Find pinned topics
    List<ForumTopic> findByIsPinnedTrueAndStatusOrderByCreatedAtDesc(ForumTopic.TopicStatus status);

    // Find topics by user
    Page<ForumTopic> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    // Find topics with expert answers
    Page<ForumTopic> findByHasExpertAnswerTrueAndStatusOrderByLastActivityAtDesc(
        ForumTopic.TopicStatus status, Pageable pageable);

    // Find topics by crop type
    Page<ForumTopic> findByCropTypeAndStatusOrderByLastActivityAtDesc(
        String cropType, ForumTopic.TopicStatus status, Pageable pageable);

    // Search topics
    @Query("SELECT t FROM ForumTopic t WHERE t.status = :status AND " +
           "(LOWER(t.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(t.content) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<ForumTopic> searchTopics(@Param("query") String query, 
                                   @Param("status") ForumTopic.TopicStatus status, 
                                   Pageable pageable);

    // Find popular topics (most replies)
    Page<ForumTopic> findByStatusOrderByReplyCountDesc(ForumTopic.TopicStatus status, Pageable pageable);

    // Find trending topics (most views)
    Page<ForumTopic> findByStatusOrderByViewCountDesc(ForumTopic.TopicStatus status, Pageable pageable);

    // Count topics by category
    long countByCategoryAndStatus(String category, ForumTopic.TopicStatus status);
}

