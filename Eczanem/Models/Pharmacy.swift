import Foundation
import MapKit

// MARK: - API Response Models

struct PharmacyResponse: Decodable {
    let success: Bool
    let result: [Pharmacy]
}

struct DistrictResponse: Decodable {
    let success: Bool
    let result: [DistrictItem]
}

struct DistrictItem: Decodable {
    let ilce: String
}

// MARK: - Pharmacy Model

struct Pharmacy: Identifiable, Decodable, Hashable {
    var id = UUID()
    let name: String
    let dist: String
    let address: String
    let phone: String
    let loc: String        // "lat,lng" string from API

    enum CodingKeys: String, CodingKey {
        case name, dist, address, phone, loc
    }

    // MARK: - Coordinate

    /// Parses the "lat,lng" loc string into a CLLocationCoordinate2D.
    var coordinate: CLLocationCoordinate2D? {
        let parts = loc.split(separator: ",")
        guard parts.count == 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lng = Double(parts[1].trimmingCharacters(in: .whitespaces))
        else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// MKMapItem representation for use with MapKit.
    var mapItem: MKMapItem? {
        guard let coord = coordinate else { return nil }
        let placemark = MKPlacemark(coordinate: coord)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        item.phoneNumber = phone
        return item
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(address)
        hasher.combine(phone)
    }

    static func == (lhs: Pharmacy, rhs: Pharmacy) -> Bool {
        lhs.name == rhs.name &&
        lhs.address == rhs.address &&
        lhs.phone == rhs.phone
    }
}

// MARK: - Turkey Provinces

/// All 81 Turkish provinces in alphabetical order.
let turkeyProvinces: [String] = [
    "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Amasya",
    "Ankara", "Antalya", "Artvin", "Aydın", "Balıkesir",
    "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur",
    "Bursa", "Çanakkale", "Çankırı", "Çorum", "Denizli",
    "Diyarbakır", "Edirne", "Elazığ", "Erzincan", "Erzurum",
    "Eskişehir", "Gaziantep", "Giresun", "Gümüşhane", "Hakkari",
    "Hatay", "Isparta", "İçel", "İstanbul", "İzmir",
    "Kars", "Kastamonu", "Kayseri", "Kırklareli", "Kırşehir",
    "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa",
    "Kahramanmaraş", "Mardin", "Muğla", "Muş", "Nevşehir",
    "Niğde", "Ordu", "Rize", "Sakarya", "Samsun",
    "Siirt", "Sinop", "Sivas", "Tekirdağ", "Tokat",
    "Trabzon", "Tunceli", "Şanlıurfa", "Uşak", "Van",
    "Yozgat", "Zonguldak", "Aksaray", "Bayburt", "Karaman",
    "Kırıkkale", "Batman", "Şırnak", "Bartın", "Ardahan",
    "Iğdır", "Yalova", "Karabük", "Kilis", "Osmaniye", "Düzce"
]
