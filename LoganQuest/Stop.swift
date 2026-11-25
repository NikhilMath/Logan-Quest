import CoreLocation
import Foundation

/// One place on a quest. Players unlock it by solving a riddle whose answer only someone standing there would know.
struct Stop: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    /// What the player has to solve. Its answer is something only someone standing there would know.
    let riddle: String
    /// Any of these unlocks the stop. Matching ignores case, punctuation, accents and a leading "the".
    let acceptedAnswers: [String]
    /// Shown under the riddle only when the player taps Show Hint: the riddle asked as a plain
    /// question. Leave it out for no hint.
    var hint: String? = nil

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Opens Apple Maps with walking directions to the stop.
    var directionsURL: URL {
        URL(string: "https://maps.apple.com/?daddr=\(latitude),\(longitude)&dirflg=w")!
    }

    /// Whether the answer unlocks the stop: one of its accepted answers, or the test code
    /// ("Nikhil") in a build where that works.
    @MainActor func unlocks(with answer: String) -> Bool {
        accepts(answer) || TestUnlock.accepts(answer)
    }

    func accepts(_ answer: String) -> Bool {
        let given = Stop.normalize(answer)
        return !given.isEmpty && acceptedAnswers.contains { Stop.normalize($0) == given }
    }

    static func normalize(_ text: String) -> String {
        let folded = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US"))
            .lowercased()
        let kept = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        var words = String(kept).split(separator: " ").map(String.init)
        if words.first == "the", words.count > 1 { words.removeFirst() }
        return words.joined(separator: " ")
    }
}
