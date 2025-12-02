package com.khetisahayak.controller;

import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "Diagnostics", description = "Crop diagnostics and expert review operations")
@RestController
@RequestMapping("/api/diagnostics")
public class DiagnosticsController {

    @GetMapping("/recommendations")
    public ResponseEntity<?> getCropRecommendations() {
        return new ResponseEntity<>("Not Implemented", HttpStatus.NOT_IMPLEMENTED);
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getDiagnosticStats() {
        return new ResponseEntity<>("Not Implemented", HttpStatus.NOT_IMPLEMENTED);
    }

    @PostMapping("/upload")
    public ResponseEntity<?> uploadForDiagnosis(@RequestParam("image") MultipartFile image) {
        return new ResponseEntity<>("Not Implemented", HttpStatus.NOT_IMPLEMENTED);
    }

    @GetMapping
    public ResponseEntity<?> getDiagnosticHistory() {
        return new ResponseEntity<>("Not Implemented", HttpStatus.NOT_IMPLEMENTED);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getDiagnosticById(@PathVariable Long id) {
        return new ResponseEntity<>("Not Implemented", HttpStatus.NOT_IMPLEMENTED);
    }

    @PostMapping("/{id}/expert-review")
    public ResponseEntity<?> requestExpertReview(@PathVariable Long id) {
        return new ResponseEntity<>("Not Implemented", HttpStatus.NOT_IMPLEMENTED);
    }

    @PutMapping("/{id}/expert-review")
    public ResponseEntity<?> submitExpertReview(@PathVariable Long id) {
        return new ResponseEntity<>("Not Implemented", HttpStatus.NOT_IMPLEMENTED);
    }

    @GetMapping("/expert/assigned")
    public ResponseEntity<?> getExpertAssignedDiagnostics() {
        return new ResponseEntity<>("Not Implemented", HttpStatus.NOT_IMPLEMENTED);
    }
}
