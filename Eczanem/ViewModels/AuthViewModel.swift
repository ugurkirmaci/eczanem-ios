import Foundation
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

// MARK: - AuthViewModel
// Manages Firebase Authentication state and all sign-in flows.

final class AuthViewModel: ObservableObject {

    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false

    // Nonce storage for Apple Sign In
    private var currentNonce: String?

    init() {
        // Restore session on app launch
        currentUser = Auth.auth().currentUser
        isAuthenticated = currentUser != nil

        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    // MARK: - Email / Password Sign In

    func signIn(email: String, password: String) async {
        guard validateEmail(email), validatePassword(password) else { return }

        await setLoading(true)
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            await setLoading(false)
        } catch {
            await setError(localizedFirebaseError(error))
        }
    }

    // MARK: - Registration

    func register(email: String, password: String, confirmPassword: String) async {
        guard validateEmail(email) else { return }
        guard !password.isEmpty else {
            await setError("Şifre boş olamaz.")
            return
        }
        guard password.count >= 6 else {
            await setError("Şifre en az 6 karakter olmalıdır.")
            return
        }
        guard password == confirmPassword else {
            await setError("Şifreler birbiriyle uyuşmuyor.")
            return
        }

        await setLoading(true)
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            await setLoading(false)
        } catch {
            await setError(localizedFirebaseError(error))
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async -> Bool {
        guard validateEmail(email) else { return false }
        await setLoading(true)
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            await setLoading(false)
            return true
        } catch {
            await setError(localizedFirebaseError(error))
            return false
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Çıkış yapılırken hata oluştu."
            }
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            await setError("Google yapılandırması bulunamadı.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        await setLoading(true)

        do {
            // Access the key window via MainActor
            let rootVC = await MainActor.run { () -> UIViewController? in
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?
                    .rootViewController
            }

            guard let rootVC else {
                await setError("Ekran açılamadı. Tekrar deneyin.")
                return
            }

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                await setError("Google kimlik doğrulaması başarısız.")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
            await setLoading(false)
        } catch {
            // User cancelled — clear loading state silently
            let nsError = error as NSError
            if nsError.code == GIDSignInError.canceled.rawValue {
                await setLoading(false)
            } else {
                await setError("Google ile giriş başarısız: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Apple Sign In — Nonce Preparation

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    // MARK: - Apple Sign In — Firebase credential sign-in

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let nonce = currentNonce,
              let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            await setError("Apple girişi sırasında hata oluştu.")
            return
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        await setLoading(true)
        do {
            try await Auth.auth().signIn(with: firebaseCredential)
            await setLoading(false)
        } catch {
            await setError(localizedFirebaseError(error))
        }
    }

    // MARK: - Validation

    private func validateEmail(_ email: String) -> Bool {
        guard !email.isEmpty else {
            Task { await setError("E-posta adresi boş olamaz.") }
            return false
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard predicate.evaluate(with: email) else {
            Task { await setError("Geçerli bir e-posta adresi girin.") }
            return false
        }
        return true
    }

    private func validatePassword(_ password: String) -> Bool {
        guard !password.isEmpty else {
            Task { await setError("Şifre boş olamaz.") }
            return false
        }
        return true
    }

    // MARK: - Firebase Error Localization

    private func localizedFirebaseError(_ error: Error) -> String {
        let code = AuthErrorCode(_bridgedNSError: error as NSError)
        switch code?.code {
        case .wrongPassword:        return "Şifre hatalı. Lütfen tekrar deneyin."
        case .userNotFound:         return "Bu e-posta ile kayıtlı hesap bulunamadı."
        case .emailAlreadyInUse:    return "Bu e-posta adresi zaten kullanılıyor."
        case .invalidEmail:         return "Geçersiz e-posta adresi."
        case .weakPassword:         return "Şifre çok zayıf. En az 6 karakter kullanın."
        case .networkError:         return "İnternet bağlantınızı kontrol edin."
        case .tooManyRequests:      return "Çok fazla deneme yapıldı. Lütfen bekleyin."
        default:                    return error.localizedDescription
        }
    }

    // MARK: - Helpers

    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
        if value { errorMessage = nil }
    }

    @MainActor
    private func setError(_ message: String) {
        errorMessage = message
        isLoading = false
    }

    // MARK: - Nonce Utilities (required for Apple Sign In)

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Failed to generate nonce: \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
