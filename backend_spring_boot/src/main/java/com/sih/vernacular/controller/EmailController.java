package com.sih.vernacular.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/email")
@CrossOrigin(origins = "*")
public class EmailController {

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @PostMapping("/send-otp")
    public ResponseEntity<Map<String, Object>> sendOtp(@RequestBody Map<String, String> request) {
        Map<String, Object> response = new HashMap<>();
        try {
            String recipientEmail = request.get("recipientEmail");
            String recipientName = request.getOrDefault("recipientName", "User");
            String otpCode = request.get("otpCode");

            if (mailSender != null) {
                SimpleMailMessage mailMessage = new SimpleMailMessage();
                mailMessage.setFrom("alonewarrior123456@gmail.com");
                mailMessage.setTo(recipientEmail);
                mailMessage.setSubject("🔐 Vernacular Pedagogy - Email Verification OTP: " + otpCode);
                mailMessage.setText("Hello " + recipientName + ",\n\nYour OTP code for Vernacular Pedagogy email verification is: " + otpCode + "\n\nThis code will expire in 10 minutes.\n\nThank you,\nVernacular Pedagogy Team");

                mailSender.send(mailMessage);
            }

            response.put("success", true);
            response.put("message", "OTP email sent successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @PostMapping("/send-reset")
    public ResponseEntity<Map<String, Object>> sendReset(@RequestBody Map<String, String> request) {
        Map<String, Object> response = new HashMap<>();
        try {
            String recipientEmail = request.get("recipientEmail");
            String recipientName = request.getOrDefault("recipientName", "Teacher");
            String resetCode = request.get("resetCode");

            if (mailSender != null) {
                SimpleMailMessage mailMessage = new SimpleMailMessage();
                mailMessage.setFrom("alonewarrior123456@gmail.com");
                mailMessage.setTo(recipientEmail);
                mailMessage.setSubject("🔑 Vernacular Pedagogy - Password Reset OTP: " + resetCode);
                mailMessage.setText("Hello " + recipientName + ",\n\nYour OTP code for password reset is: " + resetCode + "\n\nUse this code to reset your password.\n\nThank you,\nVernacular Pedagogy Security Team");

                mailSender.send(mailMessage);
            }

            response.put("success", true);
            response.put("message", "Password reset email sent successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }
}
