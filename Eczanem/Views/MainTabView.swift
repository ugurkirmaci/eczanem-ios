import SwiftUI

// MARK: - MainTabView
/// Giriş yapılmış kullanıcılar için ana tab navigasyonu.
/// PharmacyViewModel tek yerde oluşturulur ve her tab'a aktarılır.

struct MainTabView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var pharmacyViewModel = PharmacyViewModel()
    @State private var showProfileSheet = false
    @State private var selectedTab = 0      // tab geçişini yönetir

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Tab 1 — Liste
            PharmacyListView(viewModel: pharmacyViewModel)
                .tabItem { Label("Eczaneler", systemImage: "list.bullet.rectangle") }
                .tag(0)

            // MARK: Tab 2 — Harita
            PharmacyMapView(viewModel: pharmacyViewModel)
                .tabItem { Label("Harita", systemImage: "map.fill") }
                .tag(1)

            // MARK: Tab 3 — Hızlı Aramalar
            QuickLocationsView(viewModel: pharmacyViewModel, selectedTab: $selectedTab)
                .tabItem { Label("Hızlı Erişim", systemImage: "bookmark.fill") }
                .tag(2)

            // MARK: Tab 4 — Profil
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
                // Kullanıcı Bilgisi
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

                // Uygulama
                Section("Uygulama") {
                    Label("Eczanem v1.0", systemImage: "cross.case.fill")
                        .foregroundColor(Color("AppGreen"))
                    Link(destination: URL(string: "https://collectapi.com")!) {
                        Label("Veri Kaynağı: CollectAPI", systemImage: "server.rack")
                    }
                }

                // Çıkış
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
