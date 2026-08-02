// ⚠️ UNVERIFIED-ON-DEVICE: authored off-Mac; needs Xcode compile + device test.
// Tool layer (doc 04 §7): thin adapters over system frameworks. Each is defined
// once here and bridged to FoundationModels' `Tool` protocol in AFMToolBridge
// (M3) so both backends share these implementations.
// All tools are confirm-by-default in v1: they PREPARE, the user commits.
import Foundation
import EventKit
import MapKit
import SaturdayCore

enum SaturdayToolError: Error {
    case permissionDenied
    case notAvailable
    case badArguments
}

// MARK: - Calendar (permission ladder: EventKitUI sheet needs no permission;
// write-only for silent adds; full access only for reads — doc 03 A1)

struct CalendarTool {
    static let spec = ToolSpec(
        name: "create_event",
        description: "Prepare a calendar event for the user to confirm.",
        parameters: [
            .init(name: "title", type: "string", required: true, description: "Event title"),
            .init(name: "start_iso8601", type: "string", required: true, description: "Start time, ISO8601"),
            .init(name: "duration_minutes", type: "number", required: false, description: "Default 60"),
            .init(name: "notes", type: "string", required: false, description: "Notes")
        ])

    /// Returns a pre-filled event for `EKEventEditViewController` (zero-permission
    /// out-of-process confirm sheet — the assistant default).
    func prepareEvent(from call: ToolCall, store: EKEventStore) throws -> EKEvent {
        guard let title = call.arguments["title"]?.stringValue,
              let startText = call.arguments["start_iso8601"]?.stringValue,
              let start = ISO8601DateFormatter().date(from: startText) else {
            throw SaturdayToolError.badArguments
        }
        let minutes = call.arguments["duration_minutes"]?.numberValue ?? 60
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = start.addingTimeInterval(minutes * 60)
        event.notes = call.arguments["notes"]?.stringValue
        return event
    }
}

// MARK: - Reminders (full reminders access required — no write-only tier exists)

struct RemindersTool {
    static let spec = ToolSpec(
        name: "create_reminder",
        description: "Create a reminder for the user to confirm.",
        parameters: [
            .init(name: "title", type: "string", required: true, description: "Reminder text"),
            .init(name: "due_iso8601", type: "string", required: false, description: "Due date, ISO8601")
        ])

    func execute(_ call: ToolCall, store: EKEventStore) async throws -> String {
        guard let title = call.arguments["title"]?.stringValue else {
            throw SaturdayToolError.badArguments
        }
        let granted = try await store.requestFullAccessToReminders()
        guard granted else { throw SaturdayToolError.permissionDenied }
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = store.defaultCalendarForNewReminders()
        if let dueText = call.arguments["due_iso8601"]?.stringValue,
           let due = ISO8601DateFormatter().date(from: dueText) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: due)
        }
        try store.save(reminder, commit: true)
        return "Reminder created: \(title)"
    }
}

// MARK: - Nearby places (MKLocalSearch — no API key, no billing)

struct PlacesTool {
    static let spec = ToolSpec(
        name: "find_places",
        description: "Find nearby places matching a natural-language query.",
        parameters: [
            .init(name: "query", type: "string", required: true, description: "e.g. 'sushi open now'")
        ])

    func execute(_ call: ToolCall, near region: MKCoordinateRegion) async throws -> [MKMapItem] {
        guard let query = call.arguments["query"]?.stringValue else {
            throw SaturdayToolError.badArguments
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        let response = try await MKLocalSearch(request: request).start()
        return Array(response.mapItems.prefix(5))
    }
}

// MARK: - Web lookup (doc 06 §8a — opt-in; only the composed query leaves the device)

struct WebLookupTool {
    static let spec = ToolSpec(
        name: "web_lookup",
        description: "Search the web for a fact. Use only when the conversation doesn't contain the answer.",
        parameters: [
            .init(name: "query", type: "string", required: true, description: "Minimal search terms — never transcript text")
        ])

    var isEnabled: Bool // user opt-in toggle

    func execute(_ call: ToolCall) async throws -> [DDGParser.SearchResult] {
        guard isEnabled else { throw SaturdayToolError.notAvailable }
        guard let query = call.arguments["query"]?.stringValue,
              var components = URLComponents(string: "https://html.duckduckgo.com/html") else {
            throw SaturdayToolError.badArguments
        }
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        var request = URLRequest(url: components.url!)
        request.setValue("Mozilla/5.0 (iPhone) Saturday/1.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        let html = String(decoding: data, as: UTF8.self)
        var results = DDGParser.parse(html: html)
        if results.isEmpty {
            // Fallback endpoint (dual-endpoint strategy, doc 06 §8a).
            var lite = URLComponents(string: "https://lite.duckduckgo.com/lite")!
            lite.queryItems = [URLQueryItem(name: "q", value: query)]
            let (liteData, _) = try await URLSession.shared.data(from: lite.url!)
            results = DDGParser.parse(html: String(decoding: liteData, as: UTF8.self))
        }
        return results
    }
}

// MARK: - Message draft: handled at the UI layer with MFMessageComposeViewController
// (user must tap send; not available on watchOS — watch hands off to phone).
// Spec kept here so the model can request it.

enum MessageDraftTool {
    static let spec = ToolSpec(
        name: "draft_message",
        description: "Prepare a text message draft the user can review and send.",
        parameters: [
            .init(name: "recipient", type: "string", required: false, description: "Contact name if mentioned"),
            .init(name: "body", type: "string", required: true, description: "Message text")
        ])
}

enum AllTools {
    static let specs: [ToolSpec] = [
        CalendarTool.spec, RemindersTool.spec, PlacesTool.spec,
        WebLookupTool.spec, MessageDraftTool.spec
    ]
}
