//
//  SwiftProcessController.swift
//  SwiftProcessController
//

import Foundation


public class ProcessController {
	
	private static let jsonDecoder = JSONDecoder()
	var execPath: URL
	
	public init(executableURL: URL) {
		execPath = executableURL
	}
	
	public init(executablePath: String) {
		execPath = URL(fileURLWithPath: executablePath)
	}
	
	// MARK: launch
	
	let newLine: UInt8 = "\n".data(using: .ascii)![0]
	var partial: Data = Data()
	var readHandler: pipedDataHandler!
	var errHandler: pipedDataHandler!
	var termHandler: terminationHandler!
	
	public func read(_ data: Data) {
		partial.append(data)
		var splits = partial.split(separator: newLine)
		let last: Data? = splits.popLast()
		for i in splits {
			readHandler(i)
		}
		if last != nil {
			if JSONSerialization.isValidJSONObject(last as Any) {
				readHandler(last!)
				partial = Data()
			} else {
				partial = last!
				partial.append(newLine)
			}
		}
	}
	
	public func exit(_ p: Process) {
		readHandler(partial)
		termHandler(p.terminationStatus)
	}
	
	
	public var currentlyRunningProcess: Process?
	/// Launches the command for monitoring.
	/// - Parameter args: The list of arguments to use.
	/// - Parameter env: The enviorment dictionary.
	/// - Parameter stdoutHandler: Repeatedly called when new data is present in stdout.
	/// - Parameter stderrHandler: Repeatedly called when new data is present in stderr.
	/// - Parameter terminationHandler: Called when the process exits.
	public func launch(args: [String], env: [String : String]?, stdoutHandler: @escaping pipedDataHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler, qos: QualityOfService) throws {
		partial = Data()
		readHandler = stdoutHandler
		errHandler = stderrHandler
		termHandler = terminationHandler
		
		let proc = Process()
		let stdout = Pipe()
		let stderr = Pipe()
		proc.executableURL = execPath
		proc.standardOutput = stdout
		proc.standardError = stderr
		proc.arguments = args
		if env != nil {
			proc.environment = env
		}
		
		proc.qualityOfService = qos
		
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdout.fileHandleForReading, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			self.read(handle.availableData)
			handle.waitForDataInBackgroundAndNotify()
		}
		
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stderr.fileHandleForReading, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			let data = handle.availableData
			stderrHandler(data)
			handle.waitForDataInBackgroundAndNotify()
		}
		
		proc.terminationHandler = exit(_:)
		currentlyRunningProcess = proc
		try proc.run()
		stdout.fileHandleForReading.waitForDataInBackgroundAndNotify()
		stderr.fileHandleForReading.waitForDataInBackgroundAndNotify()
		proc.waitUntilExit()
		currentlyRunningProcess = nil
	}
	
}
