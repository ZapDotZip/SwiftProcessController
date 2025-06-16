//
//  SPCBase.swift
//  SwiftProcessController
//

import Foundation

/// A base class to hold functionailty for both `ProcessRunner` and `ProcessController`. Do not use directly.
public class SPCBase {
	/// The location of the binary to execute.
	public var executableURL: URL
	/// The enviorment to use when running the process. If set to `nil`, the process will inherit the parent's enviorment. If set to an empty dictionary, the process will have no enviorment.
	public var env: [String : String]?
	/// If set, the pipe which will be used for the process's standard input.
	public var standardInput: Pipe?
	/// The process's working directory. If set to `nil`, the process will inherit the parent's current working directory.
	public var currentDirectory: URL?
	/// The quality of service to run the process with. Defaults to `QualityOfService.default`
	public var qualityOfService: QualityOfService = .default
	
	init(executableURL: URL) {
		self.executableURL = executableURL
	}
	
	convenience init(executablePath: String) {
		self.init(executableURL: URL(fileURLWithPath: executablePath))
	}
	
	func CreateProcessObject(standardOutput: Pipe, standardError: Pipe, args: [String]) -> Process {
		let proc = Process()
		proc.executableURL = executableURL
		proc.standardOutput = standardOutput
		proc.standardError = standardError
		if standardInput != nil {
			proc.standardInput = standardInput
		}
		if currentDirectory != nil {
			proc.currentDirectoryURL = currentDirectory
		}
		proc.arguments = args
		if env != nil {
			proc.environment = env
		}
		proc.qualityOfService = qualityOfService
		return proc
	}
}

/// A base class to hold functionailty for ProcessController. Do not use directly.
public class SPCBaseController: SPCBase {
	public static let separatorNewLine: UInt8 = "\n".data(using: .ascii)![0]
	public static let separatorNulChar: UInt8 = "\0".data(using: .ascii)![0]

	var stderrHandler: pipedDataHandler
	var termHandler: terminationHandler

	public var currentlyRunningProcess: Process?
	
	init(executableURL: URL, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler) {
		termHandler = terminationHandler
		self.stderrHandler = stderrHandler
		super.init(executableURL: executableURL)
	}
	
	func exitHandler(_ p: Process) {
		termHandler(p.terminationStatus)
	}
	
	func addReadHandler(fileHandle: FileHandle, handler: @escaping pipedDataHandler) {
		fileHandle.readabilityHandler = { fh in
			handler(fh.availableData)
		}
	}
	
	func startProcess(proc: Process) throws {
		try proc.run()
		currentlyRunningProcess = proc
		proc.waitUntilExit()
		currentlyRunningProcess = nil
	}
	
}
