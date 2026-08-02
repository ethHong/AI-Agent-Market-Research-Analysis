import XCTest
@testable import SaturdayCore

/// Fixtures are REPRESENTATIVE of the two DDG endpoints' markup shapes (built
/// from public descriptions of the endpoints, not captured live). Before
/// shipping M3, capture real responses on a device and extend these fixtures —
/// that step is in HANDOFF.md. The parser is built to be patched when DDG
/// changes markup; these tests are the safety net for those patches.
final class DDGParserTests: XCTestCase {
    private let htmlEndpointFixture = """
    <div class="results">
      <div class="result results_links results_links_deep web-result">
        <h2 class="result__title">
          <a rel="nofollow" class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FEBITDA&amp;rut=abc">EBITDA - Wikipedia</a>
        </h2>
        <a class="result__snippet" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FEBITDA">A company's <b>earnings</b> before interest, taxes, depreciation and amortization.</a>
      </div>
      <div class="result results_links results_links_deep web-result">
        <h2 class="result__title">
          <a rel="nofollow" class="result__a" href="https://www.investopedia.com/terms/e/ebitda.asp">EBITDA: Definition &amp; Formula</a>
        </h2>
        <a class="result__snippet" href="https://www.investopedia.com/terms/e/ebitda.asp">EBITDA measures profitability.</a>
      </div>
    </div>
    """

    private let liteEndpointFixture = """
    <table>
      <tr>
        <td><a rel="nofollow" href="https://en.wikipedia.org/wiki/EBITDA" class="result-link">EBITDA - Wikipedia</a></td>
      </tr>
      <tr>
        <td class="result-snippet">Earnings before interest, taxes, depreciation and amortization.</td>
      </tr>
      <tr>
        <td><a rel="nofollow" href="https://www.investopedia.com/terms/e/ebitda.asp" class="result-link">EBITDA Definition</a></td>
      </tr>
      <tr>
        <td class="result-snippet">A measure of profitability.</td>
      </tr>
    </table>
    """

    func testParsesHTMLEndpoint() {
        let results = DDGParser.parse(html: htmlEndpointFixture)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].title, "EBITDA - Wikipedia")
        // Redirect-wrapped URL is unwrapped.
        XCTAssertEqual(results[0].url.absoluteString, "https://en.wikipedia.org/wiki/EBITDA")
        XCTAssertTrue(results[0].snippet.contains("earnings before interest"))
        // HTML entity unescaped in title.
        XCTAssertEqual(results[1].title, "EBITDA: Definition & Formula")
        XCTAssertEqual(results[1].url.host, "www.investopedia.com")
    }

    func testParsesLiteEndpoint() {
        let results = DDGParser.parse(html: liteEndpointFixture)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].title, "EBITDA - Wikipedia")
        XCTAssertEqual(results[0].url.absoluteString, "https://en.wikipedia.org/wiki/EBITDA")
        XCTAssertEqual(results[0].snippet, "Earnings before interest, taxes, depreciation and amortization.")
    }

    func testLimitRespected() {
        XCTAssertEqual(DDGParser.parse(html: htmlEndpointFixture, limit: 1).count, 1)
    }

    func testGarbageInputReturnsEmpty() {
        XCTAssertTrue(DDGParser.parse(html: "<html><body>captcha maybe</body></html>").isEmpty)
        XCTAssertTrue(DDGParser.parse(html: "").isEmpty)
    }

    func testRedirectURLResolution() {
        let url = DDGParser.resolveURL("//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2Fpage%3Fa%3D1&rut=x")
        XCTAssertEqual(url?.absoluteString, "https://example.com/page?a=1")
    }

    func testTagStrippingAndUnescaping() {
        XCTAssertEqual(DDGParser.stripTags("A <b>bold</b> &amp; plain"), "A bold & plain")
    }
}
