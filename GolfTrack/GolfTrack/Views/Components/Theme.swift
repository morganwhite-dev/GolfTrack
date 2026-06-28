import SwiftUI

extension Color {
    static let golfGreen = Color(red: 0.13, green: 0.42, blue: 0.25)
    static let fairwayGreen = Color(red: 0.20, green: 0.55, blue: 0.32)
    static let sandTan = Color(red: 0.82, green: 0.71, blue: 0.52)
    static let warningAmber = Color(red: 0.85, green: 0.55, blue: 0.15)
    static let dangerRed = Color(red: 0.78, green: 0.22, blue: 0.22)
}

// Lets these resolve via leading-dot syntax in generic `some ShapeStyle` contexts
// (e.g. .foregroundStyle(.golfGreen)), not just where the parameter type is concretely `Color`.
extension ShapeStyle where Self == Color {
    static var golfGreen: Color { Color.golfGreen }
    static var fairwayGreen: Color { Color.fairwayGreen }
    static var sandTan: Color { Color.sandTan }
    static var warningAmber: Color { Color.warningAmber }
    static var dangerRed: Color { Color.dangerRed }
}

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 20) -> some View {
        modifier(CardBackground(padding: padding, cornerRadius: cornerRadius))
    }
}

/// Small rounded tag used for skill level, goals, and hole-count badges.
struct Pill: View {
    let text: String
    var color: Color = .golfGreen
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
            .foregroundStyle(color)
    }
}

/// Circular score-relative-to-par indicator, color coded: under par (green), even (blue),
/// a little over (amber), well over (red). Used anywhere a round or hole score is summarized.
struct ScoreBadge: View {
    let scoreToPar: Int
    var size: CGFloat = 44

    var body: some View {
        Circle()
            .fill(color.opacity(0.15))
            .overlay(Circle().strokeBorder(color, lineWidth: 1.5))
            .frame(width: size, height: size)
            .overlay(
                Text(scoreToParText(scoreToPar))
                    .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.7)
            )
    }

    private var color: Color {
        switch scoreToPar {
        case ..<0: return .golfGreen
        case 0: return .blue
        case 1...4: return .warningAmber
        default: return .dangerRed
        }
    }
}

func scoreToParText(_ value: Int) -> String {
    if value == 0 { return "E" }
    return value > 0 ? "+\(value)" : "\(value)"
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
