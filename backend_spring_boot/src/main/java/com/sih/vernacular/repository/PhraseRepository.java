package com.sih.vernacular.repository;

import com.sih.vernacular.model.PhraseEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PhraseRepository extends JpaRepository<PhraseEntity, String> {
    List<PhraseEntity> findByCategory(String category);
    List<PhraseEntity> findByHindiTextContainingIgnoreCase(String hindiText);
}
