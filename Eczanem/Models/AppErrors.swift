import Foundation

// MARK: - Pharmacy API Errors

enum PharmacyError: LocalizedError {

    case invalidURL
    case networkError(Error)
    case invalidResponse(Int)   // HTTP status code ile birlikte
    case decodingError(Error)
    case noData
    case apiFailure             // success: false döndüğünde

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL adresi oluşturuldu."
        case .networkError(let error):
            return "Ağ hatası: \(error.localizedDescription)"
        case .invalidResponse(let code):
            if code == 429 {
                return "İstek limiti aşıldı. Lütfen 1-2 dakika bekleyip tekrar deneyin."
            }
            return "Sunucu beklenmeyen bir yanıt döndürdü. (Kod: \(code))"
        case .decodingError:
            return "Veri işlenirken bir hata oluştu."
        case .noData:
            return "Sunucudan veri gelmedi."
        case .apiFailure:
            return "API'den başarısız yanıt alındı. Lütfen daha sonra tekrar deneyin."
        }
    }
}

// MARK: - Auth Errors (Türkçe açıklamalar)

enum AuthError: LocalizedError {

    case emailBoş
    case şifreBoş
    case şifrelerEşleşmiyor
    case şifreKısa
    case geçersizEmail
    case firebaseError(String)

    var errorDescription: String? {
        switch self {
        case .emailBoş:
            return "E-posta adresi boş olamaz."
        case .şifreBoş:
            return "Şifre boş olamaz."
        case .şifrelerEşleşmiyor:
            return "Şifreler birbiriyle uyuşmuyor."
        case .şifreKısa:
            return "Şifre en az 6 karakter olmalıdır."
        case .geçersizEmail:
            return "Geçerli bir e-posta adresi girin."
        case .firebaseError(let mesaj):
            return mesaj
        }
    }
}
