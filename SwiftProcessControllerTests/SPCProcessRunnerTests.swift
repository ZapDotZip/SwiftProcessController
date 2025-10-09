//
//  SPCProcessRunnerTests.swift
//  SwiftProcessController
//

import XCTest
@testable import SwiftProcessController

final class SPCProcessRunnerTests: XCTestCase {
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
		continueAfterFailure = true
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testRunner() throws {
		let runner = SPCRunner(executablePath: "/bin/sh")
		XCTAssertNoThrow({
			try runner.run(args: ["--version"])
		})
	}
	
	func testRunnerBasicReturnsAndExitStatuses() throws {
		let runTrue = SPCRunner(executablePath: "/usr/bin/true")
		let resTrue = try runTrue.run(args: [])
		XCTAssertEqual(resTrue.outputString(), "")
		XCTAssertEqual(resTrue.errorString(), "")
		XCTAssertEqual(resTrue.exitStatus, 0)
		let url = URL(localPath: "/usr/bin/false")
		let runFalse = SPCRunner(executableURL: url)
		let resFalse = try runFalse.run(args: [])
		XCTAssertEqual(resFalse.exitStatus, 1)
	}
	
	func testRunnerOutput() throws {
		let run = SPCRunner(executablePath: "/usr/bin/printf")
		let printString = "test return"
		let res = try run.run(args: [printString])
		XCTAssertEqual(res.outputString(), printString)
		XCTAssertEqual(res.errorString(), "")
	}
	
	func testRunnerStderr() throws {
		let run = SPCRunner(executablePath: "/usr/bin/printf")
		let res = try run.run(args: [])
		XCTAssertEqual(res.outputString(), "")
		XCTAssertEqual(res.errorString(), "usage: printf format [arguments ...]\n")
	}
	
	func testRunnerStdBoth() throws {
		let run = SPCRunner(executablePath: "/bin/sh")
		let res = try run.run(args: ["-c", "/usr/bin/printf \"stdout\"; /usr/bin/printf \"stderr\" >&2"])
		XCTAssertEqual(res.outputString(), "stdout")
		XCTAssertEqual(res.errorString(), "stderr")
	}
	
	func testDefaultEnv() throws {
		let run = SPCRunner(executablePath: "/usr/bin/printenv")
		let res = try run.run(args: ["TERM"])
		XCTAssertEqual(res.outputString(), "dumb\n")
	}
	
	func testCustomEnv() throws {
		let run = SPCRunner(executablePath: "/usr/bin/printenv")
		let env: [String : String] = ["TESTING_CUSTOM_ENV" : "custom enviorment variable"]
		run.env = env
		let res = try run.run(args: ["TESTING_CUSTOM_ENV"])
		XCTAssertEqual(res.outputString(), "custom enviorment variable\n")
	}
	
	func testJSONReturnType() throws {
		struct DecodableJSON: Codable, Equatable {
			let str: String
			let number: Int
			let fun_number: Double
			let dict: [String : String]
			let arr: [Bool]
		}
		let testOutput = DecodableJSON(str: "testing", number: 99, fun_number: 99.999, dict: ["fun_string" : "test\nmultiline\nstring"], arr: [true, false, true, true, false])
		let run = SPCRunner(executablePath: "/bin/echo")
		let res = try run.run(args: [String(data: JSONEncoder().encode(testOutput), encoding: .utf8)!], returning: DecodableJSON.self, decodingWith: .JSON)
		
		switch res.output {
			case .object(let output):
				XCTAssertEqual(output, testOutput)
			case .error(let rawData, let decodingError):
				XCTFail("Failed to decode \(String(data: rawData, encoding: .utf8) ?? decodingError.localizedDescription)")
		}
		
	}
	
	func testInvalidJSON() throws {
		struct DecodableJSON: Codable, Equatable {
			let str: String
			let number: Int
			let fun_number: Double
			let dict: [String : String]
			let arr: [Bool]
		}
		let testOutput = DecodableJSON(str: "testing", number: 99, fun_number: 99.999, dict: ["fun_string" : "test"], arr: [true, false, true, true, false])
		let run = SPCRunner(executablePath: "/usr/bin/printf")
		let inputData: String = String(data: try! JSONEncoder().encode(testOutput), encoding: .utf8)!.replacingOccurrences(of: ":", with: "whoops")
		let res = try run.run(args: [inputData], returning: DecodableJSON.self, decodingWith: .JSON)
		
		switch res.output {
			case .object(let _):
				XCTFail("Output should not be valid.")
			case .error(let rawData, let decodingError):
				XCTAssert(rawData == inputData.data(using: .utf8))
		}
		
	}
	
	func testCurrentDirectory() throws {
		let run = SPCRunner(executablePath: "/bin/pwd")
		let res = try run.run(args: []).outputString()
		XCTAssertEqual(res, "/tmp\n")
		
		let run2 = SPCRunner(executablePath: "/bin/pwd")
		run2.currentDirectory = URL(localPath: "/usr/bin")
		let res2 = try run2.run(args: []).outputString()
		XCTAssertEqual(res2, "/usr/bin\n")
	}
	
}
