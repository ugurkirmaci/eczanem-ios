import CoreData

// MARK: - PersistenceController
/// Core Data stack'ini başlatır ve yönetir.

struct PersistenceController {

    static let shared = PersistenceController()

    // Preview için in-memory store
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Preview verisi ekle
        let context = controller.container.viewContext
        let sample = FavoritePharmacy(context: context)
        sample.id = UUID()
        sample.name = "Güven Eczanesi"
        sample.address = "Atatürk Mah. No:1 Çankaya"
        sample.phone = "0312 000 00 00"
        sample.district = "Çankaya"
        sample.savedAt = Date()
        sample.userID = "preview-user"
        try? context.save()
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Eczanem")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Production'da crash yerine log
                print("⛔ Core Data yüklenemedi: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
