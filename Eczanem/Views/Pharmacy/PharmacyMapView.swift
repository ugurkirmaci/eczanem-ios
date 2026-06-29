import SwiftUI
import MapKit

// MARK: - PharmacyMapView
/// iOS 16 uyumlu MapKit görünümü — Map(coordinateRegion:annotationItems:)

struct PharmacyMapView: View {

    @ObservedObject var viewModel: PharmacyViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedPharmacy: Pharmacy?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.015, longitude: 28.979), // İstanbul
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )

    // Sadece koordinatı olan eczaneleri göster
    private var mappablePharmacies: [Pharmacy] {
        viewModel.filteredPharmacies.filter { $0.coordinate != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // MARK: Harita
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    annotationItems: mappablePharmacies) { pharmacy in
                    MapAnnotation(coordinate: pharmacy.coordinate!) {
                        pharmacyPin(pharmacy)
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                // MARK: Seçili Eczane Kartı
                if let selected = selectedPharmacy {
                    PharmacyDetailCard(
                        pharmacy: selected,
                        userID: authViewModel.currentUser?.uid ?? "",
                        onClose: { selectedPharmacy = nil }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }

                // MARK: Veri yoksa bilgi kutusu
                if viewModel.isLoading {
                    ProgressView("Yükleniyor...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 80)
                }
            }
            .navigationTitle("Harita")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.3), value: selectedPharmacy?.id)
            .onChange(of: viewModel.filteredPharmacies) { pharmacies in
                centerMapOnPharmacies(pharmacies)
            }
        }
    }

    // MARK: - Pin Görünümü

    private func pharmacyPin(_ pharmacy: Pharmacy) -> some View {
        Button {
            withAnimation { selectedPharmacy = pharmacy }
            if let coord = pharmacy.coordinate {
                withAnimation {
                    region.center = coord
                }
            }
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(selectedPharmacy?.id == pharmacy.id
                              ? Color("AppGreen") : Color("AppGreen").opacity(0.85))
                        .frame(width: 36, height: 36)
                        .shadow(radius: 3)
                    Image(systemName: "cross.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                // Küçük üçgen
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                    .foregroundColor(Color("AppGreen"))
                    .offset(y: -4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedPharmacy?.id == pharmacy.id ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: selectedPharmacy?.id)
    }

    // MARK: - Haritayı Eczanelere Ortala

    private func centerMapOnPharmacies(_ pharmacies: [Pharmacy]) {
        let coords = pharmacies.compactMap { $0.coordinate }
        guard !coords.isEmpty else { return }

        let lats = coords.map { $0.latitude }
        let lngs = coords.map { $0.longitude }

        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lngs.min()! + lngs.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.4, 0.05),
            longitudeDelta: max((lngs.max()! - lngs.min()!) * 1.4, 0.05)
        )
        withAnimation {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

// MARK: - Seçili Eczane Kartı

struct PharmacyDetailCard: View {

    let pharmacy: Pharmacy
    let userID: String
    let onClose: () -> Void
    @State private var showCallConfirm = false

    private var cleanPhone: String { pharmacy.phone.filter { $0.isNumber } }
    private var isPhoneValid: Bool { cleanPhone.count >= 7 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pharmacy.name)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(pharmacy.dist)
                        .font(.caption)
                        .foregroundColor(Color("AppGreen"))
                }
                Spacer()
                Button { onClose() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }

            Text(pharmacy.address)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                // Telefon — confirmationDialog ile "Ara" seçeneği
                Button {
                    if isPhoneValid { showCallConfirm = true }
                } label: {
                    Label(
                        isPhoneValid ? pharmacy.phone : "Numara Yok",
                        systemImage: "phone.fill"
                    )
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isPhoneValid ? Color("AppGreen") : Color.secondary)
                    .cornerRadius(8)
                }
                .buttonStyle(.borderless)
                .disabled(!isPhoneValid)

                // Yol Tarifi — Apple Maps
                Button {
                    if let coord = pharmacy.coordinate {
                        let lat = String(format: "%.6f", coord.latitude)
                        let lng = String(format: "%.6f", coord.longitude)
                        if let url = URL(string: "maps://?daddr=\(lat),\(lng)&dirflg=d") {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        let query = "\(pharmacy.name), \(pharmacy.address)"
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "maps://?q=\(query)") {
                            UIApplication.shared.open(url)
                        }
                    }
                } label: {
                    Label("Yol Tarifi", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.borderless)

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 8)
        .onAppear { }
        .confirmationDialog(
            pharmacy.name,
            isPresented: $showCallConfirm,
            titleVisibility: .visible
        ) {
            Button("Ara  \(pharmacy.phone)") {
                if let url = URL(string: "tel:\(cleanPhone)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Eczaneyi aramak istiyor musunuz?")
        }
    }
}
