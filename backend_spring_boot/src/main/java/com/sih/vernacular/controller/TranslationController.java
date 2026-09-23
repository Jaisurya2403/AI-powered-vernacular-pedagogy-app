package com.sih.vernacular.controller;

import com.sih.vernacular.model.PhraseEntity;
import com.sih.vernacular.repository.PhraseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/v1/translation")
@CrossOrigin(origins = "*")
public class TranslationController {

    @Autowired
    private PhraseRepository phraseRepository;

    @GetMapping("/phrases")
    public List<PhraseEntity> getAllPhrases() {
        return phraseRepository.findAll();
    }

    @PostMapping("/phrases")
    public ResponseEntity<PhraseEntity> addPhrase(@RequestBody PhraseEntity phrase) {
        if (phrase.getId() == null || phrase.getId().isEmpty()) {
            phrase.setId(UUID.randomUUID().toString());
        }
        PhraseEntity saved = phraseRepository.save(phrase);
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/search")
    public List<PhraseEntity> searchPhrases(@RequestParam("query") String query) {
        return phraseRepository.findByHindiTextContainingIgnoreCase(query);
    }

    @GetMapping("/status")
    public Map<String, String> getServiceStatus() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "UP");
        status.put("database", "SQLite (vernacular_pedagogy.db)");
        status.put("ram_footprint", "< 50 MB");
        status.put("latency_target", "< 3.0 seconds");
        return status;
    }
}
