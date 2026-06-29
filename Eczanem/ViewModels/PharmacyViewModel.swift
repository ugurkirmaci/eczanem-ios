import Foundation
import Combine
import CoreLocation

// MARK: - PharmacyViewModel
// Manages the pharmacy list, city/district selection, search filtering,
// distance sorting, and response caching.

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
    @Published var userLocation: CLLocation?   // raw GPS position for distance sorting

    // MARK: - Private

    private let service = PharmacyService.shared
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Cache (rate limit protection)
    private var cacheCity = ""
    private var cacheDistrict = ""
    private var cacheTime: Date = .distantPast
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    init() {
        // Re-filter whenever search text or pharmacy list changes
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

    // MARK: - Distance Calculation

    /// Straight-line distance in kilometres from the user to a pharmacy.
    func distanceKm(to pharmacy: Pharmacy) -> Double? {
        guard let userLocation, let coord = pharmacy.coordinate else { return nil }
        let dest = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return userLocation.distance(from: dest) / 1000.0
    }

    /// Human-readable distance string — "1.2 km" or "350 m".
    func distanceText(for pharmacy: Pharmacy) -> String? {
        guard let km = distanceKm(to: pharmacy) else { return nil }
        return km < 1 ? String(format: "%.0f m", km * 1000) : String(format: "%.1f km", km)
    }

    /// The nearest pharmacy — first item in the filtered list.
    var nearestPharmacy: Pharmacy? { filteredPharmacies.first }

    // MARK: - City Change

    func cityDidChange() {
        selectedDistrict = ""
        availableDistricts = []
        cacheTime = .distantPast // invalidate cache when city changes
        Task { await loadDistricts() }
    }

    // MARK: - Load Pharmacies

    @MainActor
    func loadPharmacies() async {
        // Skip network request if same city/district was fetched recently
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
            // Sort by distance when GPS is available, otherwise preserve API order
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
            // Update cache
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

    // MARK: - Load Districts

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

    // MARK: - GPS-based Auto Load

    func loadWithUserLocation() async {
        await locationService.requestLocationAndResolve()
        // Publish state updates on the main thread
        await MainActor.run {
            if let city = locationService.currentCity, !city.isEmpty {
                selectedCity = city
            }
            if let district = locationService.currentDistrict, !district.isEmpty {
                selectedDistrict = district
            }
            userLocation = locationService.currentLocation
        }
        await loadPharmacies()
    }
}
