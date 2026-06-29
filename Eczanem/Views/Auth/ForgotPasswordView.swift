import SwiftUI

// MARK: - ForgotPasswordView

struct ForgotPasswordView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color("AppGreen"))
                    .padding(.top, 40)

                Text("Şifre Sıfırla")
                    .font(.title2.bold())

                Text("E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                EczaTextField(title: "E-posta", text: $email,
                              icon: "envelope", keyboardType: .emailAddress)
                    .padding(.horizontal, 24)

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        let success = await authViewModel.sendPasswordReset(email: email)
                        if success { showSuccess = true }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("AppGreen"))
                            .frame(height: 50)
                        if authViewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Bağlantı Gönder")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .disabled(authViewModel.isLoading)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("E-posta Gönderildi", isPresented: $showSuccess) {
                Button("Tamam") { dismiss() }
            } message: {
                Text("Şifre sıfırlama bağlantısı \(email) adresine gönderildi.")
            }
        }
    }
}
