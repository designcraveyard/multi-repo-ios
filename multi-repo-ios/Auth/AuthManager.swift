//
//  AuthManager.swift
//  multi-repo-ios
//
//  Observable auth state manager. Listens to Supabase auth state changes
//  and provides sign-in / sign-out methods for Google, Apple, and Email.
//

import Foundation
import Supabase
import AuthenticationServices
import GoogleSignIn

// MARK: - AuthManager

@Observable
@MainActor
final class AuthManager {

    // MARK: - State

    var currentUser: User?
    var currentProfile: ProfileModel?
    var isLoading = true
    var authError: String?

    private nonisolated(unsafe) var authStateTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        listenToAuthState()
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Auth State Listener

    private func listenToAuthState() {
        authStateTask = Task { [weak self] in
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                guard let self else { return }
                switch event {
                case .initialSession:
                    self.currentUser = session?.user
                    if self.currentUser != nil {
                        await self.fetchProfile()
                    }
                    self.isLoading = false
                case .signedIn:
                    self.currentUser = session?.user
                    await self.fetchProfile()
                case .signedOut:
                    self.currentUser = nil
                    self.currentProfile = nil
                default:
                    break
                }
            }
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        authError = nil
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            authError = "Cannot find root view controller"
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                authError = "Missing Google ID token"
                return
            }

            try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
            )
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Apple Sign In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        authError = nil

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                authError = "Invalid Apple credential"
                return
            }

            do {
                try await SupabaseManager.shared.client.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityToken
                    )
                )
            } catch {
                authError = error.localizedDescription
            }

        case .failure(let error):
            // User cancelled is not an error
            if (error as? ASAuthorizationError)?.code != .canceled {
                authError = error.localizedDescription
            }
        }
    }

    // MARK: - Email / Password

    func signInWithEmail(email: String, password: String) async {
        authError = nil
        do {
            try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
        } catch {
            authError = error.localizedDescription
        }
    }

    func signUpWithEmail(email: String, password: String) async {
        authError = nil
        do {
            try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Profile

    private func fetchProfile() async {
        guard let userId = currentUser?.id else { return }
        do {
            currentProfile = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
        } catch {
            // Profile may not exist yet if trigger hasn't fired
            currentProfile = nil
        }
    }
}
