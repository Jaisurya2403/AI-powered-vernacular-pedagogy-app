package com.sih.vernacular;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class VernacularApplication {
    public static void main(String[] args) {
        SpringApplication.run(VernacularApplication.class, args);
        System.out.println("SIH26042 Vernacular Pedagogy Spring Boot Microservice running on port 8080 with SQLite DB!");
    }
}
