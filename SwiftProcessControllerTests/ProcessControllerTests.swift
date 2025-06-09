//
//  ProcessControllerTests.swift
//  SwiftProcessController
//

import XCTest
@testable import SwiftProcessController

final class ProcessControllerTests: XCTestCase {
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testSimple() throws {
		var stdinData = Data()
		let inHandler: pipedDataHandler = { d in
			stdinData.append(d)
		}
		var stderrData = Data()
		let errHandler: pipedDataHandler = {d in
			stderrData.append(d)
		}
		var exitCode: Int32?
		let termHandler: terminationHandler = { code in
			exitCode = code
			print("exited")
		}
		let pc = ProcessController(executablePath: "/usr/bin/printf", stdoutHandler: inHandler, stderrHandler: errHandler, terminationHandler: termHandler)
		try pc.launch(args: ["testing"])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(String(data: stdinData, encoding: .ascii), "testing")
		XCTAssertEqual(stderrData.count, 0)
	}
	
	func testMultiLine() throws {
		var stdinData = Data()
		let inHandler: pipedDataHandler = { d in
			stdinData.append(d)
		}
		var stderrData = Data()
		let errHandler: pipedDataHandler = {d in
			stderrData.append(d)
		}
		var exitCode: Int32?
		let termHandler: terminationHandler = { code in
			exitCode = code
			print("exited")
		}
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
	
}
