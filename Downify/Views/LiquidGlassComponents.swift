import SwiftUI

// MARK: - Brand

extension Color {
    static let brand      = Color(red: 0.52, green: 0.16, blue: 0.88)
    static let brandDark  = Color(red: 0.36, green: 0.07, blue: 0.70)
    static let brandLight = Color(red: 0.70, green: 0.45, blue: 0.98)
}

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [Color(red: 0.55, green: 0.18, blue: 0.90), Color(red: 0.38, green: 0.08, blue: 0.72)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Background

struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            LinearGradient(
                colors: [Color.purple.opacity(0.15), Color.indigo.opacity(0.06), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Glass Modifiers

extension View {
    func glassCard(radius: CGFloat = 18) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: .black.opacity(0.09), radius: 14, y: 6)
    }

    func glassInput(radius: CGFloat = 13) -> some View {
        self
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.6)
            )
    }

    func glassBorder(radius: CGFloat = 18) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(Color.white.opacity(0.18), lineWidth: 0.7)
        )
    }
}

// MARK: - Primary Button

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 12 : 16)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .background {
                if enabled {
                    LinearGradient.brand
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 16))
                } else {
                    Color(.systemGray4)
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 16))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 12 : 16)
                    .stroke(Color.white.opacity(enabled ? 0.22 : 0), lineWidth: 0.8)
            )
            .shadow(color: Color.brand.opacity(enabled ? 0.38 : 0), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Glass Pill

struct GlassPill: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(_ label: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label; self.icon = icon; self.isSelected = isSelected; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.caption.bold()) }
                Text(label).font(.caption.bold())
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .secondary)
            .background(.thinMaterial, in: Capsule())
            .background {
                if isSelected {
                    LinearGradient.brand.clipShape(Capsule())
                }
            }
            .overlay(Capsule().stroke(Color.white.opacity(isSelected ? 0.28 : 0.12), lineWidth: 0.6))
            .shadow(color: Color.brand.opacity(isSelected ? 0.3 : 0), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    var text: String = "FULL"
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill").font(.system(size: 9))
            Text(text).font(.system(size: 9, weight: .black))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(
            LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing),
            in: Capsule()
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Tümü"

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            if let action {
                Button(actionLabel, action: action)
                    .font(.subheadline)
                    .foregroundStyle(.purple)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Başla"

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.10))
                    .frame(width: 90, height: 90)
                Image(systemName: icon)
                    .font(.system(size: 38))
                    .foregroundStyle(Color.brand.opacity(0.7))
            }
            VStack(spacing: 6) {
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let action {
                Button(actionLabel, action: action)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Color.brand, in: Capsule())
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold())
        }
    }
}

// MARK: - Loading Button Label

struct LoadingLabel: View {
    let isLoading: Bool
    let icon: String
    let loadingText: String
    let idleText: String

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView().tint(.white).scaleEffect(0.85)
            } else {
                Image(systemName: icon).font(.body.bold())
            }
            Text(isLoading ? loadingText : idleText)
        }
    }
}
