import SwiftUI

extension Color {
    static let golfGreen = Color(red: 0.13, green: 0.42, blue: 0.25)
    static let fairwayGreen = Color(red: 0.20, green: 0.55, blue: 0.32)
    static let sandTan = Color(red: 0.82, green: 0.71, blue: 0.52)
    static let warningAmber = Color(red: 0.85, green: 0.55, blue: 0.15)
    static let dangerRed = Color(red: 0.78, green: 0.22, blue: 0.22)
}

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
extension View {
    func cardStyle(padding: CGFloat = 16) -> some View { modifier(CardBackground(padding: padding)) }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.headline)
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .golfGreen
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryGolf: PrimaryButtonStyle { PrimaryButtonStyle() }
}

/// Large tappable score chip used throughout hole entry for fast, low-typing input.
struct ChoiceChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(minWidth: 44, minHeight: 44)
                .background(isSelected ? Color.golfGreen : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
