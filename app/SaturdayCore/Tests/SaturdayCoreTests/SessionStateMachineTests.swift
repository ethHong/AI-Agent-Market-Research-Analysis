import XCTest
@testable import SaturdayCore

final class SessionStateMachineTests: XCTestCase {
    func testHappyPath() {
        var machine = SessionStateMachine()
        XCTAssertEqual(machine.state, .idle)
        XCTAssertTrue(machine.handle(.startSession))
        XCTAssertEqual(machine.state, .listening)
        XCTAssertTrue(machine.handle(.queryCaptured))
        XCTAssertEqual(machine.state, .answering)
        XCTAssertTrue(machine.handle(.answerDelivered))
        XCTAssertEqual(machine.state, .listening)
        XCTAssertTrue(machine.handle(.endSession))
        XCTAssertEqual(machine.state, .ended)
    }

    func testInterruptionRequiresUserResume() {
        var machine = SessionStateMachine()
        machine.handle(.startSession)
        machine.handle(.interruptionBegan)
        XCTAssertEqual(machine.state, .interrupted)
        // The hard iOS constraint: nothing but an explicit user action resumes.
        XCTAssertFalse(machine.handle(.queryCaptured))
        XCTAssertFalse(machine.handle(.answerDelivered))
        XCTAssertEqual(machine.state, .interrupted)
        XCTAssertTrue(machine.handle(.userResumed))
        XCTAssertEqual(machine.state, .listening)
    }

    func testInterruptionWhileAnswering() {
        var machine = SessionStateMachine()
        machine.handle(.startSession)
        machine.handle(.queryCaptured)
        XCTAssertTrue(machine.handle(.interruptionBegan))
        XCTAssertEqual(machine.state, .interrupted)
    }

    func testEndFromInterrupted() {
        var machine = SessionStateMachine()
        machine.handle(.startSession)
        machine.handle(.interruptionBegan)
        XCTAssertTrue(machine.handle(.endSession))
        XCTAssertEqual(machine.state, .ended)
    }

    func testInvalidTransitionsDoNotChangeState() {
        var machine = SessionStateMachine()
        XCTAssertFalse(machine.handle(.queryCaptured))
        XCTAssertFalse(machine.handle(.endSession))
        XCTAssertEqual(machine.state, .idle)
    }

    func testRestartAfterEnd() {
        var machine = SessionStateMachine()
        machine.handle(.startSession)
        machine.handle(.endSession)
        XCTAssertTrue(machine.handle(.startSession))
        XCTAssertEqual(machine.state, .listening)
    }
}
