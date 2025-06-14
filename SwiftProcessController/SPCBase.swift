//
//  SPCBase.swift
//  SwiftProcessController
//

import Foundation

public class SPCBase {
	public var executableURL: URL
	public var env: [String : String]?
	public var standardInput: Pipe?
	public var currentDirectory: URL?
	public var qualityOfService: QualityOfService = .default
	
	public init(executableURL: URL) {
		self.executableURL = executableURL
	}
	
	public convenience init(executablePath: String) {
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

public class SPCBaseController: SPCBase {
	public static let separatorNewLine: UInt8 = "\n".data(using: .ascii)![0]
	public static let separatorNulChar: UInt8 = "\0".data(using: .ascii)![0]

	var stderrHandler: pipedDataHandler
	var termHandler: terminationHandler

	public var currentlyRunningProcess: Process?
	
	public init(executableURL: URL, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler) {
		termHandler = terminationHandler
		self.stderrHandler = stderrHandler
		super.init(executableURL: executableURL)
	}
	
	func exitHandler(_ p: Process) {
		termHandler(p.terminationStatus)
	}
	
	func addToNC(fileHandle: FileHandle, handler: @escaping pipedDataHandler) {
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: fileHandle, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			handler(handle.availableData)
			handle.waitForDataInBackgroundAndNotify()
		}
		fileHandle.waitForDataInBackgroundAndNotify()
	}
	
	func startProcess(proc: Process) throws {
		try proc.run()
		currentlyRunningProcess = proc
		proc.waitUntilExit()
		currentlyRunningProcess = nil
	}
	
}
