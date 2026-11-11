
package com.learnhub.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(
            @Valid @RequestBody RegisterRequest request) {

        try {
            String result = authService.register(
                    request.name(),
                    request.email(),
                    request.password()
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new MessageResponse(result));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(new MessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(
            @Valid @RequestBody LoginRequest request) {

        try {
            return ResponseEntity.ok(
                    authService.login(
                            request.email(),
                            request.password()
                    )
            );

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse(e.getMessage()));
        }
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(
            Authentication authentication) {

        return ResponseEntity.ok(
                new CurrentUserResponse(authentication.getName())
        );
    }

    public record RegisterRequest(
            @NotBlank
            @Size(max = 100)
            String name,

            @NotBlank
            @Email
            @Size(max = 150)
            String email,

            @NotBlank
            @Size(min = 8, max = 72)
            String password
    ) {}

    public record LoginRequest(
            @NotBlank
            @Email
            String email,

            @NotBlank
            String password
    ) {}

    public record MessageResponse(String message) {}

    public record CurrentUserResponse(String email) {}
}
