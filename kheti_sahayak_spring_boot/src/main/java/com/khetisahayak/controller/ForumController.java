package com.khetisahayak.controller;

import com.khetisahayak.model.ForumTopic;
import com.khetisahayak.model.ForumReply;
import com.khetisahayak.service.ForumService;
import com.khetisahayak.service.JwtService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Forum Controller for Kheti Sahayak Agricultural Platform
 * Handles farmer community discussions, Q&A, and knowledge sharing
 */
@Tag(name = "Community Forum", description = "Agricultural community forum APIs for farmer discussions")
@RestController
@RequestMapping("/api/community")
@CrossOrigin(origins = "*")
public class ForumController {

    private final ForumService forumService;
    private final JwtService jwtService;

    @Autowired
    public ForumController(ForumService forumService, JwtService jwtService) {
        this.forumService = forumService;
        this.jwtService = jwtService;
    }

    private Long getAuthenticatedUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            return Long.parseLong(authentication.getName());
        }
        throw new RuntimeException("User not authenticated");
    }

    // Topic endpoints
    
    @Operation(summary = "Get all forum topics", description = "Retrieve all active forum topics with pagination")
    @GetMapping("/topics")
    public ResponseEntity<Map<String, Object>> getAllTopics(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ForumTopic> topicsPage = forumService.getAllActiveTopics(pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", topicsPage.getContent());
            response.put("currentPage", topicsPage.getNumber());
            response.put("totalItems", topicsPage.getTotalElements());
            response.put("totalPages", topicsPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch topics");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get topic by ID", description = "Retrieve specific topic and increment view count")
    @GetMapping("/topics/{id}")
    public ResponseEntity<Map<String, Object>> getTopicById(@PathVariable Long id) {
        return forumService.getTopicByIdAndIncrementViews(id)
            .map(topic -> {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("data", topic);
                return ResponseEntity.ok(response);
            })
            .orElseGet(() -> {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Topic not found");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            });
    }

    @Operation(summary = "Get pinned topics", description = "Retrieve pinned/featured topics")
    @GetMapping("/topics/pinned")
    public ResponseEntity<Map<String, Object>> getPinnedTopics() {
        try {
            List<ForumTopic> pinnedTopics = forumService.getPinnedTopics();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", pinnedTopics);
            response.put("count", pinnedTopics.size());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch pinned topics");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get topics by category", description = "Filter topics by agricultural category")
    @GetMapping("/topics/category/{category}")
    public ResponseEntity<Map<String, Object>> getTopicsByCategory(
            @PathVariable String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ForumTopic> topicsPage = forumService.getTopicsByCategory(category, pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", topicsPage.getContent());
            response.put("currentPage", topicsPage.getNumber());
            response.put("totalItems", topicsPage.getTotalElements());
            response.put("totalPages", topicsPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch topics by category");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Search topics", description = "Search forum topics by keywords")
    @GetMapping("/topics/search")
    public ResponseEntity<Map<String, Object>> searchTopics(
            @RequestParam String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ForumTopic> topicsPage = forumService.searchTopics(q, pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", topicsPage.getContent());
            response.put("query", q);
            response.put("currentPage", topicsPage.getNumber());
            response.put("totalItems", topicsPage.getTotalElements());
            response.put("totalPages", topicsPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Search failed");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get popular topics", description = "Get topics with most replies")
    @GetMapping("/topics/popular")
    public ResponseEntity<Map<String, Object>> getPopularTopics(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ForumTopic> topicsPage = forumService.getPopularTopics(pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", topicsPage.getContent());
            response.put("currentPage", topicsPage.getNumber());
            response.put("totalItems", topicsPage.getTotalElements());
            response.put("totalPages", topicsPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch popular topics");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Get topics with expert answers", description = "Get topics answered by agricultural experts")
    @GetMapping("/topics/expert-answers")
    public ResponseEntity<Map<String, Object>> getTopicsWithExpertAnswers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ForumTopic> topicsPage = forumService.getTopicsWithExpertAnswers(pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", topicsPage.getContent());
            response.put("currentPage", topicsPage.getNumber());
            response.put("totalItems", topicsPage.getTotalElements());
            response.put("totalPages", topicsPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch topics with expert answers");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Create new topic", description = "Create a new forum discussion topic")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/topics")
    public ResponseEntity<Map<String, Object>> createTopic(@Valid @RequestBody ForumTopic topic) {
        try {
            Long userId = getAuthenticatedUserId();
            topic.setUserId(userId);
            
            ForumTopic createdTopic = forumService.createTopic(topic);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Topic created successfully");
            response.put("data", createdTopic);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to create topic");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Update topic", description = "Update an existing forum topic")
    @PreAuthorize("hasRole('FARMER')")
    @PutMapping("/topics/{id}")
    public ResponseEntity<Map<String, Object>> updateTopic(
            @PathVariable Long id,
            @Valid @RequestBody ForumTopic topic) {
        
        try {
            Long userId = getAuthenticatedUserId();
            
            // Verify ownership
            ForumTopic existingTopic = forumService.getTopicById(id)
                .orElseThrow(() -> new RuntimeException("Topic not found"));
            
            if (!existingTopic.getUserId().equals(userId)) {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Not authorized to update this topic");
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
            }
            
            ForumTopic updatedTopic = forumService.updateTopic(id, topic);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Topic updated successfully");
            response.put("data", updatedTopic);
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }
    }

    @Operation(summary = "Delete topic", description = "Delete a forum topic")
    @PreAuthorize("hasRole('FARMER')")
    @DeleteMapping("/topics/{id}")
    public ResponseEntity<Map<String, Object>> deleteTopic(@PathVariable Long id) {
        try {
            Long userId = getAuthenticatedUserId();
            
            // Verify ownership
            ForumTopic topic = forumService.getTopicById(id)
                .orElseThrow(() -> new RuntimeException("Topic not found"));
            
            if (!topic.getUserId().equals(userId)) {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Not authorized to delete this topic");
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
            }
            
            forumService.deleteTopic(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Topic deleted successfully");
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }
    }

    @Operation(summary = "Upvote topic", description = "Upvote a forum topic")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/topics/{id}/upvote")
    public ResponseEntity<Map<String, Object>> upvoteTopic(@PathVariable Long id) {
        try {
            ForumTopic topic = forumService.upvoteTopic(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Topic upvoted");
            response.put("upvoteCount", topic.getUpvoteCount());
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }
    }

    @Operation(summary = "Mark topic as resolved", description = "Mark a topic as resolved/answered")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/topics/{id}/resolve")
    public ResponseEntity<Map<String, Object>> resolveTop(@PathVariable Long id) {
        try {
            Long userId = getAuthenticatedUserId();
            
            // Verify ownership
            ForumTopic topic = forumService.getTopicById(id)
                .orElseThrow(() -> new RuntimeException("Topic not found"));
            
            if (!topic.getUserId().equals(userId)) {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Not authorized to resolve this topic");
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
            }
            
            ForumTopic resolvedTopic = forumService.markTopicAsResolved(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Topic marked as resolved");
            response.put("data", resolvedTopic);
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }
    }

    // Reply endpoints
    
    @Operation(summary = "Get topic replies", description = "Get all replies for a specific topic")
    @GetMapping("/topics/{topicId}/replies")
    public ResponseEntity<Map<String, Object>> getTopicReplies(
            @PathVariable Long topicId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ForumReply> repliesPage = forumService.getTopicReplies(topicId, pageable);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", repliesPage.getContent());
            response.put("currentPage", repliesPage.getNumber());
            response.put("totalItems", repliesPage.getTotalElements());
            response.put("totalPages", repliesPage.getTotalPages());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to fetch replies");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Create reply", description = "Post a reply to a forum topic")
    @PreAuthorize("hasRole('FARMER') or hasRole('EXPERT')")
    @PostMapping("/topics/{topicId}/replies")
    public ResponseEntity<Map<String, Object>> createReply(
            @PathVariable Long topicId,
            @Valid @RequestBody ForumReply reply) {
        
        try {
            Long userId = getAuthenticatedUserId();
            reply.setUserId(userId);
            reply.setTopicId(topicId);
            
            ForumReply createdReply = forumService.createReply(reply);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Reply posted successfully");
            response.put("data", createdReply);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", "Failed to create reply");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @Operation(summary = "Upvote reply", description = "Upvote a forum reply")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/replies/{id}/upvote")
    public ResponseEntity<Map<String, Object>> upvoteReply(@PathVariable Long id) {
        try {
            ForumReply reply = forumService.upvoteReply(id);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Reply upvoted");
            response.put("upvoteCount", reply.getUpvoteCount());
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }
    }

    @Operation(summary = "Mark reply as accepted answer", description = "Mark a reply as the accepted answer")
    @PreAuthorize("hasRole('FARMER')")
    @PostMapping("/topics/{topicId}/replies/{replyId}/accept")
    public ResponseEntity<Map<String, Object>> acceptAnswer(
            @PathVariable Long topicId,
            @PathVariable Long replyId) {
        
        try {
            Long userId = getAuthenticatedUserId();
            
            // Verify topic ownership
            ForumTopic topic = forumService.getTopicById(topicId)
                .orElseThrow(() -> new RuntimeException("Topic not found"));
            
            if (!topic.getUserId().equals(userId)) {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("error", "Only topic owner can accept answers");
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
            }
            
            ForumReply acceptedReply = forumService.markAsAcceptedAnswer(topicId, replyId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Answer accepted");
            response.put("data", acceptedReply);
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }
    }
}

