//
//  LoginView.swift
//  multi-repo-ios
//
//  Login screen — Figma node 108:5991
//  Layout: green hero area (top ~45%), then "Get Started" title, email input,
//  and three auth buttons (Email, Apple, Google).
//  responsive: N/A — single-column form works on all size classes
//

import SwiftUI
import AuthenticationServices
import PhosphorSwift

// MARK: - LoginView

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // --- Hero area ---
                Color.surfacesSuccessSubtle
                    .frame(height: 320)

                // --- Auth form ---
                VStack(alignment: .leading, spacing: .space6) {

                    // --- Section header ---
                    Text(isSignUp ? "Create Account" : "Get Started")
                        .font(.appTitleSmall)
                        .foregroundStyle(Color.typographyPrimary)

                    // --- Email input ---
                    AppInputField(
                        text: $email,
                        placeholder: "Enter Email"
                    )

                    // --- Password input ---
                    AppInputField(
                        text: $password,
                        placeholder: "Password"
                    )

                    // --- Error message ---
                    if let error = authManager.authError {
                        Text(error)
                            .font(.appCaptionMedium)
                            .foregroundStyle(Color.surfacesErrorSolid)
                    }

                    // --- Auth buttons ---
                    VStack(spacing: .space3) {
                        // Email button
                        AppButton(
                            label: isSignUp ? "Sign Up with Email" : "Login via Email",
                            variant: .primary,
                            size: .lg,
                            leadingIcon: AnyView(Ph.envelopeSimple.regular),
                            trailingIcon: AnyView(Ph.arrowRight.regular)
                        ) {
                            Task {
                                if isSignUp {
                                    await authManager.signUpWithEmail(email: email, password: password)
                                } else {
                                    await authManager.signInWithEmail(email: email, password: password)
                                }
                            }
                        }

                        // Apple Sign-In (native button required by Apple)
                        SignInWithAppleButton(
                            isSignUp ? .signUp : .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                Task {
                                    await authManager.handleAppleSignIn(result: result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 48)
                        .clipShape(Capsule())

                        // Google button
                        AppButton(
                            label: "Login via Google",
                            variant: .secondary,
                            size: .lg,
                            leadingIcon: AnyView(Ph.googleLogo.regular),
                            trailingIcon: AnyView(Ph.arrowRight.regular)
                        ) {
                            Task { await authManager.signInWithGoogle() }
                        }
                    }

                    // --- Toggle sign up / sign in ---
                    HStack(spacing: 4) {
                        Spacer()
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .font(.appBodyMedium)
                            .foregroundStyle(Color.typographyMuted)
                        Button(isSignUp ? "Sign In" : "Sign Up") {
                            isSignUp.toggle()
                            authManager.authError = nil
                        }
                        .font(.appBodyMediumEm)
                        .foregroundStyle(Color.typographyBrand)
                        Spacer()
                    }
                }
                .padding(.horizontal, .space6)
                .padding(.vertical, .space8)
            }
        }
        .background(Color.surfacesBasePrimary)
        .ignoresSafeArea(edges: .top)
    }
}
