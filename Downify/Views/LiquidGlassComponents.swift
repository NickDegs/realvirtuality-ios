import SwiftUI

// MARK: - Brand

extension Color {
    static let brand = Color(red: 0.52, green: 0.16, blue: 0.88)
}

// MARK: - iOS 26 Native Glass Helpers

extension View {
    func glassCard(radius: CGFloat = 18) -> some View {
        glassEffect(in: RoundedRectangle(cornerRadius: radius))
    }

    func glassInput(radius: CGFloat = 13) -> some View {
        glassEffect(in: RoundedRectangle(cornerRadius: radius))
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
        if isSelected {
            content.background(Theme.accent, in: Capsule())
        } else {
            content.glassEffect(in: .capsule)
        }
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
