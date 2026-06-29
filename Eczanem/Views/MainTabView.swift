import SwiftUI

// MARK: - MainTabView
// Root tab navigation for authenticated users.
// PharmacyViewModel is created once here and shared across all tabs.

struct MainTabView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var pharmacyViewModel = PharmacyViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            PharmacyListView(viewModel: pharmacyViewModel)
                .tabItem { Label("Eczaneler", systemImage: "list.bullet.rectangle") }
                .tag(0)

            PharmacyMapView(viewModel: pharmacyViewModel)
                .tabItem { Label("Harita", systemImage: "map.fill") }
                .tag(1)

            QuickLocationsView(viewModel: pharmacyViewModel, selectedTab: $selectedTab)
                .tabItem { Label("Hızlı Erişim", systemImage: "bookmark.fill") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(Color("AppGreen"))
    }
}

// MARK: - ProfileView

struct ProfileView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color("AppGreen").opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(Color("AppGreen"))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(authViewModel.currentUser?.email ?? "Kullanıcı")
                                .font(.headline)
                                .lineLimit(1)
                            Text("Eczanem Üyesi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // App info
                Section("Uygulama") {
                    Label("Eczanem v1.0", systemImage: "cross.case.fill")
                        .foregroundColor(Color("AppGreen"))
                    Link(destination: URL(string: "https://collectapi.com")!) {
                        Label("Veri Kaynağı: CollectAPI", systemImage: "server.rack")
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profil")
            .alert("Çıkış Yap", isPresented: $showSignOutAlert) {
                Button("Çıkış Yap", role: .destructive) { authViewModel.signOut() }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Hesabınızdan çıkış yapmak istediğinizden emin misiniz?")
            }
        }
    }
}
