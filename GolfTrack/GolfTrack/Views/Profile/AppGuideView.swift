import SwiftUI

struct AppGuideView: View {
    var body: some View {
        VStack(spacing: 0) {
            PushedScreenHeader("Guide")
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 18) {
                    hero
                    featureSection
                    workflowSection
                    scoringSection
                    adviceSection
                    privacySection
                }
                .padding()
            }
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(icon: "flag.fill", color: .emerald, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("GolfTrack")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.textPrimary)
                    Text("Score fast. Add context. Practice with a purpose.")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
            }

            Text("GolfTrack is built for everyday golfers who want less friction during the round and clearer feedback afterward. Fast log captures the score; your notes and details explain why it happened.")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle(raised: true)
    }

    private var featureSection: some View {
        guideSection(title: "Core Features", icon: "sparkles") {
            guideRow(icon: "lock.fill", title: "Lock Screen Scoring", text: "Start a round, lock your iPhone, then log strokes and putts from the Live Activity.")
            guideRow(icon: "house.fill", title: "Pause to Home", text: "During a round, tap the house button to save your place and return Home without ending the round.")
            guideRow(icon: "person.2.fill", title: "Player Switching", text: "During a round, tap Players to pause your scorecard, switch profiles, and let another golfer score or resume their own round.")
            guideRow(icon: "person.crop.circle.fill", title: "Home Profile Switcher", text: "Tap the profile pill on Home to switch golfers before a round or jump straight into another profile's active scorecard.")
            guideRow(icon: "figure.golf", title: "Hole-by-Hole Tracking", text: "Track strokes, putts, penalties, tee result, contact quality, clubs, and notes.")
            guideRow(icon: "list.bullet.clipboard.fill", title: "Detail Cleanup", text: "After the summary, review holes that could use more detail while the round is still fresh.")
            guideRow(icon: "checkmark.circle.fill", title: "Today's Focus", text: "Home turns your current focus into one quick action, whether it is contact, putting, mental game, tee shots, or course management.")
            guideRow(icon: "sparkles", title: "What Mattered", text: "The summary highlights the biggest pattern from the round, including penalties, three-putts, misses, or note themes.")
            guideRow(icon: "target", title: "Strokes to Save", text: "The summary estimates the fastest scoring opportunities from penalties, three-putts, blow-up holes, and recurring misses.")
            guideRow(icon: "flag.checkered", title: "Course Memory", text: "After you play a course more than once, summaries compare holes against your own history there.")
            guideRow(icon: "lightbulb.fill", title: "Round Insights", text: "Advice uses stats, reflections, mental notes, and per-hole notes to explain strengths and weak spots.")
            guideRow(icon: "checklist", title: "Practice Plans", text: "Your round becomes a focused drill list based on what you tracked and what you wrote.")
            guideRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Trends", text: "Home, Stats, and History show recent form, goal progress, and patterns over time.")
        }
    }

    private var workflowSection: some View {
        guideSection(title: "Best Workflow", icon: "arrow.triangle.2.circlepath") {
            numberedRow("1", title: "Create your profile", text: "Pick your skill level and goals so advice fits your game.")
            numberedRow("2", title: "Start a round", text: "Choose a course, target score, and holes to play.")
            numberedRow("3", title: "Use Lock Screen scoring", text: "Tap stroke or putt controls without breaking rhythm.")
            numberedRow("4", title: "Pause or switch players", text: "Use the house button to return Home, or Players to save your place and hand the phone to another local profile.")
            numberedRow("5", title: "Review details", text: "After the summary, add anything you remember: misses, clubs, penalties, contact, or notes.")
            numberedRow("6", title: "Reflect after the round", text: "Answer quick questions about what felt good, frustrating, or fixable.")
            numberedRow("7", title: "Complete the practice plan", text: "Check off drills before your next round.")
        }
    }

    private var scoringSection: some View {
        guideSection(title: "Scoring Tips", icon: "number.circle.fill") {
            guideRow(icon: "plus.circle.fill", title: "Stroke +", text: "Use this for a regular stroke that is not specifically a putt.")
            guideRow(icon: "smallcircle.filled.circle", title: "Putt +", text: "Adjusts the putt count only. Use Stroke + for the hole's stroke total.")
            guideRow(icon: "bolt.fill", title: "Fast Log", text: "Lock Screen scoring records stroke totals, putt counts, and hole changes. Open the app for clubs, misses, penalties, notes, and full shot details.")
            guideRow(icon: "target", title: "Target Score", text: "Set a target before the round to unlock pace signals and coach nudges.")
            guideRow(icon: "checkmark.circle.fill", title: "Final Hole", text: "On the last hole, the Live Activity chevron becomes a checkmark to finish the round.")
        }
    }

    private var adviceSection: some View {
        guideSection(title: "How Advice Works", icon: "brain.head.profile") {
            guideRow(icon: "text.bubble.fill", title: "Your Words Matter", text: "Per-hole notes, mental mistake notes, and reflection answers are scanned for golf themes like putting, wedges, contact, driver, distance, or focus.")
            guideRow(icon: "flag.checkered", title: "Hole Context", text: "If your notes mention issues on specific holes, advice can point back to those holes instead of staying generic.")
            guideRow(icon: "map.fill", title: "Course History", text: "When you return to a course, GolfTrack can highlight your usual score, common miss, and whether today's hole beat or missed your norm.")
            guideRow(icon: "wrench.and.screwdriver.fill", title: "Drills Follow The Evidence", text: "Practice plans combine score stats with what you wrote, so a note about rushed tee shots can lead to routine or driver work.")
        }
    }

    private var privacySection: some View {
        guideSection(title: "Data & Privacy", icon: "lock.shield.fill") {
            guideRow(icon: "iphone", title: "Local Profiles", text: "Profiles are local to this device. Each profile has its own rounds, stats, and plans.")
            guideRow(icon: "trash", title: "Delete One Round", text: "History has a visible trash button, swipe-to-delete, and a delete button inside Round Detail.")
            guideRow(icon: "trash.fill", title: "Clear Round Data", text: "Profile settings include a clear-data option for rounds, stats, and practice plans.")
            guideRow(icon: "location.fill", title: "Location", text: "Location is only used to help find nearby golf courses when you ask for it.")
        }
    }

    private func guideSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, icon: icon)
            content()
        }
        .cardStyle()
    }

    private func guideRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            IconBadge(icon: icon, color: .emerald, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textPrimary)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    private func numberedRow(_ number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(LinearGradient.emerald, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textPrimary)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}
