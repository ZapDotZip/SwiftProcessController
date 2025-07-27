//
//  SPCBaseProcessStateTests.swift
//  SwiftProcessControllerTests
//

import XCTest
@testable import SwiftProcessController

final class SPCBaseProcessStateTests: XCTestCase {
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
		continueAfterFailure = true
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	let dispatchQueue = DispatchQueue(label: "test")
	
	func testSuspendResume() throws {
		let run = ProcessRunner(executablePath: "/bin/cat")
		let stdin = Pipe()
		run.standardInput = stdin
		XCTAssertEqual(run.isSuspended, false)
		XCTAssertEqual(run.processState, .notRunning)
		dispatchQueue.async {
			let res = try! run.run(args: [])
			XCTAssertEqual(res.exitStatus, 15)
		}
		while run.currentlyRunningProcess == nil {
			Thread.sleep(forTimeInterval: 0.1)
		}
		XCTAssertTrue(run.currentlyRunningProcess!.isRunning)
		XCTAssertEqual(run.isSuspended, false)
		XCTAssertEqual(run.processState, .running)
		XCTAssertTrue(run.suspend())
		XCTAssertEqual(run.isSuspended, true)
		XCTAssertEqual(run.processState, .suspended)
		XCTAssertFalse(run.suspend())
		XCTAssertEqual(run.isSuspended, true)
		XCTAssertEqual(run.processState, .suspended)
		XCTAssertTrue(run.resume())
		XCTAssertEqual(run.isSuspended, false)
		XCTAssertEqual(run.processState, .running)
		run.terminateAndWaitForExit()
		XCTAssertEqual(run.isSuspended, false)
		XCTAssertEqual(run.processState, .notRunning)
	}
	
	func testSignals() throws {
		let run = ProcessRunner(executablePath: "/bin/cat")
		let stdin = Pipe()
		run.standardInput = stdin
		XCTAssertEqual(run.isSuspended, false)
		XCTAssertEqual(run.processState, .notRunning)
		let dq = DispatchQueue(label: "test")
		dq.async {
			let res = try! run.run(args: [])
			XCTAssertEqual(res.exitStatus, 15)
		}
		while run.currentlyRunningProcess == nil {
			Thread.sleep(forTimeInterval: 0.1)
		}
		try run.killAndWaitForExit()
	}
	
}
