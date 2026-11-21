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

    static func == (lhs: Quest, rhs: Quest) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// "About 30 min", rounded to the nearest 5 minutes.
    var walkingTime: String {
        let rounded = max(5, Int((Double(walkingMinutes) / 5).rounded()) * 5)
        return "About \(rounded) min"
    }

    /// "1.5 mi" (or kilometers where the phone uses them).
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
                id: "ellen-eccles",
                name: "Ellen Eccles Theatre",
                address: "43 S Main St",
                latitude: 41.73060,
                longitude: -111.83544,
                question: "Practice question: whose name is on this theatre?",
                acceptedAnswers: ["Ellen Eccles"]
            ),
            Stop(
                id: "merlin-olsen-park",
                name: "Merlin Olsen Park",
                address: "300 E Center St",
                latitude: 41.73037,
                longitude: -111.82860,
                question: "Practice question: whose name is on this park?",
                acceptedAnswers: ["Merlin Olsen"]
            ),
        ],
        // Tools/walk_time.swift "Logan Tabernacle" "Cache Valley Visitors Bureau" "Umbrella Alley Logan" "Ellen Eccles Theatre" "Merlin Olsen Park"
        walkingMinutes: 32,
        walkingMeters: 2443
    )
}
