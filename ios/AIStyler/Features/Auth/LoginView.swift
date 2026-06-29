import SwiftUI

struct LoginView: View {
    @Bindable var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))

                Text("AI Styler")
                    .font(.largeTitle.bold())

                Text(isSignUp ? "Create an account to get started." : "Sign in to generate and save your looks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isSignUp {
                    Text("At least 8 characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 40)

            Button {
                Task { await submit() }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text(isSignUp ? "Create account" : "Sign in")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting || !canSubmit)
            .padding(.horizontal, 40)

            Button(isSignUp ? "Already have an account? Sign in" : "Need an account? Sign up") {
                isSignUp.toggle()
                authService.errorMessage = nil
            }
            .font(.subheadline)

            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= (isSignUp ? 8 : 1)
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }

        if isSignUp {
            await authService.signUp(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } else {
            await authService.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        }
    }
}

#Preview {
    LoginView(authService: AuthService())
}
