import SwiftUI

/// The quest's prize box. It stays locked until every stop is found; then a tap sends the lid
/// flying and the prize rises out. The spinning rays and ticking clock show it's live, not a screenshot.
struct PrizeView: View {
    let quest: Quest
    let route: Route

    @Environment(ProgressStore.self) private var progress
    @Environment(AccountStore.self) private var account
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOpen = false
    @State private var lockedTaps = 0

    private let boxSize: CGFloat = 200

    var body: some View {
        let unlocked = progress.isComplete(route, in: quest)
        ZStack {
            LinearGradient(colors: [.questNavy, .questNavyDark], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Centered, but scrolls if a small screen or big text needs it.
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 28) {
                        stage(unlocked: unlocked, width: geometry.size.width - 40)
                        caption(unlocked: unlocked)
                        if let finished = progress.finishedAt(route, in: quest) {
                            proof(finishedAt: finished)
                                .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                    .padding(.top, 40) // clear of the close button
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .foregroundStyle(Color.questCream)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.questCream)
            }
            .accessibilityLabel("Close")
            .padding()
        }
        .sensoryFeedback(.success, trigger: isOpen) { _, open in open }
        .sensoryFeedback(.error, trigger: lockedTaps)
        #if DEBUG
        .task {
            guard DebugScreen.current == "prizeOpen", unlocked else { return }
            try? await Task.sleep(for: .seconds(1))
            withAnimation(.spring(duration: 0.8, bounce: 0.35)) { isOpen = true }
        }
        #endif
    }

