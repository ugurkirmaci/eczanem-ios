import Foundation
import Combine
import CoreLocation

// MARK: - PharmacyViewModel
/// Eczane listesi, il/ilçe seçimi ve arama işlemlerini yönetir.
/// iOS 16 uyumlu: ObservableObject + @Published

final class PharmacyViewModel: ObservableObject {

    // MARK: - Published

    @Published var pharmacies: [Pharmacy] = []
    @Published var filteredPharmacies: [Pharmacy] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCity = "İstanbul"
    @Published var selectedDistrict = ""
    @Published var availableDistricts: [String] = []
    @Published var searchText = ""
    @Published var userLocation: CLLocation?   // GPS konumu — mesafe sıralama için

    // MARK: - Private

    private let service = PharmacyService.shared
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Önbellek (rate limit koruması)
    private var cacheCity = ""
    private var cacheDistrict = ""
    private var cacheTime: Date = .distantPast
    private let cacheTTL: TimeInterval = 300 // 5 dakika

    init() {
        // searchText değişince filtreleme yap
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .combineLatest($pharmacies)
            .map { searchText, pharmacies in
                guard !searchText.isEmpty else { return pharmacies }
                return pharmacies.filter { pharmacy in
                    pharmacy.name.localizedStandardContains(searchText) ||
                    pharmacy.address.localizedStandardContains(searchText) ||
                    pharmacy.dist.localizedStandardContains(searchText)
                }
            }
            .assign(to: &$filteredPharmacies)
    }

    // MARK: - Mesafe Hesabı

    /// Kullanıcıdan eczaneye km cinsinden mesafe
    func distanceKm(to pharmacy: Pharmacy) -> Double? {
        guard let userLocation, let coord = pharmacy.coordinate else { return nil }
        let dest = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return userLocation.distance(from: dest) / 1000.0
    }

    /// Mesafeyi okunabilir stringe çevirir ("1.2 km" / "350 m")
    func distanceText(for pharmacy: Pharmacy) -> String? {
        guard let km = distanceKm(to: pharmacy) else { return nil }
        return km < 1 ? String(format: "%.0f m", km * 1000) : String(format: "%.1f km", km)
    }

    /// Kullanıcıya en yakın eczane
    var nearestPharmacy: Pharmacy? { filteredPharmacies.first }

    // MARK: - İl Değişince Çağrılan

    func cityDidChange() {
        selectedDistrict = ""
        availableDistricts = []
        cacheTime = .distantPast // şehir değişince önbelleği sıfırla
        Task { await loadDistricts() }
    }

    // MARK: - Eczane Yükleme

    @MainActor
    func loadPharmacies() async {
        // Aynı il/ilçe yakın zamanda çekildiyse tekrar istek atmıyoruz
        let isCacheValid = cacheCity == selectedCity &&
                           cacheDistrict == selectedDistrict &&
                           Date().timeIntervalSince(cacheTime) < cacheTTL
        if isCacheValid && !pharmacies.isEmpty {
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let result = try await service.fetchDutyPharmacies(
                city: selectedCity,
                district: selectedDistrict
            )
            // Konum varsa mesafeye göre sırala, yoksa API sırası
            if let loc = userLocation {
                pharmacies = result.sorted {
                    let d1 = distanceKmStatic(from: loc, to: $0) ?? .infinity
                    let d2 = distanceKmStatic(from: loc, to: $1) ?? .infinity
                    return d1 < d2
                }
            } else {
                pharmacies = result
            }
            filteredPharmacies = pharmacies
            // Önbelleği güncelle
            cacheCity = selectedCity
            cacheDistrict = selectedDistrict
            cacheTime = Date()
        } catch {
            errorMessage = (error as? PharmacyError)?.errorDescription ?? error.localizedDescription
            pharmacies = []
            filteredPharmacies = []
        }
        isLoading = false
    }

    private func distanceKmStatic(from loc: CLLocation, to pharmacy: Pharmacy) -> Double? {
        guard let coord = pharmacy.coordinate else { return nil }
        return loc.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) / 1000
    }

    // MARK: - İlçe Yükleme

    @MainActor
    func loadDistricts() async {
        guard !selectedCity.isEmpty else { return }
        do {
            let districts = try await service.fetchDistricts(city: selectedCity)
            availableDistricts = ["Tümü"] + districts
        } catch {
            availableDistricts = ["Tümü"]
        }
    }

    // MARK: - GPS Konumuyla Otomatik Yükleme

    func loadWithUserLocation() {
        Task {
            await locationService.requestLocationAndResolve()
            await MainActor.run {
                if let city = locationService.currentCity, !city.isEmpty {
                    self.selectedCity = city
                }
                if let district = locationService.currentDistrict, !district.isEmpty {
                    self.selectedDistrict = district
                }
                // Ham konumu kaydet — mesafe sıralaması için
                self.userLocation = locationService.currentLocation
            }
            await loadPharmacies()
        }
    }
}
