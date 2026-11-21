// Looks up places near downtown Logan in Apple Maps and times walking a loop through them,
// back to the first place. Use it to pick a quest's stops and fill in its walkingMinutes and
// walkingMeters in LoganQuest/Quest.swift.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift Tools/walk_time.swift \
//     "Logan Tabernacle" "Cache Valley Visitors Bureau" "Umbrella Alley Logan"
//
// Times are Apple Maps walking estimates (a little under 3 mph), the same ones the app's
// Walking Directions button opens.
import MapKit

let names = Array(CommandLine.arguments.dropFirst())
guard names.count >= 2 else {
    print("Give at least two places, in walking order.")
    exit(1)
}

let logan = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 41.7335, longitude: -111.8320),
    span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.08)
)

var items: [MKMapItem] = []
for name in names {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = name
    request.region = logan
    guard let item = try await MKLocalSearch(request: request).start().mapItems.first else {
        print("Couldn't find \(name)")
        exit(1)
    }
    items.append(item)
    let c = item.location.coordinate
    print(String(format: "%@: %@, %.5f, %.5f", name, item.address?.shortAddress ?? "no address", c.latitude, c.longitude))
}

print("")
var seconds = 0.0, meters = 0.0
for (from, to) in zip(items, items.dropFirst() + [items[0]]) {
    let request = MKDirections.Request()
    request.source = from
    request.destination = to
    request.transportType = .walking
    guard let route = try await MKDirections(request: request).calculate().routes.first else {
        print("No walking route from \(from.name ?? "?") to \(to.name ?? "?")")
        exit(1)
    }
    seconds += route.expectedTravelTime
    meters += route.distance
    print(String(format: "%@ → %@: %.1f min, %.0f m", from.name ?? "?", to.name ?? "?", route.expectedTravelTime / 60, route.distance))
    try await Task.sleep(for: .milliseconds(500))  // Apple Maps limits how fast you can ask
}
print(String(format: "\nWhole loop: %.0f min, %.0f m (%.2f mi)", seconds / 60, meters, meters / 1609.344))
print(String(format: "For Quest.swift: walkingMinutes: %.0f, walkingMeters: %.0f", (seconds / 60).rounded(), meters.rounded()))
