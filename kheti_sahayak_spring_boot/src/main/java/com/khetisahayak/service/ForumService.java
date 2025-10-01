package com.khetisahayak.service;

import com.khetisahayak.model.ForumTopic;
import com.khetisahayak.model.ForumReply;
import com.khetisahayak.repository.ForumTopicRepository;
import com.khetisahayak.repository.ForumReplyRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Service for managing community forum discussions
 * Enables farmers to ask questions and share agricultural knowledge
 */
@Service
@Transactional
public class ForumService {

    private static final Logger logger = LoggerFactory.getLogger(ForumService.class);

    private final ForumTopicRepository topicRepository;
    private final ForumReplyRepository replyRepository;

    @Autowired
    public ForumService(ForumTopicRepository topicRepository, ForumReplyRepository replyRepository) {
        this.topicRepository = topicRepository;
        this.replyRepository = replyRepository;
    }

    // Topic operations
    public Page<ForumTopic> getAllActiveTopics(Pageable pageable) {
        logger.debug("Fetching all active forum topics");
        return topicRepository.findByStatusOrderByLastActivityAtDesc(ForumTopic.TopicStatus.ACTIVE, pageable);
    }

    public Optional<ForumTopic> getTopicById(Long id) {
        return topicRepository.findById(id);
    }

    public Optional<ForumTopic> getTopicByIdAndIncrementViews(Long id) {
        Optional<ForumTopic> topic = topicRepository.findById(id);
        topic.ifPresent(t -> {
            t.incrementViewCount();
            topicRepository.save(t);
        });
        return topic;
    }

    public Page<ForumTopic> getTopicsByCategory(String category, Pageable pageable) {
        logger.debug("Fetching topics for category: {}", category);
        return topicRepository.findByCategoryAndStatusOrderByLastActivityAtDesc(
            category, ForumTopic.TopicStatus.ACTIVE, pageable);
    }

    public List<ForumTopic> getPinnedTopics() {
        return topicRepository.findByIsPinnedTrueAndStatusOrderByCreatedAtDesc(ForumTopic.TopicStatus.ACTIVE);
    }

    public Page<ForumTopic> getUserTopics(Long userId, Pageable pageable) {
        return topicRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
    }

    public Page<ForumTopic> getTopicsWithExpertAnswers(Pageable pageable) {
        return topicRepository.findByHasExpertAnswerTrueAndStatusOrderByLastActivityAtDesc(
            ForumTopic.TopicStatus.ACTIVE, pageable);
    }

    public Page<ForumTopic> searchTopics(String query, Pageable pageable) {
        logger.debug("Searching topics with query: {}", query);
        return topicRepository.searchTopics(query, ForumTopic.TopicStatus.ACTIVE, pageable);
    }

    public Page<ForumTopic> getPopularTopics(Pageable pageable) {
        return topicRepository.findByStatusOrderByReplyCountDesc(ForumTopic.TopicStatus.ACTIVE, pageable);
    }

    public ForumTopic createTopic(ForumTopic topic) {
        logger.info("Creating new forum topic: {}", topic.getTitle());
        return topicRepository.save(topic);
    }

    public ForumTopic updateTopic(Long id, ForumTopic updatedTopic) {
        logger.info("Updating topic: {}", id);
        return topicRepository.findById(id)
            .map(existing -> {
                existing.setTitle(updatedTopic.getTitle());
                existing.setContent(updatedTopic.getContent());
                existing.setCategory(updatedTopic.getCategory());
                existing.setTags(updatedTopic.getTags());
                existing.setCropType(updatedTopic.getCropType());
                existing.setRegion(updatedTopic.getRegion());
                existing.setSeason(updatedTopic.getSeason());
                return topicRepository.save(existing);
            })
            .orElseThrow(() -> new RuntimeException("Topic not found with id: " + id));
    }

    public void deleteTopic(Long id) {
        logger.info("Deleting topic: {}", id);
        topicRepository.deleteById(id);
    }

