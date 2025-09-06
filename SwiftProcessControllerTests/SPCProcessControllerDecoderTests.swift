//
//  SPCProcessControllerDecoderTests.swift
//  SwiftProcessControllerTests
//

import Foundation

import XCTest
@testable import SwiftProcessController

final class SPCProcessControllerDecoderTests: XCTestCase {
	struct DecodableObj: Codable, Equatable {
		let id: Int
		let value: String
	}
	let jsonEncoder = JSONEncoder()
	let plistEncoder = PropertyListEncoder()
	
	class TestDelegate: SPCProcessDecoderDelegate {
		typealias D = SPCProcessControllerDecoderTests.DecodableObj
		
		var results: [DecodableObj] = []
		func stdoutHandler(_ output: SPCStreamingResult<D>) {
			switch output {
				case .object(output: let output): results.append(output)
				case .error(rawData: _, decodingError: let err): XCTFail("Error decoding: \(err)")
			}
		}
		var err = String()
		func stderrHandler(_ output: Data) {
			if let newData = String(data: output, encoding: .ascii) { err += newData }
		}
		var exitCode: Int32?
		func terminationHandler(exitCode: Int32) { self.exitCode = exitCode }
	}
	
	let dispatchQueue = DispatchQueue(label: "test.async")
	
	override func setUpWithError() throws {
		plistEncoder.outputFormat = .xml
	}
	
	override func tearDownWithError() throws {
		
	}
	
	func testSimple() throws {
		let d = TestDelegate()
		let pc = SPCProcessControllerDecoder.init(executablePath: "/bin/echo", delegate: d, decoderType: .JSON)
		let testResult = DecodableObj(id: 0, value: "abc")
		try pc.launchAndWaitUntilExit(args: [String(data: jsonEncoder.encode(testResult), encoding: .utf8)!])
		XCTAssertEqual(d.exitCode, 0)
		XCTAssertEqual(d.results[0], testResult)
	}
	
	func testSimpleNoLineEnding() throws {
		let d = TestDelegate()
		let pc = SPCProcessControllerDecoder.init(executablePath: "/usr/bin/printf", delegate: d, decoderType: .JSON)
		let testResult = DecodableObj(id: 0, value: "abc")
		try pc.launchAndWaitUntilExit(args: [String(data: jsonEncoder.encode(testResult), encoding: .utf8)!])
		XCTAssertEqual(d.exitCode, 0)
		XCTAssertEqual(d.results[0], testResult)
	}
	
