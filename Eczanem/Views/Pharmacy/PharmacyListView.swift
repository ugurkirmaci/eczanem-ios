import SwiftUI

// MARK: - PharmacyListView

struct PharmacyListView: View {

    @ObservedObject var viewModel: PharmacyViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showCityPicker = false
    @State private var showDistrictPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.filteredPharmacies.isEmpty && !viewModel.searchText.isEmpty {
                    emptySearchView
                } else if viewModel.filteredPharmacies.isEmpty {
                    emptyView
                } else {
                    pharmacyList
                }
            }
            .navigationTitle("Nöbetçi Eczaneler")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Eczane veya adres ara")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showCityPicker) { cityPickerSheet }
            .sheet(isPresented: $showDistrictPicker) { districtPickerSheet }
            .task { await viewModel.loadPharmacies() }
        }
    }

    // MARK: - List

    private var pharmacyList: some View {
        List {
            ForEach(Array(viewModel.filteredPharmacies.enumerated()), id: \.element.id) { index, pharmacy in
                PharmacyRowView(
                    pharmacy: pharmacy,
                    userID: authViewModel.currentUser?.uid ?? "",
                    isNearest: index == 0 && viewModel.userLocation != nil,
                    distanceText: viewModel.distanceText(for: pharmacy)
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .overlay(alignment: .bottomTrailing) {
            resultCount
        }
    }

    private var resultCount: some View {
        Text("\(viewModel.filteredPharmacies.count) eczane")
            .font(.caption2)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.trailing, 16)
            .padding(.bottom, 8)
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Eczaneler yükleniyor...")
                .foregroundColor(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.7))
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            Button("Tekrar Dene") {
                Task { await viewModel.loadPharmacies() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AppGreen"))
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cross.case")
                .font(.system(size: 48))
                .foregroundColor(Color("AppGreen").opacity(0.5))
            Text("Bu bölgede nöbetçi eczane bulunamadı.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("'\(viewModel.searchText)' için sonuç bulunamadı.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { Task { viewModel.loadWithUserLocation() } } label: {
                Image(systemName: "location.fill")
                    .foregroundColor(Color("AppGreen"))
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 8) {
                // Province picker
                Button {
                    showCityPicker = true
                } label: {
                    Label(viewModel.selectedCity, systemImage: "building.2")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(Color("AppGreen"))
                }

                // District picker
                if !viewModel.availableDistricts.isEmpty {
                    Button {
                        showDistrictPicker = true
                    } label: {
                        Label(
                            viewModel.selectedDistrict.isEmpty ? "İlçe" : viewModel.selectedDistrict,
                            systemImage: "map"
                        )
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(Color("AppGreen"))
                    }
                }
            }
        }
    }

    // MARK: - Province Picker Sheet

    private var cityPickerSheet: some View {
        NavigationStack {
            List(turkeyProvinces, id: \.self) { city in
                Button {
                    viewModel.selectedCity = city
                    viewModel.cityDidChange()
                    showCityPicker = false
                    Task { await viewModel.loadPharmacies() }
                } label: {
                    HStack {
                        Text(city)
                            .foregroundColor(.primary)
                        Spacer()
                        if viewModel.selectedCity == city {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("AppGreen"))
                        }
                    }
                }
            }
            .navigationTitle("İl Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { showCityPicker = false }
                }
            }
        }
    }

    // MARK: - District Picker Sheet

    private var districtPickerSheet: some View {
        NavigationStack {
            List(viewModel.availableDistricts, id: \.self) { district in
                Button {
                    viewModel.selectedDistrict = district == "Tümü" ? "" : district
                    showDistrictPicker = false
                    Task { await viewModel.loadPharmacies() }
                } label: {
                    HStack {
                        Text(district)
                            .foregroundColor(.primary)
                        Spacer()
                        let current = viewModel.selectedDistrict.isEmpty ? "Tümü" : viewModel.selectedDistrict
                        if current == district {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("AppGreen"))
                        }
                    }
                }
            }
            .navigationTitle("İlçe Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { showDistrictPicker = false }
                }
            }
        }
    }
}
