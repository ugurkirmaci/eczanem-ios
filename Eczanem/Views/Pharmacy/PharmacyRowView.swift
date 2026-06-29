import SwiftUI

// MARK: - PharmacyRowView

struct PharmacyRowView: View {

    let pharmacy: Pharmacy
    let userID: String
    var isNearest: Bool = false        // GPS ile bulunan en yakın eczane
    var distanceText: String? = nil    // "1.2 km" veya "350 m"


    @State private var showCallConfirm = false
    @State private var isVisible = false      // slide-in animasyonu
    @State private var pulse = false          // "En Yakın" nabız efekti

    private var cleanPhone: String { pharmacy.phone.filter { $0.isNumber } }
    private var isPhoneValid: Bool { cleanPhone.count >= 7 }

    // iOS 16 ShareLink için paylaşım metni
    private var shareText: String {
        var lines = ["🏥 \(pharmacy.name)"]
        lines.append("📍 \(pharmacy.address)")
        if isPhoneValid { lines.append("📞 \(pharmacy.phone)") }
        if let coord = pharmacy.coordinate {
            let lat = String(format: "%.6f", coord.latitude)
            let lng = String(format: "%.6f", coord.longitude)
            lines.append("🗺️ maps://?daddr=\(lat),\(lng)&dirflg=d")
        }
        lines.append("\n— Eczanem Uygulaması ile paylaşıldı")
        return lines.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Üst kısım
            HStack(alignment: .top) {
                // İkon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("AppGreen").opacity(isNearest ? 0.22 : 0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(Color("AppGreen"))
                        .scaleEffect(isNearest ? 1.1 : 1.0)
                }

                // Bilgiler
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pharmacy.name)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        // "En Yakın" rozeti — nabız etkisi
                        if isNearest {
                            Text("EN YAKIN")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color("AppGreen"))
                                        .scaleEffect(pulse ? 1.08 : 1.0)
                                )
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                        pulse = true
                                    }
                                }
                        }
                    }

                    HStack(spacing: 6) {
                        Text(pharmacy.dist)
                            .font(.caption)
                            .foregroundColor(Color("AppGreen"))
                            .fontWeight(.medium)

                        // Mesafe etiketi
                        if let dist = distanceText {
                            Text("· \(dist)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(pharmacy.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Paylaş
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
            .padding(12)

            // MARK: Alt — Eylemler
            HStack(spacing: 0) {
                // Telefon
                Button { if isPhoneValid { showCallConfirm = true } } label: {
                    Label(
                        isPhoneValid ? pharmacy.phone : "Numara Yok",
                        systemImage: "phone.fill"
                    )
                    .font(.caption)
                    .foregroundColor(isPhoneValid ? Color("AppGreen") : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(!isPhoneValid)

                Divider().frame(height: 36)

                // Yol Tarifi
                Button { openDirections() } label: {
                    Label("Yol Tarifi", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
            .background(Color(.secondarySystemBackground).opacity(0.5))
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: isNearest ? Color("AppGreen").opacity(0.18) : .black.opacity(0.06),
                radius: isNearest ? 8 : 4, x: 0, y: 2)
        // Slide-in animasyon
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 18)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
        .confirmationDialog(pharmacy.name, isPresented: $showCallConfirm, titleVisibility: .visible) {
            Button("Ara  \(pharmacy.phone)") {
                if let url = URL(string: "tel:\(cleanPhone)") { UIApplication.shared.open(url) }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Eczaneyi aramak istiyor musunuz?")
        }
    }

    // MARK: - Yol Tarifi

    private func openDirections() {
        if let coord = pharmacy.coordinate {
            let lat = String(format: "%.6f", coord.latitude)
            let lng = String(format: "%.6f", coord.longitude)
            if let url = URL(string: "maps://?daddr=\(lat),\(lng)&dirflg=d") {
                UIApplication.shared.open(url); return
            }
        }
        let query = "\(pharmacy.name), \(pharmacy.address)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(query)") { UIApplication.shared.open(url) }
    }


}

