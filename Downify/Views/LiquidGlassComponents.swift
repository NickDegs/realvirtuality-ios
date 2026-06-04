import SwiftUI

// MARK: - Background

struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.18),
                    Color.indigo.opacity(0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Glass Card

extension View {
    func glassCard(radius: CGFloat = 18) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
    }

    func glassInput(radius: CGFloat = 13) -> some View {
        self
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
            )
    }
}

// MARK: - Primary Button

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .background {
                if enabled {
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.18, blue: 0.90),
                            Color(red: 0.38, green: 0.08, blue: 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Color(.systemGray4)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(enabled ? 0.22 : 0), lineWidth: 0.7)
            )
            .shadow(color: Color.purple.opacity(enabled ? 0.4 : 0), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Glass Pill (mode/option chips)

struct GlassPill: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(_ label: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.bold())
                }
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .secondary)
            .background(.thinMaterial, in: Capsule())
            .background {
                if isSelected {
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.18, blue: 0.90),
                            Color(red: 0.38, green: 0.08, blue: 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(Capsule())
                }
            }
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.3 : 0.12), lineWidth: 0.6)
            )
            .shadow(color: Color.purple.opacity(isSelected ? 0.35 : 0), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
