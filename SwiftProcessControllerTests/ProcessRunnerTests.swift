//
//  ProcessRunnerTests.swift
//  SwiftProcessController
//

import XCTest
@testable import SwiftProcessController

final class ProcessRunnerTests: XCTestCase {
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
		continueAfterFailure = true
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testRunner() throws {
		let runner = ProcessRunner(executablePath: "/bin/sh")
		XCTAssertNoThrow({
			try runner.run(args: ["--version"])
		})
	}
	
	func testRunnerBasicReturnsAndExitStatuses() throws {
		let runTrue = ProcessRunner(executablePath: "/usr/bin/true")
		let resTrue = try runTrue.run(args: [])
		XCTAssertEqual(resTrue.outputString(), "")
		XCTAssertEqual(resTrue.errorString(), "")
		XCTAssertEqual(resTrue.exitStatus, 0)
		let url = URL(fileURLWithPath: "/usr/bin/false")
		let runFalse = ProcessRunner(executableURL: url)
		let resFalse = try runFalse.run(args: [])
		XCTAssertEqual(resFalse.exitStatus, 1)
	}
	
	func testRunnerOutput() throws {
		let run = ProcessRunner(executablePath: "/usr/bin/printf")
		let printString = "test return"
		let res = try run.run(args: [printString])
		XCTAssertEqual(res.outputString(), printString)
		XCTAssertEqual(res.errorString(), "")
	}
	
	func testRunnerStderr() throws {
		let run = ProcessRunner(executablePath: "/usr/bin/printf")
		let res = try run.run(args: [])
		XCTAssertEqual(res.outputString(), "")
		XCTAssertEqual(res.errorString(), "usage: printf format [arguments ...]\n")
	}
	
	func testRunnerStdBoth() throws {
		let run = ProcessRunner(executablePath: "/bin/sh")
		let res = try run.run(args: ["-c", "/usr/bin/printf \"stdout\"; /usr/bin/printf \"stderr\" >&2"])
		XCTAssertEqual(res.outputString(), "stdout")
		XCTAssertEqual(res.errorString(), "stderr")
	}
	
	func testDefaultEnv() throws {
		let run = ProcessRunner(executablePath: "/usr/bin/printenv")
		let res = try run.run(args: ["TERM"])
		XCTAssertEqual(res.outputString(), "dumb\n")
	}
	
	func testCustomEnv() throws {
		let run = ProcessRunner(executablePath: "/usr/bin/printenv")
		let env: [String : String] = ["TESTING_CUSTOM_ENV" : "custom enviorment variable"]
		run.env = env
		let res = try run.run(args: ["TESTING_CUSTOM_ENV"])
		XCTAssertEqual(res.outputString(), "custom enviorment variable\n")
	}
	
	func testJSONReturnType() throws {
		struct decodableJSON: Codable, Equatable {
			let str: String
			let number: Int
			let fun_number: Double
			let dict: [String : String]
			let arr: [Bool]
		}
		let sample_output = decodableJSON(str: "testing", number: 99, fun_number: 99.999, dict: ["fun_string" : "test\nmultiline\nstring"], arr: [true, false, true, true, false])
		let run = ProcessRunner(executablePath: "/bin/echo")
		let res = try run.run(args: [String(data: JSONEncoder().encode(sample_output), encoding: .utf8)!], returning: decodableJSON.self)
		XCTAssertEqual(res.output, sample_output)
	}
	
	func testCurrentDirectory() throws {
		let run = ProcessRunner(executablePath: "/bin/pwd")
		let res = try run.run(args: []).outputString()
		XCTAssertEqual(res, "/tmp\n")
		
		let run2 = ProcessRunner(executablePath: "/bin/pwd")
		run2.currentDirectory = URL(fileURLWithPath: "/usr/bin")
		let res2 = try run2.run(args: []).outputString()
		XCTAssertEqual(res2, "/usr/bin\n")
	}
	
}
