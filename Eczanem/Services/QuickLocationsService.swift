import Foundation
import Combine

// MARK: - SavedLocation Model

struct SavedLocation: Codable, Identifiable, Hashable {
    var id = UUID()
    let city: String
    let district: String      // empty string means whole province

    var displayName: String {
        district.isEmpty ? city : "\(city) · \(district)"
    }
}

// MARK: - QuickLocationsService
// Persists user-saved city/district shortcuts in UserDefaults.
// No Core Data dependency required.

final class QuickLocationsService: ObservableObject {

    static let shared = QuickLocationsService()

    @Published private(set) var locations: [SavedLocation] = []

    private let storageKey = "quick_locations_v1"

    private init() {
        load()
    }

    // MARK: - Save

    func save(city: String, district: String) {
        let new = SavedLocation(city: city, district: district)
        // Skip duplicates
        guard !locations.contains(where: { $0.city == city && $0.district == district }) else { return }
        locations.insert(new, at: 0)            // newest entry first
        if locations.count > 10 { locations = Array(locations.prefix(10)) }
        persist()
    }

    // MARK: - Delete

    func delete(_ location: SavedLocation) {
        locations.removeAll { $0.id == location.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        locations.remove(atOffsets: offsets)
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([SavedLocation].self, from: data)
        else { return }
        locations = saved
    }
}
