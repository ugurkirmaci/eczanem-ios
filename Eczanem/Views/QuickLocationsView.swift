import SwiftUI

// MARK: - QuickLocationsView
/// Hizli Erisim: GPS ile aninda en yakin eczane + kayitli sehir kisayollari

struct QuickLocationsView: View {
    @ObservedObject var viewModel: PharmacyViewModel
    @Binding var selectedTab: Int
    @ObservedObject private var service = QuickLocationsService.shared

    @State private var isLocating = false
    @State private var showSaveSheet = false
    @State private var savedFeedback = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    gpsCard
                    if !service.locations.isEmpty { savedSection }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Hizli Erisim")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .overlay(alignment: .top) {
                if savedFeedback {
                    feedbackBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 4)
                }
            }
            .confirmationDialog("Konumu Kaydet", isPresented: $showSaveSheet, titleVisibility: .visible) {
                Button("\(viewModel.selectedCity) - \(viewModel.selectedDistrict.isEmpty ? "Tum ilceler" : viewModel.selectedDistrict) kaydet") {
                    saveCurrentLocation()
                }
                Button("Iptal", role: .cancel) { }
            } message: {
                Text("Secili konumu hizli erisim listene eklemek istiyor musun?")
            }
        }
    }

    // MARK: - GPS Hero Karti

    private var gpsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color("AppGreen").opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(Color("AppGreen"))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("En Yakin Nobetci Eczane")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Konumun algilayip en yakin eczaneleri siralar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            Button {
                findNearestPharmacy()
            } label: {
                HStack(spacing: 10) {
                    if isLocating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.9)
                        Text("Konum aliniyor...")
                            .font(.headline)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("Bana En Yakin Eczaneyi Bul")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isLocating ? Color("AppGreen").opacity(0.6) : Color("AppGreen"))
                )
            }
            .disabled(isLocating)
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: Color("AppGreen").opacity(0.12), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Kayitli Konumlar

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Kayitli Konumlar")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                EditButton()
                    .font(.subheadline)
                    .foregroundColor(Color("AppGreen"))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(service.locations) { loc in
                    savedLocationRow(loc)
                }
            }
        }
    }

    private func savedLocationRow(_ loc: SavedLocation) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("AppGreen").opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color("AppGreen"))
                    .font(.subheadline)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.city)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(loc.district.isEmpty ? "Tum ilceler" : loc.district)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { applyLocation(loc) } label: {
                HStack(spacing: 3) {
                    Text("Ara")
                        .font(.caption)
                        .foregroundColor(Color("AppGreen"))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(Color("AppGreen"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color("AppGreen").opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                if let idx = service.locations.firstIndex(where: { $0.id == loc.id }) {
                    service.delete(at: IndexSet(integer: idx))
                }
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }

    // MARK: - Feedback Banner

    private var feedbackBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
            Text("Kaydedildi!").foregroundColor(.white).font(.subheadline).fontWeight(.medium)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color("AppGreen")).cornerRadius(20).shadow(radius: 4)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showSaveSheet = true } label: {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(Color("AppGreen"))
                    .font(.title3)
            }
        }
    }

    // MARK: - Aksiyonlar

    private func findNearestPharmacy() {
        guard !isLocating else { return }
        isLocating = true
        Task {
            await viewModel.loadWithUserLocation()
            isLocating = false
            withAnimation { selectedTab = 0 }
        }
    }

    private func applyLocation(_ loc: SavedLocation) {
        viewModel.selectedCity = loc.city
        viewModel.selectedDistrict = loc.district
        Task {
            await viewModel.loadPharmacies()
            await MainActor.run { withAnimation { selectedTab = 0 } }
        }
    }

    private func saveCurrentLocation() {
        let city = viewModel.selectedCity
        guard !city.isEmpty else { return }
        service.save(city: city, district: viewModel.selectedDistrict)
        withAnimation { savedFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { savedFeedback = false }
        }
    }
}
