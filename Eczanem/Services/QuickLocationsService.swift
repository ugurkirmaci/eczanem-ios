import Foundation
import Combine

// MARK: - SavedLocation Model

struct SavedLocation: Codable, Identifiable, Hashable {
    var id = UUID()
    let city: String
    let district: String      // "" ise tüm ilçeler

    var displayName: String {
        district.isEmpty ? city : "\(city) · \(district)"
    }
}

// MARK: - QuickLocationsService
/// Kullanıcının hızlı erişim için kaydettiği şehir/ilçe çiftlerini
/// UserDefaults'ta saklar. Core Data gerektirmez.

final class QuickLocationsService: ObservableObject {

    static let shared = QuickLocationsService()

    @Published private(set) var locations: [SavedLocation] = []

    private let key = "quick_locations_v1"

    private init() {
        load()
    }

    // MARK: - Kaydet

    func save(city: String, district: String) {
        let new = SavedLocation(city: city, district: district)
        // Aynı çift zaten varsa ekleme
        guard !locations.contains(where: { $0.city == city && $0.district == district }) else { return }
        locations.insert(new, at: 0)            // en sone eklenen başa gelsin
        if locations.count > 10 { locations = Array(locations.prefix(10)) }
        persist()
    }

    // MARK: - Sil

    func delete(_ location: SavedLocation) {
        locations.removeAll { $0.id == location.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        locations.remove(atOffsets: offsets)
        persist()
    }

    // MARK: - Kalıcılık

    private func persist() {
        if let data = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([SavedLocation].self, from: data)
        else { return }
        locations = saved
    }
}
