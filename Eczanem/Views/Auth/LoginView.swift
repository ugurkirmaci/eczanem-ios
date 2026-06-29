import SwiftUI
import AuthenticationServices
import GoogleSignIn

// MARK: - LoginView

struct LoginView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Logo / branding
                    VStack(spacing: 8) {
                        Image(systemName: "cross.case.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(Color("AppGreen"))

                        Text("Eczanem")
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        Text("Nöbetçi eczaneleri hızla bul")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = authViewModel.prepareAppleSignIn()
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                Task { await authViewModel.signInWithApple(credential: credential) }
                            }
                        case .failure(let error):
                            print("Apple sign-in error: \(error)")
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)

                    // Google Sign In
                    Button {
                        Task { await authViewModel.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            // Google "G" colour block
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 22, height: 22)
                                Text("G")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            Text("Google ile Giriş Yap")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(.label))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading)

                    // Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.3))
                        Text("veya").font(.caption).foregroundColor(.secondary)
                        Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.3))
                    }

                    // Email / Password fields
                    VStack(spacing: 12) {
                        EczaTextField(title: "E-posta", text: $email,
                                      icon: "envelope", keyboardType: .emailAddress)

                        EczaSecureField(title: "Şifre", text: $password, icon: "lock")

                        HStack {
                            Spacer()
                            Button("Şifremi unuttum") { showForgotPassword = true }
                                .font(.caption)
                                .foregroundColor(Color("AppGreen"))
                        }
                    }

                    // Validation error
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Sign In button
                    Button {
                        Task { await authViewModel.signIn(email: email, password: password) }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AppGreen"))
                                .frame(height: 50)
                            if authViewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Giriş Yap")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(authViewModel.isLoading)

                    // Register link
                    Button {
                        showRegister = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Hesabın yok mu?").foregroundColor(.secondary)
                            Text("Kayıt Ol").foregroundColor(Color("AppGreen")).fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegister) { RegisterView() }
            .sheet(isPresented: $showForgotPassword) { ForgotPasswordView() }
        }
    }
}

// MARK: - Reusable Input Components

struct EczaTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct EczaSecureField: View {
    let title: String
    @Binding var text: String
    let icon: String
    @State private var isVisible = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            if isVisible {
                TextField(title, text: $text)
            } else {
                SecureField(title, text: $text)
            }
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
