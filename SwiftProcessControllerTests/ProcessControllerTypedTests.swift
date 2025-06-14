//
//  LineStreamerTests.swift
//  SwiftProcessControllerTests
//

import Foundation

import XCTest
@testable import SwiftProcessController

final class ProcessControllerTypedTests: XCTestCase {
	struct decodableObj: Codable, Equatable {
		let id: Int
		let value: String
	}
	let jsonEncoder = JSONEncoder()
	let plistEncoder = PropertyListEncoder()
	
	var stdErrHandler: pipedDataHandler = { _ in }
	var stdErrData = Data()
	
	let blankErrHandler: (Error, Data) -> Void = { _,_  in }

	override func setUpWithError() throws {
		stdErrHandler = { err in self.stdErrData.append(err) }
		stdErrData = Data()
		plistEncoder.outputFormat = .xml
	}
	
	override func tearDownWithError() throws {
		
	}
	
	func testSimple() throws {
		var exitCode: Int32 = -1
		let termHandler = { code in exitCode = code }
		var results: [decodableObj] = []
		let inHandler: (decodableObj) -> Void = { d in results.append(d) }
		
		let pc = ProcessControllerTyped.init(executablePath: "/bin/echo", stdoutHandler: inHandler, stderrHandler: stdErrHandler, terminationHandler: termHandler, decoderType: .JSON, errHandler: blankErrHandler)
		let testResult = decodableObj(id: 0, value: "abc")
		try pc.launch(args: [String(data: jsonEncoder.encode(testResult), encoding: .utf8)!])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(results[0], testResult)
	}
	
	func testSimpleNoLineEnding() throws {
		var exitCode: Int32 = -1
		let termHandler = { code in exitCode = code }
		var results: [decodableObj] = []
		let inHandler: (decodableObj) -> Void = { d in results.append(d) }
		
		let pc = ProcessControllerTyped.init(executablePath: "/usr/bin/printf", stdoutHandler: inHandler, stderrHandler: stdErrHandler, terminationHandler: termHandler, decoderType: .JSON, errHandler: blankErrHandler)
		let testResult = decodableObj(id: 0, value: "abc")
		try pc.launch(args: [String(data: jsonEncoder.encode(testResult), encoding: .utf8)!])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(results[0], testResult)
	}
	
	func testManyLines() throws {
		var exitCode: Int32 = -1
		let termHandler = { code in exitCode = code }
		var results: [decodableObj] = []
		let inHandler: (decodableObj) -> Void = { d in results.append(d) }
		
		let pc = ProcessControllerTyped.init(executablePath: "/bin/sh", stdoutHandler: inHandler, stderrHandler: stdErrHandler, terminationHandler: termHandler, decoderType: .JSON, errHandler: blankErrHandler)
		let stdin = Pipe()
		pc.standardInput = stdin
		let dq = DispatchQueue(label: "test.async")
		let TEST_COUNT = 1_000
		dq.async {
			do {
				for i in 0...TEST_COUNT {
					let encoded = try! String(data: self.jsonEncoder.encode(decodableObj(id: i, value: String.init(repeating: "a", count: i))), encoding: .utf8)!
					try stdin.fileHandleForWriting.write(contentsOf: "echo '\(encoded)'\n".data(using: .utf8)!)
				}
				let encoded = try! String(data: self.jsonEncoder.encode(decodableObj(id: TEST_COUNT + 1, value: String.init(repeating: "a", count: 5000))), encoding: .utf8)!
				try stdin.fileHandleForWriting.write(contentsOf: "echo '\(encoded)'\n".data(using: .utf8)!)
				try stdin.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		try pc.launch(args: [])
		XCTAssertEqual(exitCode, 0)
		for i in 0...TEST_COUNT {
			XCTAssertEqual(results[i].id, i)
		}
		XCTAssertEqual(results[TEST_COUNT + 1].id, TEST_COUNT + 1)
		XCTAssertEqual(results[TEST_COUNT + 1].value.count, 5000)
	}
	
	func testSimplePlist() throws {
		var exitCode: Int32 = -1
		let termHandler = { code in exitCode = code }
		var results: [decodableObj] = []
		let inHandler: (decodableObj) -> Void = { d in results.append(d) }
		
		let pc = ProcessControllerTyped.init(executablePath: "/usr/bin/printf", stdoutHandler: inHandler, stderrHandler: stdErrHandler, terminationHandler: termHandler, decoderType: .PropertyList, errHandler: blankErrHandler, separator: ProcessController.separatorNulChar)
		let testResult = decodableObj(id: 0, value: "abc")
		var encoded: Data = try plistEncoder.encode(testResult)
		encoded.append("\\0".data(using: .utf8)!)
		try pc.launch(args: [String(data: encoded, encoding: .utf8)!])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(results[0], testResult)
	}
	
	func testSimplePlistNoLineEnding() throws {
		var exitCode: Int32 = -1
		let termHandler = { code in exitCode = code }
		var results: [decodableObj] = []
		let inHandler: (decodableObj) -> Void = { d in results.append(d) }
		
		let pc = ProcessControllerTyped.init(executablePath: "/usr/bin/printf", stdoutHandler: inHandler, stderrHandler: stdErrHandler, terminationHandler: termHandler, decoderType: .PropertyList, errHandler: blankErrHandler, separator: ProcessController.separatorNulChar)
		let testResult = decodableObj(id: 0, value: "abc")
		try pc.launch(args: [String(data: plistEncoder.encode(testResult), encoding: .utf8)!])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(results[0], testResult)
	}
	
	func testPlistManyLines() throws {
		var exitCode: Int32 = -1
		let termHandler = { code in exitCode = code }
		var results: [decodableObj] = []
		let inHandler: (decodableObj) -> Void = { d in results.append(d) }
		
		let pc = ProcessControllerTyped.init(executablePath: "/bin/sh", stdoutHandler: inHandler, stderrHandler: stdErrHandler, terminationHandler: termHandler, decoderType: .PropertyList, errHandler: blankErrHandler, separator: ProcessController.separatorNulChar)
		let stdin = Pipe()
		pc.standardInput = stdin
		let dq = DispatchQueue(label: "test.async")
		let TEST_COUNT = 1_000
		dq.async {
			do {
				for i in 0...TEST_COUNT {
					let encoded = try! String(data: self.plistEncoder.encode(decodableObj(id: i, value: String.init(repeating: "a", count: i))), encoding: .utf8)!
					try stdin.fileHandleForWriting.write(contentsOf: "printf '\(encoded)\\0'\n".data(using: .utf8)!)
				}
				let encoded = try! String(data: self.plistEncoder.encode(decodableObj(id: TEST_COUNT + 1, value: String.init(repeating: "a", count: 5000))), encoding: .utf8)!
				try stdin.fileHandleForWriting.write(contentsOf: "printf '\(encoded)\\0'\n".data(using: .utf8)!)
				try stdin.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		try pc.launch(args: [])
		XCTAssertEqual(exitCode, 0)
		for i in 0..<TEST_COUNT {
			XCTAssertEqual(results[i].id, i)
		}
		XCTAssertEqual(results[TEST_COUNT + 1].id, TEST_COUNT + 1)
		XCTAssertEqual(results[TEST_COUNT + 1].value.count, 5000)
	}
	
}
