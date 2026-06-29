import Foundation
import CoreLocation

// MARK: - LocationService
/// Kullanıcının GPS konumunu alır ve
/// şehir / ilçe bilgisine çevirir (reverse geocoding).

final class LocationService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var currentCity: String?
    @Published var currentDistrict: String?
    @Published var currentLocation: CLLocation?   // ham GPS verisi — mesafe hesabı için
    @Published var isLocating = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?

    // MARK: - Private

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authContinuation: CheckedContinuation<Void, Error>?   // izin bekleme

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer   // eczane için km yeterli
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API

    /// İzin iste ve konumu al — async/await ile çağrılır
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
        // 1. İzin durumunu kontrol et
        switch manager.authorizationStatus {
        case .notDetermined:
            // İzni iste ve cevabı bekle (delegate üzerinden)
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                self.authContinuation = cont
                self.manager.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            throw NSError(domain: "LocationService",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Konum izni reddedildi. Ayarlar > Eczanem > Konum bölümünden etkinleştirin."])
        default:
            break   // authorizedWhenInUse veya authorizedAlways → devam et
        }

        // 2. İzin var, konumu iste
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

        // administrativeArea → İl (örn: "Ankara")
        // subAdministrativeArea veya locality → İlçe
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
            // İzin verildi — authContinuation'ı çöz (requestLocation'daki await bitsin)
            authContinuation?.resume(returning: ())
            authContinuation = nil
        case .denied, .restricted:
            authContinuation?.resume(throwing: NSError(
                domain: "LocationService", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Konum izni reddedildi."]
            ))
            authContinuation = nil
        default:
            break
        }
    }
}
