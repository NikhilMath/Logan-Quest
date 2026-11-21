import MapKit

/// A scavenger hunt: a set of stops to find. Add new quests to `Quest.all`.
/// A quest's `id` and its stops' `id`s are how progress is saved, so never change them once shipped.
struct Quest: Identifiable, Hashable {
    let id: String
    let title: String
    let area: String
    let summary: String
    let stops: [Stop]

    static func == (lhs: Quest, rhs: Quest) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

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
        summary: "Three landmarks along Main Street.",
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
                id: "ellen-eccles",
                name: "Ellen Eccles Theatre",
                address: "43 S Main St",
                latitude: 41.73060,
                longitude: -111.83544,
                question: "Practice question: whose name is on this theatre?",
                acceptedAnswers: ["Ellen Eccles"]
            ),
        ]
    )
}
