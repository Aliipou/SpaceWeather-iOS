import SwiftUI

struct LoginView: View {
    let onRegister: () -> Void

    @EnvironmentObject private var auth: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        ZStack {
            Color(hex: "0A0A1A").ignoresSafeArea()
            StarFieldBackground()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue.gradient)
                        Text("Space Explorer")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text("Sign in to sync your favorites")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    VStack(spacing: 16) {
                        AuthTextField(
                            title: "Email",
                            text: $email,
                            icon: "envelope",
                            keyboardType: .emailAddress,
                            contentType: .emailAddress
                        )
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                        AuthTextField(
                            title: "Password",
                            text: $password,
                            icon: "lock",
                            isSecure: true,
                            contentType: .password
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await signIn() } }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: { Task { await signIn() } }) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button("Create account") { onRegister() }
                        .foregroundStyle(.blue)
                        .font(.subheadline)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 28)
            }
        }
    }

    private func signIn() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            errorMessage = humanReadable(error)
        }
    }

    private func humanReadable(_ error: Error) -> String {
        switch error {
        case AppError.invalidResponse(let code) where code == 401:
            return "Wrong email or password."
        default:
            return "Sign in failed. Check your connection and try again."
        }
    }
}
