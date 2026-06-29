import Foundation
import CoreLocation

// MARK: - LocationService
// Requests the user's GPS position and resolves it to a city/district
// pair via reverse geocoding.

final class LocationService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var currentCity: String?
    @Published var currentDistrict: String?
    @Published var currentLocation: CLLocation?   // raw GPS fix for distance calculation
    @Published var isLocating = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?

    // MARK: - Private

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authContinuation: CheckedContinuation<Void, Error>?   // waits for permission dialog

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer   // kilometre precision is sufficient for pharmacy lookup
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API

    /// Requests permission (if needed), obtains a GPS fix, and reverse-geocodes
    /// the result into city/district strings. Must be called with await.
    func requestLocationAndResolve() async {
        await MainActor.run { isLocating = true; locationError = nil }

        do {
            let location = try await requestLocation()
            let (city, district) = try await reverseGeocode(location: location)

            await MainActor.run {
                self.currentCity = city
                self.currentDistrict = district
                self.currentLocation = location
                self.isLocating = false
            }
        } catch {
            await MainActor.run {
                self.locationError = "Konum alınamadı: \(error.localizedDescription)"
                self.isLocating = false
            }
        }
    }

    // MARK: - Private Helpers

    private func requestLocation() async throws -> CLLocation {
        // Step 1: Handle authorization
        switch manager.authorizationStatus {
        case .notDetermined:
            // Request permission and suspend until the delegate fires
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                self.authContinuation = cont
                self.manager.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            throw NSError(
                domain: "LocationService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Konum izni reddedildi. Ayarlar > Eczanem > Konum bölümünden etkinleştirin."]
            )
        default:
            break   // authorizedWhenInUse / authorizedAlways — proceed
        }

        // Step 2: Permission granted — request a single GPS fix
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.manager.requestLocation()
        }
    }

    private func reverseGeocode(location: CLLocation) async throws -> (city: String, district: String) {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        guard let placemark = placemarks.first else {
            throw NSError(domain: "Geocoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Adres bulunamadı"])
        }

        // administrativeArea  → Province  (e.g. "Ankara")
        // subLocality / locality → District
        let city = placemark.administrativeArea ?? ""
        let district = placemark.subLocality ?? placemark.locality ?? ""

        return (city, district)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted — resume the auth continuation so requestLocation() proceeds
            authContinuation?.resume(returning: ())
            authContinuation = nil
        case .denied, .restricted:
            authContinuation?.resume(throwing: NSError(
                domain: "LocationService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Konum izni reddedildi."]
            ))
            authContinuation = nil
        default:
            break
        }
    }
}
