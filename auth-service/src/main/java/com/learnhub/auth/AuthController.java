package com.learnhub.auth;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        try {
            String result = authService.register(
                    request.name(),
                    request.email(),
                    request.password()
            );

            return ResponseEntity.ok(new MessageResponse(result));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(new MessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            return ResponseEntity.ok(
                    authService.login(request.email(), request.password())
            );

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse(e.getMessage()));
        }
    }

    public record RegisterRequest(String name, String email, String password) {}
    public record LoginRequest(String email, String password) {}
    public record MessageResponse(String message) {}
}
