package com.khetisahayak.repository;

import com.khetisahayak.model.ForumReply;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ForumReplyRepository extends JpaRepository<ForumReply, Long> {

    // Find all replies for a topic
    Page<ForumReply> findByTopicIdOrderByCreatedAtAsc(Long topicId, Pageable pageable);

    // Find replies by user
    Page<ForumReply> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    // Find expert answers for a topic
    List<ForumReply> findByTopicIdAndIsExpertAnswerTrueOrderByUpvoteCountDesc(Long topicId);

    // Find accepted answer for a topic
    Optional<ForumReply> findByTopicIdAndIsAcceptedAnswerTrue(Long topicId);

    // Count replies for a topic
    long countByTopicId(Long topicId);

    // Count expert answers for a topic
    long countByTopicIdAndIsExpertAnswerTrue(Long topicId);
}

