import SwiftUI
import FirebaseCore
import GoogleSignIn

// MARK: - AppDelegate
// Handles Firebase initialization and Google Sign-In URL routing.
// Using UIApplicationDelegate provides reliable launch lifecycle hooks
// across iOS versions including iOS 26+.

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - EczanemApp

@main
struct EczanemApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Single shared instance lives for the entire app lifetime
    @StateObject private var authViewModel = AuthViewModel()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(authViewModel)
                .environment(\.managedObjectContext,
                              persistenceController.container.viewContext)
        }
    }
}