    /// The box, and the prize that rises out of it.
    private func stage(unlocked: Bool, width: CGFloat) -> some View {
        let s = boxSize
        let coupon = quest.prize.coupon
        let couponWidth = min(width, 400)
        let couponHeight = couponWidth * CouponView.aspect
        // Once a coupon is out, the empty box shrinks to make room for it.
        let openBoxScale: CGFloat = coupon == nil ? 1 : 0.6
        // Where the prize comes to rest, measured up from the bottom of the box.
        let prizeBottom = coupon == nil ? s * 0.5 : s * 0.5 * openBoxScale + 12
        let prizeMiddle = coupon == nil ? s * 0.95 : prizeBottom + couponHeight / 2
        let openHeight = coupon == nil ? s * 1.3 : prizeBottom + couponHeight + 8
        // The glow sits behind the box until it opens, then spreads behind the prize.
        let raysSize = coupon == nil ? s * 1.5 : couponWidth * 1.3
        let glowSize = isOpen ? raysSize : s * 1.5
        return Button {
            if !unlocked {
                lockedTaps += 1
            } else if !isOpen {
                withAnimation(.spring(duration: 0.8, bounce: 0.35)) { isOpen = true }
            }
        } label: {
            ZStack(alignment: .bottom) {
                Circle()
                    .fill(RadialGradient(colors: [Color.questGold.opacity(0.45), .clear], center: .center, startRadius: 0, endRadius: glowSize / 2))
                    .frame(width: glowSize, height: glowSize)
                    .offset(y: glowSize / 2 - (isOpen ? prizeMiddle : s * 0.45))
                    .opacity(unlocked ? 1 : 0)

                if isOpen {
                    PrizeRays(spinning: !reduceMotion)
                        .frame(width: raysSize, height: raysSize)
                        .offset(y: raysSize / 2 - prizeMiddle)
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                }

                // Starts small and hidden inside the box, behind its front.
                switch quest.prize.item {
                case .coupon(let coupon):
                    CouponView(coupon: coupon, quest: quest, width: couponWidth)
                        .scaleEffect(isOpen ? 1 : 0.2, anchor: .bottom)
                        .offset(y: isOpen ? -prizeBottom : -s * 0.1)
                        .opacity(isOpen ? 1 : 0)
                case .badge(let symbol):
                    Image(systemName: symbol)
                        .font(.system(size: s * 0.46))
                        .foregroundStyle(LinearGradient(colors: [.questGoldLight, .questGold], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        .scaleEffect(isOpen ? 1 : 0.5, anchor: .bottom)
                        .offset(y: isOpen ? -s * 0.56 : -s * 0.06)
                        .opacity(isOpen ? 1 : 0)
                }

                PrizeBox(size: s, isLocked: !unlocked, lidOff: isOpen)
                    .modifier(Wiggle(active: unlocked && !isOpen && !reduceMotion))
                    .keyframeAnimator(initialValue: 0.0, trigger: lockedTaps) { content, x in
                        content.offset(x: x)
                    } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(-12, duration: 0.06)
                            CubicKeyframe(12, duration: 0.08)
                            CubicKeyframe(-8, duration: 0.08)
                            CubicKeyframe(6, duration: 0.07)
                            CubicKeyframe(0, duration: 0.06)
                        }
                    }
                    .scaleEffect(isOpen ? openBoxScale : 1, anchor: .bottom)
            }
            .frame(width: max(s * 1.5, coupon == nil ? 0 : couponWidth), height: isOpen ? openHeight : s * 1.3, alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOpen ? coupon?.spokenDescription() ?? quest.prize.title : unlocked ? "Open the prize box" : "Prize box, locked")
    }

    private var prizeDetail: String {
        if let coupon = quest.prize.coupon, coupon.isExpired() {
            return "This coupon ran out after \(coupon.lastDayText)."
        }
        return quest.prize.detail
    }

    @ViewBuilder
    private func caption(unlocked: Bool) -> some View {
        VStack(spacing: 10) {
            if isOpen {
                Text(quest.prize.title)
                    .font(.largeTitle.bold())
                Text(prizeDetail)
                    .font(.title3)
            } else if unlocked {
                Text("Prize box unlocked!")
                    .font(.largeTitle.bold())
                Text("Tap the box to open it.")
                    .font(.title3)
            } else {
                let left = route.stops.count - progress.foundCount(on: route, in: quest)
                Text("Prize box")
                    .font(.largeTitle.bold())
                Text("Find ^[\(left) more stop](inflect: true) to open it.")
                    .font(.title3)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 420)
    }

    private func proof(finishedAt: Date) -> some View {
        VStack(spacing: 4) {
            Text("\(account.name ?? "You") finished \(quest.title)\(quest.hasDifficulties ? " on \(route.difficulty.title)" : "")")
            Text(finishedAt.formatted(date: .abbreviated, time: .shortened))
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text("It's \(context.date.formatted(date: .omitted, time: .standard))")
                    .monospacedDigit()
            }
        }
        .font(.subheadline.weight(.semibold))
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.questCream.opacity(0.7))
    }
}

/// A gift box in the app icon's gold and cream. `lidOff` sends the lid flying.
struct PrizeBox: View {
    var size: CGFloat
    var isLocked = false
    var lidOff = false

