import SwiftUI

// MARK: - PharmacyRowView
// A card-style row showing pharmacy details with slide-in animation,
// nearest badge, distance label, phone call, directions, and share actions.

struct PharmacyRowView: View {

    let pharmacy: Pharmacy
    let userID: String
    var isNearest: Bool = false        // true for the GPS-closest pharmacy
    var distanceText: String? = nil    // e.g. "1.2 km" or "350 m"

    @State private var showCallConfirm = false
    @State private var isVisible = false      // drives slide-in animation
    @State private var pulse = false          // drives nearest badge pulse

    private var cleanPhone: String { pharmacy.phone.filter { $0.isNumber } }
    private var isPhoneValid: Bool { cleanPhone.count >= 7 }

    // Share sheet content
    private var shareText: String {
        var lines = ["🏥 \(pharmacy.name)"]
        lines.append("📍 \(pharmacy.address)")
        if isPhoneValid { lines.append("📞 \(pharmacy.phone)") }
        if let coord = pharmacy.coordinate {
            let lat = String(format: "%.6f", coord.latitude)
            let lng = String(format: "%.6f", coord.longitude)
            lines.append("🗺️ maps://?daddr=\(lat),\(lng)&dirflg=d")
        }
        lines.append("\n— Shared via Eczanem")
        return lines.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Top row
            HStack(alignment: .top) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("AppGreen").opacity(isNearest ? 0.22 : 0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(Color("AppGreen"))
                        .scaleEffect(isNearest ? 1.1 : 1.0)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pharmacy.name)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        // Nearest badge with pulse animation
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

                        // Distance label
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

                // Share button
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
            .padding(12)

            // MARK: Bottom action bar
            HStack(spacing: 0) {
                // Phone call
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

                // Directions
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
        // Slide-in spring animation on appear
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

    // MARK: - Directions

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
