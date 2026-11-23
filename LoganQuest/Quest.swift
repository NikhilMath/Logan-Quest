import MapKit

/// A scavenger hunt: a set of stops to find, walked as a loop. Add new quests to `Quest.all`.
/// A quest's `id` and its stops' `id`s are how progress is saved, so never change them once shipped.
struct Quest: Identifiable, Hashable {
    let id: String
    let title: String
    let area: String
    /// Ways to walk the quest, easiest first. With more than one, players pick a difficulty.
    /// Routes share stops: a stop found on one route counts on every route that has it.
    let routes: [Route]
    /// What's in the prize box, which opens once every stop on the chosen route is found.
    let prize: Prize
    /// An SF Symbol for the quest's badges, one for finishing each route. Players keep badges
    /// even after resetting their progress.
    let badgeSymbol: String

    static func == (lhs: Quest, rhs: Quest) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var hasDifficulties: Bool { routes.count > 1 }

    /// The route for a difficulty, or the easiest one if the quest doesn't have that difficulty.
    func route(_ difficulty: Difficulty?) -> Route {
        routes.first { $0.difficulty == difficulty } ?? routes[0]
    }

    /// Every stop on any route, each once: the easiest route's stops first, then each harder
    /// route's additions.
    var allStops: [Stop] {
        var seen = Set<String>()
        return routes.flatMap(\.stops).filter { seen.insert($0.id).inserted }
    }

    /// The difficulties whose routes include the stop, easiest first.
    func difficulties(with stop: Stop) -> [Difficulty] {
        routes.filter { $0.stops.contains(stop) }.map(\.difficulty)
    }

    /// Where this iPhone keeps the difficulty last picked for the quest (`@AppStorage`).
    /// It isn't synced to iCloud; the stops found are.
    var difficultyKey: String { "difficulty.\(id)" }
}

/// How many stops a quest asks for. Each harder route keeps the easier one's stops and adds more.
/// The raw values are part of how badges are saved, so never change them.
enum Difficulty: String, CaseIterable, Identifiable {
    case easy, medium, hard

    var id: Self { self }

    /// "Medium"
    var title: String { rawValue.capitalized }
}

/// One way to walk a quest: its stops and how long the loop takes.
struct Route: Identifiable, Hashable {
    let difficulty: Difficulty
    let summary: String
    /// In walking order. The walk is a loop: after the last stop, players head back to the first.
    let stops: [Stop]
    /// Walking the whole loop, back to the first stop, per Apple Maps walking directions.
    /// Measure with `Tools/walk_time.swift` whenever the stops change.
    let walkingMinutes: Int
    let walkingMeters: Double

    var id: Difficulty { difficulty }

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

    static let downtownLogan = Quest(
        id: "downtown-logan",
        title: "Downtown Logan",
        area: "Logan, Utah",
        routes: [
            Route(
                difficulty: .easy,
                summary: "Five stops in a loop that starts and ends at the Logan Tabernacle.",
                stops: [.tabernacle, .courthouse, .umbrellaAlley, .thatcherYoung, .ellenEccles],
                // Tools/walk_time.swift "Logan Tabernacle" "Cache Valley Visitors Bureau" "Umbrella Alley Logan" "Thatcher Young Mansion" "Ellen Eccles Theatre"
                walkingMinutes: 18,
                walkingMeters: 1412
            ),
            Route(
                difficulty: .medium,
                summary: "Nine stops in a loop that starts and ends at the Logan Tabernacle.",
                stops: [
                    .tabernacle, .stJohns, .pioneerMuseum, .library, .courthouse,
                    .umbrellaAlley, .caineLyric, .thatcherYoung, .ellenEccles,
                ],
                // Tools/walk_time.swift "Logan Tabernacle" "St. John's Episcopal Church Logan" "Cache Pioneer Museum" "Logan Library" "Cache Valley Visitors Bureau" "Umbrella Alley Logan" "Caine Lyric Theatre" "Thatcher Young Mansion" "Ellen Eccles Theatre"
                walkingMinutes: 30,
                walkingMeters: 2225
            ),
            Route(
                difficulty: .hard,
                summary: "Fifteen stops in a loop that starts and ends at the Logan Tabernacle.",
                stops: [
                    .tabernacle, .pioneerMuseum, .courthouse, .library, .cityHall,
                    .presbyterianChurch, .umbrellaAlley, .caineLyric, .utahTheatre, .thatcherYoung,
                    .ellenEccles, .pioneerPark, .merlinOlsenPark, .temple, .stJohns,
                ],
                // Tools/walk_time.swift "Logan Tabernacle" "Cache Pioneer Museum" "Cache Valley Visitors Bureau" "Logan Library" "Logan City Hall" "First Presbyterian Church Logan" "Umbrella Alley Logan" "Caine Lyric Theatre" "Utah Theatre Logan" "Thatcher Young Mansion" "Ellen Eccles Theatre" "Pioneer Park Logan" "Merlin Olsen Central Park" "Logan Utah Temple" "St. John's Episcopal Church Logan"
                walkingMinutes: 72,
                walkingMeters: 5257
            ),
        ],
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
        ),
        badgeSymbol: "building.columns.fill"
    )
}

// Downtown Logan's stops. Addresses and coordinates are from Apple Maps.
// The questions are PRACTICE placeholders so the unlock flow can be tested.
// Replace each one with a real question and answer from the downtown walk
// (something only someone standing there would know, like what's carved on a plaque).
private extension Stop {
    // Easy, and every route after it.

