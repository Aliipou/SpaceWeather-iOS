import SwiftUI

struct RegisterView: View {
    let onLogin: () -> Void

    @EnvironmentObject private var auth: AuthService
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case name, email, password, confirm }

    private var passwordsMatch: Bool { password == confirmPassword || confirmPassword.isEmpty }
    private var isValid: Bool {
        !email.isEmpty && password.count >= 8 && password == confirmPassword
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A1A").ignoresSafeArea()
            StarFieldBackground()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 48)

                    VStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(.purple.gradient)
                        Text("Create Account")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 14) {
                        AuthTextField(title: "Display Name (optional)", text: $name, icon: "person")
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }

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
                            title: "Password (min 8 chars)",
                            text: $password,
                            icon: "lock",
                            isSecure: true,
                            contentType: .newPassword
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirm }

                        AuthTextField(
                            title: "Confirm Password",
                            text: $confirmPassword,
                            icon: "lock.fill",
                            isSecure: true,
                            contentType: .newPassword,
                            hasError: !passwordsMatch
                        )
                        .focused($focusedField, equals: .confirm)
                        .submitLabel(.go)
                        .onSubmit { if isValid { Task { await register() } } }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: { Task { await register() } }) {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(isLoading || !isValid)

                    Button("Already have an account? Sign in") { onLogin() }
                        .foregroundStyle(.blue)
                        .font(.subheadline)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 28)
            }
        }
    }

    private func register() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.register(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                displayName: name.isEmpty ? nil : name.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            switch error {
            case AppError.conflict:
                errorMessage = "That email is already registered."
            default:
                errorMessage = "Registration failed. Try again later."
            }
        }
    }
}