    public ForumTopic markTopicAsResolved(Long id) {
        return topicRepository.findById(id)
            .map(topic -> {
                topic.setStatus(ForumTopic.TopicStatus.RESOLVED);
                return topicRepository.save(topic);
            })
            .orElseThrow(() -> new RuntimeException("Topic not found"));
    }

    public ForumTopic upvoteTopic(Long id) {
        return topicRepository.findById(id)
            .map(topic -> {
                topic.incrementUpvoteCount();
                return topicRepository.save(topic);
            })
            .orElseThrow(() -> new RuntimeException("Topic not found"));
    }

    // Reply operations
    public Page<ForumReply> getTopicReplies(Long topicId, Pageable pageable) {
        logger.debug("Fetching replies for topic: {}", topicId);
        return replyRepository.findByTopicIdOrderByCreatedAtAsc(topicId, pageable);
    }

    public Optional<ForumReply> getReplyById(Long id) {
        return replyRepository.findById(id);
    }

    public List<ForumReply> getExpertAnswers(Long topicId) {
        return replyRepository.findByTopicIdAndIsExpertAnswerTrueOrderByUpvoteCountDesc(topicId);
    }

    public Optional<ForumReply> getAcceptedAnswer(Long topicId) {
        return replyRepository.findByTopicIdAndIsAcceptedAnswerTrue(topicId);
    }

    public ForumReply createReply(ForumReply reply) {
        logger.info("Creating reply for topic: {}", reply.getTopicId());
        
        // Save reply
        ForumReply savedReply = replyRepository.save(reply);
        
        // Update topic reply count and last activity
        topicRepository.findById(reply.getTopicId()).ifPresent(topic -> {
            topic.incrementReplyCount();
            topic.updateLastActivity();
            
            // If it's an expert answer, mark topic as having expert answer
            if (reply.getIsExpertAnswer()) {
                topic.setHasExpertAnswer(true);
            }
            
            topicRepository.save(topic);
        });
        
        return savedReply;
    }

    public ForumReply updateReply(Long id, ForumReply updatedReply) {
        return replyRepository.findById(id)
            .map(existing -> {
                existing.setContent(updatedReply.getContent());
                return replyRepository.save(existing);
            })
            .orElseThrow(() -> new RuntimeException("Reply not found with id: " + id));
    }

    public void deleteReply(Long id) {
        ForumReply reply = replyRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Reply not found"));
        
        // Decrement topic reply count
        topicRepository.findById(reply.getTopicId()).ifPresent(topic -> {
            topic.decrementReplyCount();
            topicRepository.save(topic);
        });
        
        replyRepository.deleteById(id);
    }

    public ForumReply upvoteReply(Long id) {
        return replyRepository.findById(id)
            .map(reply -> {
                reply.incrementUpvoteCount();
                return replyRepository.save(reply);
            })
            .orElseThrow(() -> new RuntimeException("Reply not found"));
    }

    public ForumReply downvoteReply(Long id) {
        return replyRepository.findById(id)
            .map(reply -> {
                reply.incrementDownvoteCount();
                return replyRepository.save(reply);
            })
            .orElseThrow(() -> new RuntimeException("Reply not found"));
    }

    public ForumReply markAsAcceptedAnswer(Long topicId, Long replyId) {
        // First, unmark any existing accepted answer
        replyRepository.findByTopicIdAndIsAcceptedAnswerTrue(topicId)
            .ifPresent(existingAnswer -> {
                existingAnswer.unmarkAsAccepted();
                replyRepository.save(existingAnswer);
            });
        
        // Mark the new reply as accepted
        ForumReply reply = replyRepository.findById(replyId)
            .orElseThrow(() -> new RuntimeException("Reply not found"));
        
        reply.markAsAccepted();
        ForumReply savedReply = replyRepository.save(reply);
        
        // Mark topic as resolved
        topicRepository.findById(topicId).ifPresent(topic -> {
            topic.setStatus(ForumTopic.TopicStatus.RESOLVED);
            topicRepository.save(topic);
        });
        
        return savedReply;
    }

    public long getReplyCount(Long topicId) {
        return replyRepository.countByTopicId(topicId);
    }
}

