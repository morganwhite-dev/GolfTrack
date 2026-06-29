import SwiftUI
import UIKit

extension Color {
    // Backdrop — dark emerald fading to black, the app's signature gradient backdrop.
    static let bgTop = Color(red: 0.035, green: 0.09, blue: 0.065)
    static let bgBottom = Color(red: 0.01, green: 0.015, blue: 0.012)

    // Brand accent — glowing mint/emerald green.
    static let emerald = Color(red: 0.22, green: 0.86, blue: 0.55)
    static let emeraldLight = Color(red: 0.58, green: 0.97, blue: 0.78)
    static let emeraldDeep = Color(red: 0.05, green: 0.27, blue: 0.18)

    // Card surface — sits just above the backdrop with a faint emerald-tinted fill.
    static let cardFill = Color(red: 0.065, green: 0.105, blue: 0.085)
    static let cardBorder = Color.emerald.opacity(0.22)
    static let cardFillRaised = Color(red: 0.09, green: 0.14, blue: 0.115)

    static let charcoal = Color.white.opacity(0.85)
    static let warningAmber = Color(red: 0.93, green: 0.58, blue: 0.27)
    static let alertCoral = Color(red: 0.92, green: 0.40, blue: 0.38)
    static let slateGray = Color.white.opacity(0.45)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.56)
    static let textTertiary = Color.white.opacity(0.34)
}

/// The app's signature gradients — backdrop, primary CTAs, hero cards, selected chips.
extension LinearGradient {
    static let emerald = LinearGradient(colors: [.emerald, .emeraldLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let emeraldGlow = LinearGradient(colors: [Color.emerald.opacity(0.95), Color.emeraldDeep], startPoint: .top, endPoint: .bottom)
    static let appBackdrop = LinearGradient(colors: [.bgTop, .bgBottom, .black], startPoint: .top, endPoint: .bottom)
}

// Lets these resolve via leading-dot syntax in generic `some ShapeStyle` contexts
// (e.g. .foregroundStyle(.emerald)), not just where the parameter type is concretely `Color`.
extension ShapeStyle where Self == Color {
    static var emerald: Color { Color.emerald }
    static var emeraldLight: Color { Color.emeraldLight }
    static var emeraldDeep: Color { Color.emeraldDeep }
    static var charcoal: Color { Color.charcoal }
    static var warningAmber: Color { Color.warningAmber }
    static var alertCoral: Color { Color.alertCoral }
    static var slateGray: Color { Color.slateGray }
    static var textPrimary: Color { Color.textPrimary }
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary: Color { Color.textTertiary }
}

/// Full-bleed dark emerald backdrop — every screen sits on this instead of a system background.
struct AppBackdrop: View {
    var body: some View {
        LinearGradient.appBackdrop.ignoresSafeArea()
    }
}
extension View {
    /// Applies the standard dark emerald screen backdrop behind a scrollable/static screen body.
    func appBackground() -> some View {
        background(AppBackdrop())
    }
}

/// Soft blurred glow shape for decorative depth behind hero cards — no image assets needed,
/// just a blurred gradient circle. Use sparingly (1-2 per screen) behind a card's leading/trailing edge.
struct GlowBlob: View {
    var color: Color = .emerald
    var size: CGFloat = 180
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.35)
            .opacity(0.35)
            .allowsHitTesting(false)
    }
}

/// Triangular flag pennant shape used by GolfFlagGraphic.
private struct FlagPennant: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.42))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.84))
        path.closeSubpath()
        return path
    }
}

/// Small custom-drawn golf flag-on-green graphic — pole, pennant, green mound, and a ball —
/// used as a decorative motif instead of a single flat SF Symbol watermark. No image assets.
struct GolfFlagGraphic: View {
    var size: CGFloat = 90
    var body: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(colors: [Color.emerald.opacity(0.4), Color.emeraldDeep.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 1.3, height: size * 0.32)
                .offset(y: size * 0.42)

            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 0.04, height: size * 0.82)
                .offset(y: -size * 0.04)

            FlagPennant()
                .fill(LinearGradient.emerald)
                .frame(width: size * 0.46, height: size * 0.3)
                .offset(x: size * 0.23, y: -size * 0.34)
                .shadow(color: Color.emerald.opacity(0.5), radius: 6, x: 0, y: 2)

            Circle()
                .fill(
                    RadialGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.5)], center: .topLeading, startRadius: 0, endRadius: size * 0.16)
                )
                .frame(width: size * 0.14, height: size * 0.14)
                .offset(x: -size * 0.34, y: size * 0.33)
        }
        .frame(width: size, height: size)
    }
}

