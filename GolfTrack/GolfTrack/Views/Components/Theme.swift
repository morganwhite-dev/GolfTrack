import SwiftUI

extension Color {
    static let brandRed = Color(red: 0.74, green: 0.09, blue: 0.15)
    static let brandRedLight = Color(red: 0.92, green: 0.27, blue: 0.24)
    static let charcoal = Color(red: 0.16, green: 0.16, blue: 0.18)
    static let warningAmber = Color(red: 0.85, green: 0.55, blue: 0.15)
    static let slateGray = Color(red: 0.45, green: 0.47, blue: 0.50)
}

/// The app's signature gradient — used on primary CTAs, hero cards, and selected chips.
extension LinearGradient {
    static let brandRed = LinearGradient(colors: [.brandRed, .brandRedLight], startPoint: .topLeading, endPoint: .bottomTrailing)
}

// Lets these resolve via leading-dot syntax in generic `some ShapeStyle` contexts
// (e.g. .foregroundStyle(.brandRed)), not just where the parameter type is concretely `Color`.
extension ShapeStyle where Self == Color {
    static var brandRed: Color { Color.brandRed }
    static var brandRedLight: Color { Color.brandRedLight }
    static var charcoal: Color { Color.charcoal }
    static var warningAmber: Color { Color.warningAmber }
    static var slateGray: Color { Color.slateGray }
}

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
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
    var color: Color = .brandRed
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
            .foregroundStyle(color)
    }
}

/// Circular score-relative-to-par indicator. Follows real golf-leaderboard convention —
/// red marks an under-par (good) score — with amber/charcoal carrying the "needs work" signal
/// instead of red, so red stays a positive, brand-consistent color rather than an alarm color.
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
        case ..<0: return .brandRed
        case 0: return .charcoal
        case 1...4: return .warningAmber
        default: return .slateGray
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
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.brandRed)
                    .frame(width: 30, height: 30)
                    .background(Color.brandRed.opacity(0.12), in: Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Single-row selectable item with a trailing checkmark — used for both single-select
/// (skill level) and multi-select (goals) lists so selection always looks/feels the same.
struct SelectableRow: View {
    let label: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .brandRed : Color.secondary.opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(isSelected ? Color.brandRed.opacity(0.08) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Rounded text field with a soft fill background, used in place of the plain system Form fields.
struct InputField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = .brandRed
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(gradient.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                .background {
                    if isSelected {
                        LinearGradient.brandRed
                    } else {
                        Color.secondary.opacity(0.15)
                    }
                }
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
