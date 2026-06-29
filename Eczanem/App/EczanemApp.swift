import SwiftUI
import Firebase
import GoogleSignIn

@main
struct EczanemApp: App {

    // AuthViewModel tüm uygulama boyunca yaşayan tek instance
    @StateObject private var authViewModel = AuthViewModel()

    // Core Data Persistence controller
    let persistenceController = PersistenceController.shared

    init() {
        // Firebase başlat — GoogleService-Info.plist mevcut olmalı
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(authViewModel)
                .environment(\.managedObjectContext,
                              persistenceController.container.viewContext)
                .onOpenURL { url in
                    // Google Sign-In yönlendirme URL'ini yakala
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