/// Layered gradient icon badge — replaces flat single-tone "circle + SF Symbol" treatment
/// with a richer, more dimensional look (gradient fill, ring, soft glow shadow).
struct IconBadge: View {
    let icon: String
    var color: Color = .emerald
    var size: CGFloat = 40
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [color.opacity(0.4), color.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(color.opacity(0.45), lineWidth: 1)
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let xOffset: CGFloat
    let yOffset: CGFloat
    let rotation: Double
    let delay: Double
    let size: CGFloat
}

/// Confetti burst used by RoundCompleteOverlay — a one-shot particle effect, not a reusable
/// animation loop. Generates randomized pieces on appear and animates them outward/down/fading.
private struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var animated = false
    private static let colors: [Color] = [.emerald, .emeraldLight, .warningAmber, .white]

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.4)
                    .rotationEffect(.degrees(animated ? piece.rotation : 0))
                    .offset(x: animated ? piece.xOffset : 0, y: animated ? piece.yOffset : 0)
                    .opacity(animated ? 0 : 1)
                    .animation(.easeOut(duration: 1.1).delay(piece.delay), value: animated)
            }
        }
        .onAppear {
            pieces = (0..<24).map { _ in
                ConfettiPiece(
                    color: Self.colors.randomElement() ?? .emerald,
                    xOffset: CGFloat.random(in: -160...160),
                    yOffset: CGFloat.random(in: -80...260),
                    rotation: Double.random(in: -540...540),
                    delay: Double.random(in: 0...0.15),
                    size: CGFloat.random(in: 6...11)
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { animated = true }
        }
    }
}

/// Full-screen celebration shown briefly when a round is completed — checkmark burst, confetti,
/// and a success haptic. Designed to cover the transition into Round Summary, then fade away.
struct RoundCompleteOverlay: View {
    @State private var checkScale: CGFloat = 0.3
    @State private var checkOpacity: Double = 0
    @State private var fired = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            ConfettiView()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.emerald)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.emerald.opacity(0.6), radius: 24, x: 0, y: 0)
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.black)
                }
                .scaleEffect(checkScale)
                .opacity(checkOpacity)

                Text("Round Complete!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .opacity(checkOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkScale = 1
                checkOpacity = 1
            }
            fired = true
        }
        .sensoryFeedback(.success, trigger: fired)
    }
}

/// Circular ring progress indicator (Apple-Activity-style) — used in place of flat ProgressView
/// bars wherever a single completion fraction is the headline metric.
struct RingProgress<Content: View>: View {
    var progress: Double
    var lineWidth: CGFloat = 7
    var size: CGFloat = 60
    var color: Color = .emerald
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0.001), 1))
                .stroke(
                    AngularGradient(colors: [color.opacity(0.45), color], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            content
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.4), value: progress)
    }
}

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    var raised: Bool = false
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(raised ? Color.cardFillRaised : Color.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.emerald.opacity(0.10), radius: 18, x: 0, y: 10)
            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 6)
    }
}
extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 20, raised: Bool = false) -> some View {
        modifier(CardBackground(padding: padding, cornerRadius: cornerRadius, raised: raised))
    }
}

/// Small rounded tag used for skill level, goals, and hole-count badges.
struct Pill: View {
    let text: String
    var color: Color = .emerald
    var filled: Bool = false
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(filled ? color.opacity(0.9) : color.opacity(0.16), in: Capsule())
            .foregroundStyle(filled ? Color.black : color)
            .overlay(Capsule().strokeBorder(color.opacity(filled ? 0 : 0.35), lineWidth: 1))
    }
}

/// Circular score-relative-to-par indicator. Emerald marks an under-par (good) score, matching
/// the app's brand accent and standard green-is-good UI convention; warm tones signal "needs work."
/// Pops in with a spring on appear and rolls its digits in via CountUpNumber.
struct ScoreBadge: View {
    let scoreToPar: Int
    var size: CGFloat = 44
    @State private var appeared = false

    var body: some View {
        Circle()
            .fill(color.opacity(0.16))
            .overlay(Circle().strokeBorder(color, lineWidth: 1.5))
            .frame(width: size, height: size)
            .overlay(
                CountUpNumber(value: scoreToPar, font: .system(size: size * 0.32, weight: .bold, design: .rounded), color: color, formatter: scoreToParText)
                    .minimumScaleFactor(0.7)
            )
            .scaleEffect(appeared ? 1 : 0.4)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { appeared = true }
            }
    }

    private var color: Color {
        switch scoreToPar {
        case ..<0: return .emerald
        case 0: return .textPrimary
        case 1...4: return .warningAmber
        default: return .alertCoral
        }
    }
}

func scoreToParText(_ value: Int) -> String {
    if value == 0 { return "E" }
    return value > 0 ? "+\(value)" : "\(value)"
}

