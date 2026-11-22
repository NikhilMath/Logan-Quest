import SwiftUI

/// A prize-box coupon, drawn like the pitch coupon in Partners: a navy ticket with a
/// gift-box stub, the business, the offer, and when it runs out. Everything scales with `width`.
struct CouponView: View {
    let coupon: Coupon
    let quest: Quest
    var width: CGFloat
    var now: Date = .now

    /// Height as a share of width.
    static let aspect: CGFloat = 0.58

    var body: some View {
        let w = width, h = width * Self.aspect
        let stub = w * 0.28, notch = w * 0.023
        let expired = coupon.isExpired(at: now)
        HStack(spacing: 0) {
            stubSide(w: w)
                .frame(width: stub)
            mainSide(w: w, expired: expired)
                .padding(.horizontal, w * 0.05)
                .padding(.vertical, w * 0.045)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(width: w, height: h)
        .background(LinearGradient(colors: [.questNavy, .questNavyDark], startPoint: .top, endPoint: .bottom))
        .overlay {
            RoundedRectangle(cornerRadius: w * 0.02, style: .continuous)
                .strokeBorder(Color.questGold.opacity(0.45), lineWidth: max(1, w * 0.002))
                .padding(w * 0.011)
        }
        .overlay {
            // Where the stub tears off.
            Path { path in
                path.move(to: CGPoint(x: stub, y: notch + w * 0.012))
                path.addLine(to: CGPoint(x: stub, y: h - notch - w * 0.012))
            }
            .stroke(Color.questCream.opacity(0.35), style: StrokeStyle(lineWidth: max(1, w * 0.003), lineCap: .round, dash: [w * 0.011, w * 0.009]))
        }
        .clipShape(TicketShape(stub: stub, notch: notch, corner: w * 0.028))
        .saturation(expired ? 0 : 1)
        .shadow(color: .black.opacity(0.4), radius: w * 0.03, y: w * 0.015)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(coupon.spokenDescription(at: now))
    }

    private func stubSide(w: CGFloat) -> some View {
        VStack(spacing: w * 0.03) {
            PrizeBox(size: w * 0.16)
            VStack(spacing: w * 0.008) {
                Text("QUEST REWARD")
                    .font(.system(size: w * 0.026, weight: .heavy, design: .rounded))
                    .tracking(w * 0.004)
                    .foregroundStyle(Color.questGold)
                    .lineLimit(1)
                Text("\(quest.title) quest")
                    .font(.system(size: w * 0.025, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.questCream.opacity(0.65))
                    .lineLimit(2)
            }
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, w * 0.02)
    }

    private func mainSide(w: CGFloat, expired: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LOGAN QUESTS")
                .font(.system(size: w * 0.028, weight: .heavy, design: .rounded))
                .tracking(w * 0.004)
                .foregroundStyle(Color.questGold)
            Text(coupon.business)
                .font(.system(size: w * 0.115, weight: .black, design: .rounded))
                .foregroundStyle(Color.questCream)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            Spacer(minLength: w * 0.015)

            Text(coupon.offer)
                .font(.system(size: w * 0.048, weight: .black, design: .rounded))
                .foregroundStyle(Color.questGoldLight)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, w * 0.03)
                .padding(.vertical, w * 0.022)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: w * 0.018, style: .continuous).fill(Color.questGold.opacity(0.13)))
                .overlay(
                    RoundedRectangle(cornerRadius: w * 0.018, style: .continuous)
                        .strokeBorder(Color.questGold, style: StrokeStyle(lineWidth: max(1, w * 0.003), dash: [w * 0.012, w * 0.008]))
                )

            Spacer(minLength: w * 0.015)

            Rectangle()
                .fill(Color.questCream.opacity(0.25))
                .frame(height: max(0.5, w * 0.0015))
            let ends = Text("\(expired ? "EXPIRED" : "EXPIRES") \(coupon.lastDayText.uppercased())")
                .font(.system(size: w * 0.028, weight: .heavy, design: .rounded))
                .tracking(w * 0.003)
                .foregroundStyle(Color.questGold)
            let terms = Text(coupon.terms)
                .font(.system(size: w * 0.026, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.questCream.opacity(0.65))
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    ends
                    Spacer(minLength: w * 0.02)
                    terms
                }
                VStack(alignment: .leading, spacing: w * 0.006) {
                    ends
                    terms
                }
            }
            .lineLimit(1)
            .padding(.top, w * 0.022)
        }
    }
}

/// A rounded card with a notch top and bottom where the stub tears off.
private struct TicketShape: Shape {
    var stub: CGFloat
    var notch: CGFloat
    var corner: CGFloat

    func path(in rect: CGRect) -> Path {
        let card = Path(roundedRect: rect, cornerRadius: corner, style: .continuous)
        var notches = Path()
        for y in [rect.minY, rect.maxY] {
            notches.addEllipse(in: CGRect(x: rect.minX + stub - notch, y: y - notch, width: notch * 2, height: notch * 2))
        }
        return card.subtracting(notches)
    }
}

extension Coupon {
    /// What VoiceOver reads for the coupon.
    func spokenDescription(at date: Date = .now) -> String {
        "\(business) coupon. \(offer). \(isExpired(at: date) ? "Expired after" : "Good through") \(lastDayText). \(terms)."
    }
}

#Preview {
    VStack(spacing: 24) {
        if let coupon = Quest.downtownLogan.prize.coupon {
            CouponView(coupon: coupon, quest: .downtownLogan, width: 353)
            CouponView(coupon: coupon, quest: .downtownLogan, width: 353, now: .distantFuture)
        }
    }
    .padding()
    .background(Color.questNavyDark)
}
