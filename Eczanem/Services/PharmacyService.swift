import Foundation

// MARK: - PharmacyService
// Fetches on-duty pharmacy data from CollectAPI.
// Reference: https://collectapi.com/api/health/pharmaciesApi

final class PharmacyService {

    static let shared = PharmacyService()
    private init() {}

    // MARK: - Constants

    private let baseURL = "https://api.collectapi.com/health"

    /// Reads the API key from Info.plist — never hardcoded.
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "COLLECT_API_KEY") as? String,
              !key.isEmpty,
              key != "YOUR_COLLECTAPI_KEY_HERE"
        else {
            assertionFailure("⛔ COLLECT_API_KEY is not set in Info.plist")
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

    // MARK: - Fetch On-Duty Pharmacies

    /// Returns today's on-duty pharmacies for the given city and optional district.
    /// - Parameters:
    ///   - city: Province name (e.g. "Ankara")
    ///   - district: District name — omit or pass empty string for the whole province
    func fetchDutyPharmacies(city: String, district: String = "") async throws -> [Pharmacy] {
        var components = URLComponents(string: "\(baseURL)/dutyPharmacy")
        components?.queryItems = [
            URLQueryItem(name: "il", value: city),
            URLQueryItem(name: "ilce", value: district)
        ].filter { !($0.value?.isEmpty ?? true) }

        guard let url = components?.url else {
            throw PharmacyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PharmacyError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw PharmacyError.invalidResponse(http.statusCode)
        }

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

    // MARK: - Fetch Districts

    /// Returns the list of districts for the given province.
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
