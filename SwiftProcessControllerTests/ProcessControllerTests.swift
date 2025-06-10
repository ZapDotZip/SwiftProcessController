//
//  ProcessControllerTests.swift
//  SwiftProcessController
//

import XCTest
@testable import SwiftProcessController

final class ProcessControllerTests: XCTestCase {
	var stdinData = Data()
	var inHandler: pipedDataHandler = { d in XCTFail("Unset closure!") }
	var stderrData = Data()
	var errHandler: pipedDataHandler = { d in XCTFail("Unset closure!") }
	var exitCode: Int32?
	var termHandler: terminationHandler = { code in XCTFail("Unset closure!") }
	
	override func setUpWithError() throws {
		stdinData = Data()
		inHandler = { d in self.stdinData.append(d) }
		stderrData = Data()
		errHandler = { d in self.stderrData.append(d) }
		exitCode = nil
		termHandler = { code in self.exitCode = code }

	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testSimple() throws {
		let pc = ProcessController(executablePath: "/usr/bin/printf", stdoutHandler: inHandler, stderrHandler: errHandler, terminationHandler: termHandler)
		try pc.launch(args: ["testing"])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(String(data: stdinData, encoding: .ascii), "testing")
		XCTAssertEqual(stderrData.count, 0)
	}
	
	func testSimpleExitCode() throws {
		let pc = ProcessController(executablePath: "/usr/bin/false", stdoutHandler: inHandler, stderrHandler: errHandler, terminationHandler: termHandler)
		try pc.launch(args: [])
		XCTAssertEqual(exitCode, 1)
		XCTAssertEqual(stdinData.count, 0)
		XCTAssertEqual(stderrData.count, 0)
	}

	func testMultiLine() throws {
		let pc = ProcessController(executablePath: "/bin/cat", stdoutHandler: inHandler, stderrHandler: errHandler, terminationHandler: termHandler)
		let input = Pipe()
		pc.standardInput = input
		let inputArr = (1...100).map { i in
			return "line \(i)"
		}.joined(separator: "\n")
		let dq = DispatchQueue(label: "test.async")
		dq.async {
			do {
				try input.fileHandleForWriting.write(contentsOf: inputArr.data(using: .ascii)!)
				try input.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		
		try pc.launch(args: [])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(String(data: stdinData, encoding: .ascii), inputArr)
		XCTAssertEqual(stderrData.count, 0)
	}
	
	func testSimpleCommand() throws {
		let pc = ProcessController(executablePath: "/bin/sh", stdoutHandler: inHandler, stderrHandler: errHandler, terminationHandler: termHandler)
		let standardInput = Pipe()
		pc.standardInput = standardInput
		let dq = DispatchQueue(label: "test.async")
		dq.async {
			do {
				try standardInput.fileHandleForWriting.write(contentsOf: "echo hello\n".data(using: .ascii)!)
				try standardInput.fileHandleForWriting.write(contentsOf: "echo hello\n".data(using: .ascii)!)
				try standardInput.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		try pc.launch(args: [])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(String(data: stdinData, encoding: .ascii), "hello\nhello\n")
		XCTAssertEqual(stderrData.count, 0)
	}
	
	func testMultiLineWithError() throws {
		let pc = ProcessController(executablePath: "/bin/sh", stdoutHandler: inHandler, stderrHandler: errHandler, terminationHandler: termHandler)
		let input = Pipe()
		pc.standardInput = input
		let dq = DispatchQueue(label: "test.async")
		var inResult = ""
		var errResult = ""
		dq.async {
			do {
				for i in 0...2500 {
					if ((i % 3) == 0) {
						let inLine = "echo line \(i)\n"
						try input.fileHandleForWriting.write(contentsOf: inLine.data(using: .ascii)!)
						inResult += "line \(i)\n"
					}
					if ((i % 5) == 0) {
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
		
		try pc.launch(args: [])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(String(data: stdinData, encoding: .ascii), inResult)
		XCTAssertEqual(String(data: stderrData, encoding: .ascii), errResult)
	}

}
