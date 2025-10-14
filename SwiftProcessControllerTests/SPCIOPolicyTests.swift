//
//  SPCIOPolicyTests.swift
//  SwiftProcessControllerTests
//

import XCTest
@testable import SwiftProcessController

@available(macOS 10.12, *)
final class SPCIOPolicyTests: XCTestCase {
	
	var programPath: URL = {
		let cTestCode = """
	#include <sys/resource.h>
	#include <stdio.h>
	
	int main() {
		int policy = getiopolicy_np(IOPOL_TYPE_DISK, IOPOL_SCOPE_PROCESS);
		switch (policy) {
		case IOPOL_IMPORTANT:
			printf("IOPOL_IMPORTANT");
			break;
		case IOPOL_STANDARD:
			printf("IOPOL_STANDARD");
			break;
		case IOPOL_UTILITY:
			printf("IOPOL_UTILITY");
			break;
		case IOPOL_THROTTLE:
			printf("IOPOL_THROTTLE");
			break;
		case IOPOL_PASSIVE:
			printf("IOPOL_PASSIVE");
			break;
		case 0: // Setting important or default via taskpolicy results in 0.
			printf("IOPOL_IMPORTANT");
			break;
		default:
			printf("Unknown (%d)", policy);
			break;
		}
	}
	"""

		let runner = SPCRunner(executablePath: "/usr/bin/clang")
		let codePipe = Pipe()
		runner.standardInput = codePipe
		let programPath = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
		DispatchQueue.global().async {
			if #available(macOS 10.15.4, *) {
				try! codePipe.fileHandleForWriting.write(contentsOf: cTestCode.data(using: .utf8)!)
				try! codePipe.fileHandleForWriting.close()
			} else {
				codePipe.fileHandleForWriting.write(cTestCode.data(using: .utf8)!)
				codePipe.fileHandleForWriting.closeFile()
			}
		}
		_ = try! runner.run(args: ["-x", "c", "-", "-o", programPath.localPath])
		return programPath
	}()
	
	func testExample() throws {
		let runner = SPCRunner(executableURL: programPath)
		var result = try! runner.run(args: [])
		XCTAssert("IOPOL_IMPORTANT" == result.outputString(), "Got \(result.outputString() ?? "").")
		runner.ioPolicy = .important
		result = try! runner.run(args: [])
		XCTAssert("IOPOL_IMPORTANT" == result.outputString(), "Got \(result.outputString() ?? "").")
		runner.ioPolicy = .standard
		result = try! runner.run(args: [])
		XCTAssert("IOPOL_STANDARD" == result.outputString(), "Got \(result.outputString() ?? "").")
		runner.ioPolicy = .utility
		result = try! runner.run(args: [])
		XCTAssert("IOPOL_UTILITY" == result.outputString(), "Got \(result.outputString() ?? "").")
		runner.ioPolicy = .throttle
		result = try! runner.run(args: [])
		XCTAssert("IOPOL_THROTTLE" == result.outputString(), "Got \(result.outputString() ?? "").")
		runner.ioPolicy = .passive
		result = try! runner.run(args: [])
		XCTAssert("IOPOL_PASSIVE" == result.outputString(), "Got \(result.outputString() ?? "").")
	}
	
}
