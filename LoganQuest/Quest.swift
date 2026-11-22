import MapKit

/// A scavenger hunt: a set of stops to find. Add new quests to `Quest.all`.
/// A quest's `id` and its stops' `id`s are how progress is saved, so never change them once shipped.
struct Quest: Identifiable, Hashable {
    let id: String
    let title: String
    let area: String
    let summary: String
    /// In walking order. The walk is a loop: after the last stop, players head back to the first.
    let stops: [Stop]
    /// Walking the whole loop, back to the first stop, per Apple Maps walking directions.
    /// Measure with `Tools/walk_time.swift` whenever the stops change.
    let walkingMinutes: Int
    let walkingMeters: Double
    /// What's in the prize box, which opens once every stop is found.
    let prize: Prize

    static func == (lhs: Quest, rhs: Quest) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// "About 20 min", rounded to the nearest 5 minutes.
    var walkingTime: String {
        let rounded = max(5, Int((Double(walkingMinutes) / 5).rounded()) * 5)
        return "About \(rounded) min"
    }

    /// "0.9 mi" (or kilometers where the phone uses them).
    var walkingDistance: String {
        Measurement(value: walkingMeters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road, numberFormatStyle: .number.precision(.fractionLength(1))))
    }

    /// The map area that shows every stop, with a little room around the edges.
    var region: MKCoordinateRegion {
        let lats = stops.map(\.latitude), lons = stops.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return MKCoordinateRegion()
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.7, 0.005),
                longitudeDelta: max((maxLon - minLon) * 1.7, 0.005)
            )
        )
    }
}

/// What's inside a quest's prize box.
struct Prize: Hashable {
    let title: String
    let detail: String
    let item: Item

    enum Item: Hashable {
        /// An SF Symbol, drawn in gold as it rises out of the box.
        case badge(symbol: String)
        /// A coupon from a Logan business, shown at its counter.
        case coupon(Coupon)
    }

    var coupon: Coupon? {
        if case .coupon(let coupon) = item { coupon } else { nil }
    }
}

/// A coupon from a business. It's good through the end of its last day, Logan time.
struct Coupon: Hashable {
    let business: String
    /// What finishers get. Only put in an offer the business has agreed to.
    let offer: String
    let terms: String
    /// Midnight at the start of the last day it's good, in Logan.
    let lastDay: Date

    init(business: String, offer: String, terms: String, goodThrough day: DateComponents) {
        self.business = business
        self.offer = offer
        self.terms = terms
        lastDay = Coupon.logan.date(from: day)!
    }

    /// Logan keeps Mountain Time.
    static let logan: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver")!
        return calendar
    }()

    func isExpired(at date: Date = .now) -> Bool {
        date >= Coupon.logan.date(byAdding: .day, value: 1, to: lastDay)!
    }

    /// "Dec 31, 2026"
    var lastDayText: String {
        lastDay.formatted(Date.FormatStyle(timeZone: Coupon.logan.timeZone).month(.abbreviated).day().year())
    }
}

extension Quest {
    static let all: [Quest] = [.downtownLogan]

    // The questions below are PRACTICE placeholders so the unlock flow can be tested.
    // Replace each one with a real question and answer from the downtown walk
    // (something only someone standing there would know, like what's carved on a plaque).
    static let downtownLogan = Quest(
        id: "downtown-logan",
        title: "Downtown Logan",
        area: "Logan, Utah",
        summary: "Five stops in a loop that starts and ends at the Logan Tabernacle.",
        stops: [
            Stop(
                id: "tabernacle",
                name: "Logan Tabernacle",
                address: "50 N Main St",
                latitude: 41.73235,
                longitude: -111.83423,
                question: "Practice question: what's this building called?",
                acceptedAnswers: ["Logan Tabernacle", "Tabernacle"]
            ),
            Stop(
                id: "courthouse",
                name: "Old Cache County Courthouse",
                address: "199 N Main St",
                latitude: 41.73479,
                longitude: -111.83567,
                question: "Practice question: this was the courthouse for which county?",
                acceptedAnswers: ["Cache", "Cache County"]
            ),
            Stop(
                id: "umbrella-alley",
                name: "Umbrella Alley",
                address: "73 W Center St",
                latitude: 41.73155,
                longitude: -111.83687,
                question: "Practice question: what hangs over this alley?",
                acceptedAnswers: ["Umbrellas", "Umbrella"]
            ),
            Stop(
                id: "thatcher-young",
                name: "Thatcher-Young Mansion",
                address: "35 W 100 S",
                latitude: 41.73039,
                longitude: -111.83597,
                question: "Practice question: what's this house called?",
                acceptedAnswers: ["Thatcher-Young Mansion", "Thatcher-Young"]
            ),
            Stop(
                id: "ellen-eccles",
                name: "Ellen Eccles Theatre",
                address: "43 S Main St",
                latitude: 41.73060,
                longitude: -111.83544,
                question: "Practice question: whose name is on this theatre?",
                acceptedAnswers: ["Ellen Eccles"]
            ),
        ],
        // Tools/walk_time.swift "Logan Tabernacle" "Cache Valley Visitors Bureau" "Umbrella Alley Logan" "Thatcher Young Mansion" "Ellen Eccles Theatre"
        walkingMinutes: 18,
        walkingMeters: 1412,
        // A generic coupon for pitching to Logan businesses. Once one signs on, put in its
        // name and the agreed offer (and `terms`, if they change). The pitch coupon in
        // Partners shows the same thing, so keep the two matching.
        prize: Prize(
            title: "Local business coupon",
            detail: "Show this screen at the counter. The ticking clock shows it's not a screenshot.",
            item: .coupon(Coupon(
                business: "Your Business",
                offer: "Your offer here",
                terms: "One per player",
                goodThrough: DateComponents(year: 2026, month: 12, day: 31)
            ))
        )
    )
}
