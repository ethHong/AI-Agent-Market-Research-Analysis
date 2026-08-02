import Foundation

/// Parser for DuckDuckGo's keyless HTML endpoints (doc 06 §8a).
///
/// DELIBERATELY BRITTLE-BY-DESIGN NOTE: these endpoints are unofficial; the
/// markup can change and break this parser. That risk is why it lives here as
/// an isolated, heavily-tested pure function — patch the regexes, re-run the
/// fixture tests, ship an app update. Both endpoints are parsed so they can
/// act as fallbacks for each other:
///   - html.duckduckgo.com/html?q=…   (`result__a` / `result__snippet` classes)
///   - lite.duckduckgo.com/lite?q=…   (plain `<a rel="nofollow">` table rows)
public enum DDGParser {
    public struct SearchResult: Equatable, Sendable {
        public let title: String
        public let url: URL
        public let snippet: String
    }

    public static func parse(html: String, limit: Int = 5) -> [SearchResult] {
        let results = parseHTMLEndpoint(html)
        if !results.isEmpty { return Array(results.prefix(limit)) }
        return Array(parseLiteEndpoint(html).prefix(limit))
    }

    // MARK: html.duckduckgo.com

    static func parseHTMLEndpoint(_ html: String) -> [SearchResult] {
        let linkPattern = #"<a[^>]*class="[^"]*result__a[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>"#
        let snippetPattern = #"class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</a>|class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</(?:div|span|td)>"#

        let links = captures(in: html, pattern: linkPattern)
        let snippets = captures(in: html, pattern: snippetPattern)

        var results: [SearchResult] = []
        for (index, link) in links.enumerated() {
            guard link.count >= 2,
                  let url = resolveURL(link[0]) else { continue }
            let title = stripTags(link[1])
            let snippet = index < snippets.count
                ? stripTags(snippets[index].first(where: { !$0.isEmpty }) ?? "")
                : ""
            guard !title.isEmpty else { continue }
            results.append(SearchResult(title: title, url: url, snippet: snippet))
        }
        return results
    }

    // MARK: lite.duckduckgo.com

    static func parseLiteEndpoint(_ html: String) -> [SearchResult] {
        let linkPattern = #"<a[^>]*rel="nofollow"[^>]*href="([^"]+)"[^>]*>(.*?)</a>"#
        let snippetPattern = #"<td[^>]*class="[^"]*result-snippet[^"]*"[^>]*>(.*?)</td>"#

        let links = captures(in: html, pattern: linkPattern)
        let snippets = captures(in: html, pattern: snippetPattern)

        var results: [SearchResult] = []
        for (index, link) in links.enumerated() {
            guard link.count >= 2,
                  let url = resolveURL(link[0]) else { continue }
            let title = stripTags(link[1])
            let snippet = index < snippets.count ? stripTags(snippets[index][0]) : ""
            guard !title.isEmpty else { continue }
            results.append(SearchResult(title: title, url: url, snippet: snippet))
        }
        return results
    }

    // MARK: helpers

    /// DDG wraps result URLs as `//duckduckgo.com/l/?uddg=<encoded>&…` — unwrap.
    static func resolveURL(_ raw: String) -> URL? {
        let unescaped = htmlUnescape(raw)
        if let components = URLComponents(string: unescaped.hasPrefix("//") ? "https:" + unescaped : unescaped),
           components.path.hasPrefix("/l/"),
           let encoded = components.queryItems?.first(where: { $0.name == "uddg" })?.value,
           let url = URL(string: encoded) {
            return url
        }
        if unescaped.hasPrefix("//") { return URL(string: "https:" + unescaped) }
        guard unescaped.hasPrefix("http") else { return nil }
        return URL(string: unescaped)
    }

    static func captures(in text: String, pattern: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).map { match in
            (1..<match.numberOfRanges).compactMap { groupIndex in
                guard let range = Range(match.range(at: groupIndex), in: text) else { return "" }
                return String(text[range])
            }
        }
    }

    static func stripTags(_ html: String) -> String {
        let withoutTags = html.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        return htmlUnescape(withoutTags).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func htmlUnescape(_ text: String) -> String {
        var result = text
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#x27;", "'"), ("&#39;", "'"), ("&nbsp;", " ")
        ]
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        return result
    }
}