	@available(macOS 10.15.4, *)
	func testManyLines() throws {
		let d = TestDelegate()
		let pc = SPCProcessControllerDecoder.init(executablePath: "/bin/sh", delegate: d, decoderType: .JSON)
		let stdin = Pipe()
		pc.standardInput = stdin
		let TEST_COUNT = 1_000
		dispatchQueue.async {
			do {
				for i in 0...TEST_COUNT {
					let encoded = try! String(data: self.jsonEncoder.encode(DecodableObj(id: i, value: String.init(repeating: "a", count: i))), encoding: .utf8)!
					try stdin.fileHandleForWriting.write(contentsOf: Data("echo '\(encoded)'\n".utf8))
				}
				let encoded = try! String(data: self.jsonEncoder.encode(DecodableObj(id: TEST_COUNT + 1, value: String.init(repeating: "a", count: 5000))), encoding: .utf8)!
				try stdin.fileHandleForWriting.write(contentsOf: Data("echo '\(encoded)'\n".utf8))
				try stdin.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		try pc.launchAndWaitUntilExit(args: [])
		XCTAssertEqual(d.exitCode, 0)
		for i in 0...TEST_COUNT {
			XCTAssertEqual(d.results[i].id, i)
		}
		XCTAssertEqual(d.results[TEST_COUNT + 1].id, TEST_COUNT + 1)
		XCTAssertEqual(d.results[TEST_COUNT + 1].value.count, 5000)
	}
	
	func testSimplePlist() throws {
		let d = TestDelegate()
		let pc = SPCProcessControllerDecoder.init(executablePath: "/usr/bin/printf", delegate: d, decoderType: .PropertyList, separator: SPCProcessController.separatorNulChar)
		let testResult = DecodableObj(id: 0, value: "abc")
		var encoded: Data = try plistEncoder.encode(testResult)
		encoded.append(Data("\\0".utf8))
		try pc.launchAndWaitUntilExit(args: [String(data: encoded, encoding: .utf8)!])
		XCTAssertEqual(d.exitCode, 0)
		XCTAssertEqual(d.results[0], testResult)
	}
	
	func testSimplePlistNoLineEnding() throws {
		let d = TestDelegate()
		let pc = SPCProcessControllerDecoder.init(executablePath: "/usr/bin/printf", delegate: d, decoderType: .PropertyList, separator: SPCProcessController.separatorNulChar)
		let testResult = DecodableObj(id: 0, value: "abc")
		try pc.launchAndWaitUntilExit(args: [String(data: plistEncoder.encode(testResult), encoding: .utf8)!])
		XCTAssertEqual(d.exitCode, 0)
		XCTAssertEqual(d.results[0], testResult)
	}
	
	@available(macOS 10.15.4, *)
	func testPlistManyLines() throws {
		let d = TestDelegate()
		let pc = SPCProcessControllerDecoder.init(executablePath: "/bin/sh", delegate: d, decoderType: .PropertyList, separator: SPCProcessController.separatorNulChar)
		let stdin = Pipe()
		pc.standardInput = stdin
		let TEST_COUNT = 1_000
		dispatchQueue.async {
			do {
				for i in 0...TEST_COUNT {
					let encoded = try! String(data: self.plistEncoder.encode(DecodableObj(id: i, value: String.init(repeating: "a", count: i))), encoding: .utf8)!
					try stdin.fileHandleForWriting.write(contentsOf: Data("printf '\(encoded)\\0'\n".utf8))
				}
				let encoded = try! String(data: self.plistEncoder.encode(DecodableObj(id: TEST_COUNT + 1, value: String.init(repeating: "a", count: 5000))), encoding: .utf8)!
				try stdin.fileHandleForWriting.write(contentsOf: Data("printf '\(encoded)\\0'\n".utf8))
				try stdin.fileHandleForWriting.close()
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		try pc.launchAndWaitUntilExit(args: [])
		XCTAssertEqual(d.exitCode, 0)
		for i in 0..<TEST_COUNT {
			XCTAssertEqual(d.results[i].id, i)
		}
		XCTAssertEqual(d.results[TEST_COUNT + 1].id, TEST_COUNT + 1)
		XCTAssertEqual(d.results[TEST_COUNT + 1].value.count, 5000)
	}
	
	@available(macOS 10.15.4, *)
	func testPlistPerformance() {
		self.measure {
			let d = TestDelegate()
			let pc = SPCProcessControllerDecoder.init(executablePath: "/bin/sh", delegate: d, decoderType: .PropertyList, separator: SPCProcessController.separatorNulChar)
			let testCount = 1_250
			dispatchQueue.async { [self] in
				let procstdin = Pipe()
				pc.standardInput = procstdin
				for i in 0...testCount {
					let encoded = try! String(data: self.plistEncoder.encode(DecodableObj(id: i, value: String.init(repeating: "a", count: i))), encoding: .utf8)!
					try! procstdin.fileHandleForWriting.write(contentsOf: Data("printf '\(encoded)\\0'\n".utf8))
				}
				let encoded = try! String(data: self.plistEncoder.encode(DecodableObj(id: testCount + 1, value: String.init(repeating: "a", count: 5000))), encoding: .utf8)!
				try! procstdin.fileHandleForWriting.write(contentsOf: Data("printf '\(encoded)\\0'\n".utf8))
				try! procstdin.fileHandleForWriting.close()
			}
			try! pc.launchAndWaitUntilExit(args: [])
		}
	}
	
}