    static let tabernacle = Stop(
        id: "tabernacle",
        name: "Logan Tabernacle",
        address: "50 N Main St",
        latitude: 41.73235,
        longitude: -111.83423,
        // A real question (Nikhil, 2026-11-22): the Tabernacle was finished in 1891.
        question: "What year was this building erected?",
        acceptedAnswers: ["1891"]
    )

    static let courthouse = Stop(
        id: "courthouse",
        name: "Old Cache County Courthouse",
        address: "199 N Main St",
        latitude: 41.73479,
        longitude: -111.83567,
        question: "Practice question: this was the courthouse for which county?",
        acceptedAnswers: ["Cache", "Cache County"]
    )

    static let umbrellaAlley = Stop(
        id: "umbrella-alley",
        name: "Umbrella Alley",
        address: "73 W Center St",
        latitude: 41.73155,
        longitude: -111.83687,
        question: "Practice question: what hangs over this alley?",
        acceptedAnswers: ["Umbrellas", "Umbrella"]
    )

    static let thatcherYoung = Stop(
        id: "thatcher-young",
        name: "Thatcher-Young Mansion",
        address: "35 W 100 S",
        latitude: 41.73039,
        longitude: -111.83597,
        question: "Practice question: what's this house called?",
        acceptedAnswers: ["Thatcher-Young Mansion", "Thatcher-Young"]
    )

    static let ellenEccles = Stop(
        id: "ellen-eccles",
        name: "Ellen Eccles Theatre",
        address: "43 S Main St",
        latitude: 41.73060,
        longitude: -111.83544,
        question: "Practice question: whose name is on this theatre?",
        acceptedAnswers: ["Ellen Eccles"]
    )

    // Added on Medium, and Hard.

    static let stJohns = Stop(
        id: "st-johns",
        name: "St. John's Episcopal Church",
        address: "85 E 100 N",
        latitude: 41.73354,
        longitude: -111.83279,
        question: "Practice question: which saint is this church named for?",
        acceptedAnswers: ["St. John", "Saint John", "St. John's", "Saint John's", "John"]
    )

    static let pioneerMuseum = Stop(
        id: "pioneer-museum",
        name: "Cache Pioneer Museum",
        address: "160 N Main St",
        latitude: 41.73439,
        longitude: -111.83441,
        question: "Practice question: what's this museum called?",
        acceptedAnswers: ["Cache Pioneer Museum", "Pioneer Museum", "Cache Pioneer"]
    )

    static let library = Stop(
        id: "library",
        name: "Logan Library",
        address: "285 N Main St",
        latitude: 41.73641,
        longitude: -111.83530,
        question: "Practice question: what kind of building is this?",
        acceptedAnswers: ["Library", "Logan Library", "Public library"]
    )

    static let caineLyric = Stop(
        id: "caine-lyric",
        name: "Caine Lyric Theatre",
        address: "28 W Center St",
        latitude: 41.73129,
        longitude: -111.83590,
        question: "Practice question: what's this theatre called?",
        acceptedAnswers: ["Caine Lyric Theatre", "Caine Lyric Theater", "Caine Lyric", "Lyric Theatre", "Lyric Theater", "Lyric"]
    )

    // Added on Hard.

    static let cityHall = Stop(
        id: "city-hall",
        name: "Logan City Hall",
        address: "290 N 100 W",
        latitude: 41.73684,
        longitude: -111.83691,
        question: "Practice question: this is the city hall for which city?",
        acceptedAnswers: ["Logan", "Logan City"]
    )

    static let presbyterianChurch = Stop(
        id: "presbyterian-church",
        name: "First Presbyterian Church",
        address: "178 W Center St",
        latitude: 41.73110,
        longitude: -111.83980,
        question: "Practice question: what kind of church is this?",
        acceptedAnswers: ["Presbyterian", "First Presbyterian", "Presbyterian Church", "First Presbyterian Church"]
    )

    static let utahTheatre = Stop(
        id: "utah-theatre",
        name: "Utah Theatre",
        address: "18 W Center St",
        latitude: 41.73115,
        longitude: -111.83560,
        question: "Practice question: which state is this theatre named for?",
        acceptedAnswers: ["Utah"]
    )

    static let pioneerPark = Stop(
        id: "pioneer-park",
        name: "Pioneer Park",
        // Apple Maps has no street address for the park, only its walkway.
        address: "Pioneer Park Walkway",
        latitude: 41.73006,
        longitude: -111.83071,
        question: "Practice question: what's this park called?",
        acceptedAnswers: ["Pioneer Park", "Pioneer"]
    )

    static let merlinOlsenPark = Stop(
        id: "merlin-olsen-park",
        name: "Merlin Olsen Park",
        address: "300 E Center St",
        latitude: 41.73037,
        longitude: -111.82860,
        question: "Practice question: whose name is on this park?",
        acceptedAnswers: ["Merlin Olsen", "Olsen"]
    )

    static let temple = Stop(
        id: "temple",
        name: "Logan Utah Temple",
        address: "175 N 300 E",
        latitude: 41.73445,
        longitude: -111.82802,
        question: "Practice question: what's this building called?",
        acceptedAnswers: ["Logan Utah Temple", "Logan Temple", "Temple"]
    )
}