    var body: some View {
        let s = size
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: s * 0.05, style: .continuous)
                .fill(LinearGradient(colors: [.questGold, .questGoldDark], startPoint: .top, endPoint: .bottom))
                .overlay { Rectangle().fill(Color.questCream).frame(width: s * 0.14) }
                .overlay(alignment: .top) { Rectangle().fill(.black.opacity(0.2)).frame(height: s * 0.04) }
                .clipShape(RoundedRectangle(cornerRadius: s * 0.05, style: .continuous))
                .overlay {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: s * 0.15, weight: .bold))
                            .foregroundStyle(Color.questNavy)
                            .frame(width: s * 0.3, height: s * 0.3)
                            .background(Circle().fill(Color.questCream))
                            .overlay(Circle().strokeBorder(Color.questNavy.opacity(0.25), lineWidth: max(1, s * 0.015)))
                    }
                }
                .frame(width: s * 0.8, height: s * 0.5)

            VStack(spacing: -s * 0.035) {
                bow
                RoundedRectangle(cornerRadius: s * 0.04, style: .continuous)
                    .fill(LinearGradient(colors: [.questGoldLight, .questGold], startPoint: .top, endPoint: .bottom))
                    .overlay { Rectangle().fill(Color.questCream).frame(width: s * 0.14) }
                    .clipShape(RoundedRectangle(cornerRadius: s * 0.04, style: .continuous))
                    .frame(width: s * 0.9, height: s * 0.16)
            }
            .offset(y: -s * 0.49)
            .rotationEffect(.degrees(lidOff ? 30 : 0), anchor: .bottomTrailing)
            .offset(x: lidOff ? s * 0.5 : 0, y: lidOff ? -s * 0.6 : 0)
            .opacity(lidOff ? 0 : 1)
        }
        .frame(width: s, height: s * 0.86, alignment: .bottom)
        .saturation(isLocked ? 0 : 1)
        .accessibilityHidden(true)
    }

    private var bow: some View {
        let s = size
        return ZStack(alignment: .bottom) {
            ForEach([-1.0, 1.0], id: \.self) { side in
                Ellipse()
                    .fill(Color.questCream)
                    .overlay(
                        Ellipse()
                            .fill(Color.questGoldDark.opacity(0.35))
                            .frame(width: s * 0.1, height: s * 0.045)
                    )
                    .frame(width: s * 0.24, height: s * 0.13)
                    .rotationEffect(.degrees(side * -28))
                    .offset(x: side * s * 0.1, y: -s * 0.045)
            }
            Capsule()
                .fill(Color.questCream)
                .frame(width: s * 0.11, height: s * 0.08)
        }
        .frame(width: s * 0.5, height: s * 0.2, alignment: .bottom)
    }
}

/// Gold rays that spin slowly behind the prize.
private struct PrizeRays: View {
    var spinning: Bool

    var body: some View {
        TimelineView(.animation(paused: !spinning)) { context in
            let degrees = spinning ? (context.date.timeIntervalSinceReferenceDate * 15).truncatingRemainder(dividingBy: 360) : 0
            Canvas { gc, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2
                let count = 14
                for i in 0..<count {
                    let start = Angle.degrees(Double(i) / Double(count) * 360)
                    var wedge = Path()
                    wedge.move(to: center)
                    wedge.addArc(center: center, radius: radius, startAngle: start, endAngle: start + .degrees(360 / Double(count) / 2), clockwise: false)
                    wedge.closeSubpath()
                    gc.fill(wedge, with: .color(Color.questGold.opacity(0.22)))
                }
            }
            .rotationEffect(.degrees(degrees))
            .mask(EllipticalGradient(colors: [.white, .clear]))
        }
        .accessibilityHidden(true)
    }
}

/// Every so often, the box gives a little shake to say "open me".
private struct Wiggle: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.keyframeAnimator(initialValue: 0.0, repeating: true) { content, angle in
                content.rotationEffect(.degrees(angle), anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0, duration: 1.4)
                    CubicKeyframe(-6, duration: 0.09)
                    CubicKeyframe(6, duration: 0.12)
                    CubicKeyframe(-5, duration: 0.12)
                    CubicKeyframe(4, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                }
            }
        } else {
            content
        }
    }
}

/// The app icon's colors.
extension Color {
    static let questNavy = Color(red: 22 / 255, green: 56 / 255, blue: 88 / 255)
    static let questNavyDark = Color(red: 8 / 255, green: 26 / 255, blue: 44 / 255)
    static let questGold = Color(red: 247 / 255, green: 189 / 255, blue: 52 / 255)
    static let questGoldLight = Color(red: 255 / 255, green: 216 / 255, blue: 110 / 255)
    static let questGoldDark = Color(red: 214 / 255, green: 148 / 255, blue: 22 / 255)
    static let questCream = Color(red: 251 / 255, green: 243 / 255, blue: 226 / 255)
}

#Preview {
    PrizeView(quest: .downtownLogan, route: Quest.downtownLogan.routes[0])
        .environment(ProgressStore())
        .environment(AccountStore())
}
