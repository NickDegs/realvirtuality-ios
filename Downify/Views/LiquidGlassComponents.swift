import SwiftUI

// MARK: - Brand

extension Color {
    /// Brand colour now follows the editorial accent (no more purple).
    static let brand = Theme.accent
}

// MARK: - Frosted surfaces (stable, iOS 16+)
// Uses `.ultraThinMaterial` for a translucent editorial look. Avoids the
// iOS-26-only Liquid Glass APIs (glassEffect / glassProminent /
// GlassEffectContainer) that forced an iOS-26-only deployment target and
// were the most likely startup-crash surface.

extension View {
    /// Frosted surface for any shape (replaces `.glassEffect(in:)`).
    func frosted<S: Shape>(in shape: S, tinted: Bool = false) -> some View {
        background(
            tinted ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.ultraThinMaterial),
            in: shape
        )
    }

    /// A static frosted surface (cards, sheets) with a hairline edge.
    func glassCard(radius: CGFloat = 18) -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
    }

    /// Frosted surface for inputs.
    func glassInput(radius: CGFloat = 13) -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
    }

    /// Frosted surface for tappable controls; tinted when active.
    func liquidGlass(tinted: Bool = false, radius: CGFloat = 18) -> some View {
        background(
            tinted ? AnyShapeStyle(Theme.accent.opacity(0.18)) : AnyShapeStyle(.ultraThinMaterial),
            in: RoundedRectangle(cornerRadius: radius)
        )
    }
}

// MARK: - Glass Pill (iOS 26)

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
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .modifier(PillStyle(isSelected: isSelected))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

struct PillStyle: ViewModifier {
    let isSelected: Bool
    func body(content: Content) -> some View {
        // Frosted capsule; tinted accent when selected.
        content.background(
            isSelected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.ultraThinMaterial),
            in: .capsule
        )
        .overlay(
            Capsule().strokeBorder(Color.primary.opacity(isSelected ? 0 : 0.08), lineWidth: 0.5)
        )
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

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Başla"

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundStyle(Color.brand.opacity(0.8))
            VStack(spacing: 6) {
                Text(title).font(.title3.bold())
                Text(subtitle)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
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

// MARK: - Loading Label

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