/// Animated number that rolls its digits in via the iOS 17 numeric text transition instead of
/// just appearing — used anywhere a headline number is the focal point of a screen.
struct CountUpNumber: View {
    let value: Int
    var font: Font = .title2.weight(.bold)
    var color: Color = .textPrimary
    var formatter: (Int) -> String = { "\($0)" }
    @State private var displayed: Int = 0

    var body: some View {
        Text(formatter(displayed))
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) { displayed = value }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) { displayed = newValue }
            }
    }
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
                    .foregroundStyle(.emerald)
                    .frame(width: 30, height: 30)
                    .background(Color.emerald.opacity(0.14), in: Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.textSecondary)
                    .tracking(0.6)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(.textPrimary)
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
                    Text(label).foregroundStyle(.textPrimary)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .emerald : Color.white.opacity(0.25))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(isSelected ? Color.emerald.opacity(0.14) : Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.emerald.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.bouncy)
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
            .foregroundStyle(.textPrimary)
            .tint(.emerald)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

/// Label/value row used throughout summary, history, stats, and club detail screens.
struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = .textPrimary
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(valueColor)
        }
    }
}

/// Compact metric tile for dashboard-style grids (Round Summary, Stats, Club Stats).
struct MetricTile: View {
    let title: String
    let value: String
    var icon: String? = nil
    var tint: Color = .emerald
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 6) {
            if let icon {
                Image(systemName: icon).font(.subheadline).foregroundStyle(tint)
            }
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
                .contentTransition(.numericText())
            Text(title).font(.caption).foregroundStyle(.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle(padding: 8, cornerRadius: 14)
        .scaleEffect(appeared ? 1 : 0.7)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appeared = true }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = .emerald
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.black)
            .background(gradient.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.emerald.opacity(0.35), radius: 14, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: configuration.isPressed)
            .sensoryFeedback(trigger: configuration.isPressed) { _, isPressed in
                isPressed ? .impact(weight: .medium) : nil
            }
    }
}
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryGolf: PrimaryButtonStyle { PrimaryButtonStyle() }
}

/// Generic spring-bounce press feedback for card taps, nav links, and icon buttons —
/// makes every tap in the app feel physically responsive instead of just changing state.
struct BouncyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .sensoryFeedback(trigger: configuration.isPressed) { _, isPressed in
                isPressed ? .impact(weight: .light) : nil
            }
    }
}
extension ButtonStyle where Self == BouncyButtonStyle {
    static var bouncy: BouncyButtonStyle { BouncyButtonStyle() }
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
                        LinearGradient.emerald
                    } else {
                        Color.white.opacity(0.07)
                    }
                }
                .foregroundStyle(isSelected ? .black : .textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.bouncy)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// Big +/- counter used for strokes/putts/penalties — fast to tap mid-round, no keyboard.
struct BigStepperBox: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...20
    @State private var bump = false

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.caption.weight(.medium)).foregroundStyle(.textSecondary)
            HStack(spacing: 10) {
                Button { step(-1) } label: {
                    Image(systemName: "minus.circle.fill").font(.title2)
                }
                .buttonStyle(.bouncy)
                Text("\(value)")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundStyle(.textPrimary)
                    .frame(minWidth: 30)
                    .scaleEffect(bump ? 1.25 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.4), value: bump)
                Button { step(1) } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
                .buttonStyle(.bouncy)
            }
            .foregroundStyle(.emerald)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle(padding: 8, cornerRadius: 14)
    }

    private func step(_ delta: Int) {
        value = min(range.upperBound, max(range.lowerBound, value + delta))
        bump = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { bump = false }
    }
}

/// Horizontally scrollable row of chips for picking one case of a DisplayNamed enum —
/// used for club pickers and other longer option lists during fast hole entry.
struct ChipScrollRow<T: DisplayNamed>: View {
    let items: [T]
    let selected: T?
    let allowsDeselect: Bool
    let onSelect: (T?) -> Void

    init(items: [T], selected: T?, allowsDeselect: Bool = true, onSelect: @escaping (T?) -> Void) {
        self.items = items
        self.selected = selected
        self.allowsDeselect = allowsDeselect
        self.onSelect = onSelect
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    ChoiceChip(label: item.displayName, isSelected: selected == item) {
                        if allowsDeselect && selected == item {
                            onSelect(nil)
                        } else {
                            onSelect(item)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

/// Collapsible section for secondary fields — keeps the main hole-entry screen fast,
/// with deeper club-tracking detail tucked away until tapped.
struct ExpandableSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                        if let subtitle {
                            Text(subtitle).font(.caption).foregroundStyle(.textSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.bouncy)

            if isExpanded {
                content
            }
        }
        .cardStyle()
    }
}
