import Foundation
import Combine
import Supabase
import Auth

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let client: SupabaseClient

    var session: Session? {
        get async {
            try? await client.auth.session
        }
    }

    init() {
        self.client = SupabaseManager.shared.client
        listenToAuthChanges()
    }

    // MARK: - Auth Methods

    func checkSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentUser = session.user
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }

    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
    }

    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        await MainActor.run {
            self.currentUser = session.user
            self.isAuthenticated = true
        }
    }

    func signOut() async throws {
        try await client.auth.signOut()
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    // MARK: - Private

    private func listenToAuthChanges() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn:
                        self.currentUser = session?.user
                        self.isAuthenticated = true
                    case .signedOut:
                        self.currentUser = nil
                        self.isAuthenticated = false
                    default:
                        break
                    }
                }
            }
        }
    }
}

