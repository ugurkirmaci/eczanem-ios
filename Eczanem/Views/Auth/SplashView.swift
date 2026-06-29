import SwiftUI

// MARK: - SplashView
/// Uygulama açılışında oturum kontrolü yapar ve yönlendirir.

struct SplashView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLaunch = true

    var body: some View {
        ZStack {
            if showLaunch {
                launchScreen
            } else {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showLaunch = false
                }
            }
        }
    }

    // MARK: - Launch Ekranı

    private var launchScreen: some View {
        ZStack {
            Color("AppGreen")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "cross.case.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)

                Text("Eczanem")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Nöbetçi Eczane Bulucu")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .transition(.opacity)
    }
}
