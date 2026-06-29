import Foundation

// MARK: - PharmacyService
/// CollectAPI üzerinden nöbetçi eczane verisi çeker.
/// Dökümantasyon: https://collectapi.com/api/health/pharmaciesApi

final class PharmacyService {

    // MARK: Singleton değil — dışarıdan init edilir
    static let shared = PharmacyService()
    private init() {}

    // MARK: - Sabitler

    private let baseURL = "https://api.collectapi.com/health"

    /// API anahtarını Info.plist'ten okur — hardcode yapmıyoruz
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "COLLECT_API_KEY") as? String,
              !key.isEmpty,
              key != "BURAYA_API_KEYINI_YAPISTIR"
        else {
            assertionFailure("⛔ COLLECT_API_KEY Info.plist içinde tanımlanmamış!")
            return ""
        }
        return key
    }

    private var defaultHeaders: [String: String] {
        [
            "authorization": "apikey \(apiKey)",
            "content-type": "application/json"
        ]
    }

    // MARK: - Nöbetçi Eczane Çekme

    /// Belirtilen il ve ilçe için bugünkü nöbetçi eczaneleri getirir.
    /// - Parameters:
    ///   - city: İl adı (örn: "Ankara")
    ///   - district: İlçe adı (örn: "Çankaya") — boş bırakılırsa tüm il
    /// - Returns: Pharmacy dizisi
    func fetchDutyPharmacies(city: String, district: String = "") async throws -> [Pharmacy] {
        // 1. URL oluştur
        var components = URLComponents(string: "\(baseURL)/dutyPharmacy")
        components?.queryItems = [
            URLQueryItem(name: "il", value: city),
            URLQueryItem(name: "ilce", value: district)
        ].filter { !($0.value?.isEmpty ?? true) }

        guard let url = components?.url else {
            throw PharmacyError.invalidURL
        }

        // 2. Request oluştur
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        // 3. İstek at (async/await)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PharmacyError.networkError(error)
        }

        // 4. HTTP status code kontrol
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw PharmacyError.invalidResponse(http.statusCode)
        }

        // 5. JSON Decode
        do {
            let decoded = try JSONDecoder().decode(PharmacyResponse.self, from: data)
            guard decoded.success else { throw PharmacyError.apiFailure }
            return decoded.result
        } catch let decodeError as PharmacyError {
            throw decodeError
        } catch {
            throw PharmacyError.decodingError(error)
        }
    }

    // MARK: - İlçe Listesi Çekme

    /// Bir ile ait ilçe listesini getirir.
    /// - Parameter city: İl adı
    /// - Returns: İlçe adları dizisi
    func fetchDistricts(city: String) async throws -> [String] {
        var components = URLComponents(string: "\(baseURL)/districtList")
        components?.queryItems = [
            URLQueryItem(name: "il", value: city)
        ]

        guard let url = components?.url else {
            throw PharmacyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw PharmacyError.invalidResponse(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(DistrictResponse.self, from: data)
            guard decoded.success else { throw PharmacyError.apiFailure }
            return decoded.result.map { $0.ilce }
        } catch let decodeError as PharmacyError {
            throw decodeError
        } catch {
            throw PharmacyError.decodingError(error)
        }
    }
}
