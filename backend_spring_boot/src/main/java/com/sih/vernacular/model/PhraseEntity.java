package com.sih.vernacular.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "phrase_bank")
public class PhraseEntity {

    @Id
    private String id;
    private String category;
    private String hindiText;
    private String englishText;
    private String santhaliText;
    private String hoText;
    private String mundariText;

    public PhraseEntity() {}

    public PhraseEntity(String id, String category, String hindiText, String englishText, String santhaliText, String hoText, String mundariText) {
        this.id = id;
        this.category = category;
        this.hindiText = hindiText;
        this.englishText = englishText;
        this.santhaliText = santhaliText;
        this.hoText = hoText;
        this.mundariText = mundariText;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getHindiText() { return hindiText; }
    public void setHindiText(String hindiText) { this.hindiText = hindiText; }

    public String getEnglishText() { return englishText; }
    public void setEnglishText(String englishText) { this.englishText = englishText; }

    public String getSanthaliText() { return santhaliText; }
    public void setSanthaliText(String santhaliText) { this.santhaliText = santhaliText; }

    public String getHoText() { return hoText; }
    public void setHoText(String hoText) { this.hoText = hoText; }

    public String getMundariText() { return mundariText; }
    public void setMundariText(String mundariText) { this.mundariText = mundariText; }
}
