import SwiftUI

// MARK: - RegisterView

struct RegisterView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(Color("AppGreen"))
                        Text("Hesap Oluştur")
                            .font(.title2.bold())
                    }
                    .padding(.top, 20)

                    // Input fields
                    VStack(spacing: 12) {
                        EczaTextField(title: "E-posta", text: $email,
                                      icon: "envelope", keyboardType: .emailAddress)

                        EczaSecureField(title: "Şifre (en az 6 karakter)", text: $password, icon: "lock")

                        EczaSecureField(title: "Şifre Tekrar", text: $confirmPassword, icon: "lock.fill")
                    }

                    // Validation error
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Register button
                    Button {
                        Task {
                            await authViewModel.register(
                                email: email,
                                password: password,
                                confirmPassword: confirmPassword
                            )
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AppGreen"))
                                .frame(height: 50)
                            if authViewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Kayıt Ol")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(authViewModel.isLoading)

                    // Geri
                    Button("Zaten hesabım var") { dismiss() }
                        .font(.subheadline)
                        .foregroundColor(Color("AppGreen"))
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
        }
    }
}
