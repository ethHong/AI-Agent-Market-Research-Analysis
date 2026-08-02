import XCTest
@testable import SaturdayCore

final class HotphraseDetectorTests: XCTestCase {
    func testDetectsPhraseAndExtractsQuery() {
        var detector = HotphraseDetector()
        let detection = detector.scan("Hey Saturday what did she say about the deadline", sessionTime: 100)
        XCTAssertNotNil(detection)
        XCTAssertEqual(detection?.trailingQuery, "what did she say about the deadline")
    }

    func testDetectsWithASRPunctuation() {
        var detector = HotphraseDetector()
        let detection = detector.scan("Hey, Saturday — what's the number?", sessionTime: 100)
        // "hey saturday" normalizes past the punctuation.
        XCTAssertNotNil(detection)
        XCTAssertEqual(detection?.trailingQuery, "whats the number")
    }

    func testCooldownSuppressesRepeats() {
        var detector = HotphraseDetector(config: .init(cooldown: 5))
        XCTAssertNotNil(detector.scan("hey saturday first question", sessionTime: 10))
        XCTAssertNil(detector.scan("hey saturday second question", sessionTime: 12))
        XCTAssertNotNil(detector.scan("hey saturday third question", sessionTime: 20))
    }

    func testBareSaturdayAsDateDoesNotTrigger() {
        var detector = HotphraseDetector() // default phrases: "hey saturday", "saturday,"
        // "saturday," normalizes to "saturday" — so a bare mention DOES match the
        // single-word phrase. This documents why the wake phrase ships as an
        // off-by-default beta (doc 06 decision 1): with the default config the
        // date-collision is real.
        let detection = detector.scan("let's meet on saturday afternoon", sessionTime: 50)
        XCTAssertNotNil(detection)

        // The safer two-word-only config avoids it:
        var strict = HotphraseDetector(config: .init(phrases: ["hey saturday"], cooldown: 5))
        XCTAssertNil(strict.scan("let's meet on saturday afternoon", sessionTime: 50))
        XCTAssertNotNil(strict.scan("hey saturday add that to my calendar", sessionTime: 60))
    }

    func testNoPhraseNoDetection() {
        var detector = HotphraseDetector()
        XCTAssertNil(detector.scan("we should ship in october", sessionTime: 10))
        XCTAssertNil(detector.scan("", sessionTime: 11))
    }
}
