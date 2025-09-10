//
//  SPCProcessControllerTests.swift
//  SwiftProcessController
//

import XCTest
@testable import SwiftProcessController

final class SPCProcessControllerTests: XCTestCase {
	class ResultTester: SPCDelegate {
		var out = String()
		func stdoutHandler(_ output: Data) {
			if let newData = String(data: output, encoding: .ascii) {
				out += newData
			}
		}
		var err = String()
		func stderrHandler(_ output: Data) {
			if let newData = String(data: output, encoding: .ascii) {
				err += newData
			}
		}
		var exitCode: Int32?
		func terminationHandler(exitCode: Int32) {
			self.exitCode = exitCode
		}
	}
	
	let dispatchQueue = DispatchQueue(label: "test.async")
	
	override func setUpWithError() throws {
		
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testSimple() throws {
		let result = ResultTester()
		let pc = SPCController(executablePath: "/usr/bin/printf", delegate: result)
		try pc.launchAndWaitUntilExit(args: ["testing"])
		XCTAssertEqual(result.exitCode, 0)
		XCTAssertEqual(result.out, "testing")
		XCTAssertEqual(result.err.count, 0)
	}
	
	func testSimpleExitCode() throws {
		let result = ResultTester()
		let pc = SPCController(executablePath: "/usr/bin/false", delegate: result)
		try pc.launchAndWaitUntilExit(args: [])
		XCTAssertEqual(result.exitCode, 1)
		XCTAssertEqual(result.out.count, 0)
		XCTAssertEqual(result.err.count, 0)
	}
	
	@available(macOS 10.15.4, *)
	func testMultiLine() throws {
		let result = ResultTester()
		let pc = SPCController(executablePath: "/bin/cat", delegate: result)
		let input = Pipe()
		pc.standardInput = input
		let inputArr = (1...100).map { i in
			return "line \(i)"
		}.joined(separator: "\n")
		dispatchQueue.async {
			do {
				try input.fileHandleForWriting.write(contentsOf: inputArr.data(using: .ascii)!)
				try input.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		
		try pc.launchAndWaitUntilExit(args: [])
		XCTAssertEqual(result.exitCode, 0)
		XCTAssertEqual(result.out, inputArr)
		XCTAssertEqual(result.err.count, 0)
	}
	
	@available(macOS 10.15.4, *)
	func testSimpleCommand() throws {
		let result = ResultTester()
		let pc = SPCController(executablePath: "/bin/sh", delegate: result)
		let standardInput = Pipe()
		pc.standardInput = standardInput
		dispatchQueue.async {
			do {
				try standardInput.fileHandleForWriting.write(contentsOf: "echo hello\n".data(using: .ascii)!)
				try standardInput.fileHandleForWriting.write(contentsOf: "echo hello\n".data(using: .ascii)!)
				try standardInput.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		try pc.launchAndWaitUntilExit(args: [])
		XCTAssertEqual(result.exitCode, 0)
		XCTAssertEqual(result.out, "hello\nhello\n")
		XCTAssertEqual(result.err.count, 0)
	}
	
	@available(macOS 10.15.4, *)
	func testMultiLineWithError() throws {
		let result = ResultTester()
		let pc = SPCController(executablePath: "/bin/sh", delegate: result)
		let input = Pipe()
		pc.standardInput = input
		var inResult = ""
		var errResult = ""
		dispatchQueue.async {
			do {
				for i in 0...2500 {
					if (i % 3) == 0 {
						let inLine = "echo line \(i)\n"
						try input.fileHandleForWriting.write(contentsOf: inLine.data(using: .ascii)!)
						inResult += "line \(i)\n"
					}
					if (i % 5) == 0 {
						let errLine = "echo line \(i) >&2\n"
						try input.fileHandleForWriting.write(contentsOf: errLine.data(using: .ascii)!)
						errResult += "line \(i)\n"
					}
				}
				try input.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		
		try pc.launchAndWaitUntilExit(args: [])
		XCTAssertEqual(result.exitCode, 0)
		XCTAssertEqual(result.out, inResult)
		XCTAssertEqual(result.err, errResult)
	}
	
}
