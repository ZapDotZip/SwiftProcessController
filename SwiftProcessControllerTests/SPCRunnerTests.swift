//
//  SPCRunnerTests.swift
//  SwiftProcessController
//

import XCTest
@testable import SwiftProcessController

final class SPCRunnerTests: XCTestCase {
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testRunner() throws {
		let runner = Runner(executablePath: "/bin/sh")
		XCTAssertNoThrow({
			try runner.run(args: ["--version"], env: nil)
		})
	}
	
	func testRunnerBasicReturnsAndExitStatuses() throws {
		let runTrue = Runner(executablePath: "/usr/bin/true")
		let resTrue = try runTrue.run(args: [], env: nil)
		XCTAssertEqual(resTrue.outputString(), "")
		XCTAssertEqual(resTrue.errorString(), "")
		XCTAssertEqual(resTrue.exitStatus, 0)
		let runFalse = Runner(executablePath: "/usr/bin/false")
		let resFalse = try runFalse.run(args: [], env: nil)
		XCTAssertEqual(resFalse.exitStatus, 1)
	}
	
	func testRunnerOutput() throws {
		let run = Runner(executablePath: "/usr/bin/printf")
		let printString = "test return"
		let res = try run.run(args: [printString], env: nil)
		XCTAssertEqual(res.outputString(), printString)
		XCTAssertEqual(res.errorString(), "")
	}
	
	func testRunnerStderr() throws {
		let run = Runner(executablePath: "/usr/bin/printf")
		let res = try run.run(args: [], env: nil)
		XCTAssertEqual(res.outputString(), "")
		XCTAssertEqual(res.errorString(), "usage: printf format [arguments ...]\n")
	}
	
	func testRunnerStdBoth() throws {
		let run = Runner(executablePath: "/bin/sh")
		let res = try run.run(args: ["-c", "/usr/bin/printf \"stdout\"; /usr/bin/printf \"stderr\" >&2"], env: nil)
		XCTAssertEqual(res.outputString(), "stdout")
		XCTAssertEqual(res.errorString(), "stderr")
	}
	
	func testDefaultEnv() throws {
		let run = Runner(executablePath: "/usr/bin/printenv")
		let res = try run.run(args: ["TERM"], env: nil)
		XCTAssertEqual(res.outputString(), "dumb\n")
	}
	
	func testCustomEnv() throws {
		let run = Runner(executablePath: "/usr/bin/printenv")
		let env: [String : String] = ["TESTING_CUSTOM_ENV" : "custom enviorment variable"]
		let res = try run.run(args: ["TESTING_CUSTOM_ENV"], env: env)
		XCTAssertEqual(res.outputString(), "custom enviorment variable\n")
	}
	
}
