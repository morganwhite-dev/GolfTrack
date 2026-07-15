import SwiftUI
import SwiftData
import Foundation

struct RootView: View {
    @Query(sort: \UserProfile.createdDate) private var profiles: [UserProfile]
    @AppStorage("activeProfileID") private var activeProfileIDString: String = ""
    @State private var isShowingStartScreen = true
    @State private var didScheduleStartScreen = false

    private var activeProfile: UserProfile? {
        if let id = UUID(uuidString: activeProfileIDString), let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.first
    }

    var body: some View {
        ZStack {
            destination
                .opacity(isShowingStartScreen ? 0 : 1)

            if isShowingStartScreen {
                GolfTrackStartScreen()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard !didScheduleStartScreen else { return }
            didScheduleStartScreen = true
            try? await Task.sleep(nanoseconds: 2_750_000_000)
            withAnimation(.easeInOut(duration: 0.45)) {
                isShowingStartScreen = false
            }
        }
    }

    @ViewBuilder
    private var destination: some View {
        if let profile = activeProfile {
            MainTabView(profile: profile)
                .onAppear {
                    if activeProfileIDString != profile.id.uuidString {
                        activeProfileIDString = profile.id.uuidString
                    }
                }
        } else {
            ProfileSetupView()
        }
    }
}

private struct GolfTrackStartScreen: View {
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            LinearGradient.appBackdrop
                .ignoresSafeArea()

            VStack(spacing: 34) {
                VStack(spacing: 8) {
                    Text("GolfTrack")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(0)

                    Capsule()
                        .fill(LinearGradient.emerald)
                        .frame(width: glowPulse ? 132 : 96, height: 4)
                        .shadow(color: Color.emerald.opacity(glowPulse ? 0.7 : 0.35), radius: glowPulse ? 18 : 8)
                }

                RoundlySplashMark()
                    .frame(width: 270, height: 230)
            }
            .padding(.bottom, 18)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

private struct RoundlySplashMark: View {
    @State private var drawRing = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let size = min(width, height)
            let center = CGPoint(x: width * 0.50, y: height * 0.50)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.emerald.opacity(0.28), Color.clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: size * 0.55
                        )
                    )
                    .frame(width: size, height: size)
                    .position(center)

                Circle()
                    .trim(from: 0.05, to: drawRing ? 0.95 : 0.05)
                    .stroke(
                        LinearGradient.emerald,
                        style: StrokeStyle(lineWidth: size * 0.034, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-100))
                    .frame(width: size * 0.78, height: size * 0.78)
                    .position(center)
                    .shadow(color: Color.emerald.opacity(0.45), radius: 16)

                ForEach(ringDots(width: width, height: height), id: \.x) { point in
                    Circle()
                        .fill(Color.emerald)
                        .frame(width: size * 0.080, height: size * 0.080)
                        .position(point)
                        .shadow(color: Color.emerald.opacity(0.45), radius: 10)
                }

                fairwayShape(width: width, height: height)
                    .fill(LinearGradient.emerald)
                    .shadow(color: Color.emerald.opacity(0.45), radius: 12)

                fairwayCutout(width: width, height: height)
                    .stroke(Color.black.opacity(0.62), style: StrokeStyle(lineWidth: size * 0.070, lineCap: .round))

                Circle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: size * 0.17, height: size * 0.055)
                    .position(x: width * 0.50, y: height * 0.62)

                Capsule()
                    .fill(LinearGradient.emerald)
                    .frame(width: size * 0.035, height: size * 0.36)
                    .position(x: width * 0.50, y: height * 0.45)
                    .shadow(color: Color.emerald.opacity(0.45), radius: 12)

                flag(width: width, height: height)
                    .fill(LinearGradient.emerald)
                    .shadow(color: Color.emerald.opacity(0.45), radius: 14)

                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.emerald.opacity(0.75), radius: 14)
                    .position(x: width * 0.50, y: height * 0.16)
            }
        }
        .onAppear {
            drawRing = false
            withAnimation(.easeOut(duration: 1.10).delay(0.12)) {
                drawRing = true
            }
        }
    }

    private func fairwayShape(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: width * 0.28, y: height * 0.67))
        path.addCurve(
            to: CGPoint(x: width * 0.77, y: height * 0.63),
            control1: CGPoint(x: width * 0.44, y: height * 0.49),
            control2: CGPoint(x: width * 0.58, y: height * 0.57)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.61, y: height * 0.83),
            control1: CGPoint(x: width * 0.71, y: height * 0.76),
            control2: CGPoint(x: width * 0.66, y: height * 0.83)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.32, y: height * 0.71),
            control1: CGPoint(x: width * 0.48, y: height * 0.77),
            control2: CGPoint(x: width * 0.40, y: height * 0.68)
        )
        path.closeSubpath()
        return path
    }

    private func fairwayCutout(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: width * 0.31, y: height * 0.66))
        path.addCurve(
            to: CGPoint(x: width * 0.56, y: height * 0.69),
            control1: CGPoint(x: width * 0.43, y: height * 0.56),
            control2: CGPoint(x: width * 0.53, y: height * 0.58)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.45, y: height * 0.79),
            control1: CGPoint(x: width * 0.58, y: height * 0.76),
            control2: CGPoint(x: width * 0.52, y: height * 0.80)
        )
        return path
    }

    private func flag(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: width * 0.51, y: height * 0.30))
        path.addLine(to: CGPoint(x: width * 0.72, y: height * 0.38))
        path.addLine(to: CGPoint(x: width * 0.51, y: height * 0.48))
        path.closeSubpath()
        return path
    }

    private func ringDots(width: CGFloat, height: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: width * 0.20, y: height * 0.52),
            CGPoint(x: width * 0.50, y: height * 0.85),
            CGPoint(x: width * 0.82, y: height * 0.52)
        ]
    }
}
