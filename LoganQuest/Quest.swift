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

    /// The routes players can walk now, easiest first: every route that isn't coming soon.
    var openRoutes: [Route] { routes.filter { !$0.isComingSoon } }

    /// The route for a difficulty, or the easiest open one if the quest doesn't have that
    /// difficulty or it's coming soon.
    func route(_ difficulty: Difficulty?) -> Route {
        openRoutes.first { $0.difficulty == difficulty } ?? openRoutes.first ?? routes[0]
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
    /// Shows "Coming soon" in the difficulty picker and can't be played: its map, stops and
    /// prize box stay hidden, and everywhere else uses the easiest open route instead. Delete
    /// it from the route to open it. Never set it on a quest's first route.
    var isComingSoon = false

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
                summary: "Six stops in a loop that starts and ends at the Logan Tabernacle.",
                stops: [.tabernacle, .courthouse, .luckySlice, .centerStreet, .thatcherYoung, .ellenEccles],
                // Tools/walk_time.swift "Logan Tabernacle" "Cache Valley Visitors Bureau" "Lucky Slice Logan" "36 W Center St, Logan, UT" "Thatcher Young Mansion" "Ellen Eccles Theatre"
                walkingMinutes: 18,
                walkingMeters: 1394
            ),
            Route(
                difficulty: .medium,
                summary: "Ten stops in a loop that starts and ends at the Logan Tabernacle.",
                stops: [
                    .tabernacle, .stJohns, .pioneerMuseum, .library, .courthouse,
                    .luckySlice, .centerStreet, .caineLyric, .thatcherYoung, .ellenEccles,
                ],
                // Tools/walk_time.swift "Logan Tabernacle" "St. John's Episcopal Church Logan" "Cache Pioneer Museum" "Logan Library" "Cache Valley Visitors Bureau" "Lucky Slice Logan" "36 W Center St, Logan, UT" "Caine Lyric Theatre" "Thatcher Young Mansion" "Ellen Eccles Theatre"
                walkingMinutes: 29,
                walkingMeters: 2132,
                // Nikhil, 2026-11-25: Medium and Hard say "Coming soon" until they're ready.
                isComingSoon: true
            ),
            Route(
                difficulty: .hard,
                summary: "Sixteen stops in a loop that starts and ends at the Logan Tabernacle.",
                stops: [
                    .tabernacle, .pioneerMuseum, .courthouse, .library, .cityHall,
                    .presbyterianChurch, .luckySlice, .centerStreet, .caineLyric, .utahTheatre,
                    .thatcherYoung, .ellenEccles, .pioneerPark, .merlinOlsenPark, .temple, .stJohns,
                ],
                // Tools/walk_time.swift "Logan Tabernacle" "Cache Pioneer Museum" "Cache Valley Visitors Bureau" "Logan Library" "Logan City Hall" "First Presbyterian Church Logan" "Lucky Slice Logan" "36 W Center St, Logan, UT" "Caine Lyric Theatre" "Utah Theatre Logan" "Thatcher Young Mansion" "Ellen Eccles Theatre" "Pioneer Park Logan" "Merlin Olsen Central Park" "Logan Utah Temple" "St. John's Episcopal Church Logan"
                walkingMinutes: 72,
                walkingMeters: 5283,
                isComingSoon: true
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
        // A real question (Nikhil, 2026-11-25).
        question: "How many kids did David Eccles have with Ellen Eccles?",
        acceptedAnswers: ["9", "nine"]
    )

    static let luckySlice = Stop(
        id: "lucky-slice-mural",
        name: "Lucky Slice Mural",
        address: "37 W Center St",
        latitude: 41.73154,
        longitude: -111.83601,
        // A real question (Nikhil, 2026-11-25).
        question: "How many people are depicted in the mural?",
        acceptedAnswers: ["5", "five"]
    )

    // Replaced Umbrella Alley (id "umbrella-alley", never reuse it) on 2026-11-25: its umbrellas
    // come down for the winter. Nikhil says the Center Street sign is right north of The Owl
    // (36 W Center St, 41.73126, -111.83607 in Apple Maps), so the pin is just north of it.
    static let centerStreet = Stop(
        id: "center-street",
        name: "Center Street",
        address: "36 W Center St",
        latitude: 41.73138,
        longitude: -111.83607,
        // A real question (Nikhil, 2026-11-25).
        question: "What year did the Center Street revitalization happen?",
        acceptedAnswers: ["2019"]
    )

    static let thatcherYoung = Stop(
        id: "thatcher-young",
        name: "Thatcher-Young Mansion",
        address: "35 W 100 S",
        latitude: 41.73039,
        longitude: -111.83597,
        // A real question (Nikhil, 2026-11-25).
        question: "What was Logan High originally named?",
        acceptedAnswers: ["Brigham Young College", "BYC"]
    )

    static let ellenEccles = Stop(
        id: "ellen-eccles",
        name: "Ellen Eccles Theatre",
        address: "43 S Main St",
        latitude: 41.73060,
        longitude: -111.83544,
        // A real question (Nikhil, 2026-11-25): the lights in the ceiling of the covered entrance.
        question: "How many recessed lights are in the ceiling over the front entrance?",
        acceptedAnswers: ["8", "eight"]
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
