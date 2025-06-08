//
//  SwiftProcessController.swift
//  SwiftProcessController
//

import Foundation


public class ProcessController {
	
	public var execURL: URL
	public var qualityOfService: QualityOfService = .default
	
	public init(executableURL: URL, stdoutHandler: @escaping pipedDataHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler) {
		execURL = executableURL
		self.stdoutHandler = stdoutHandler
		self.stderrHandler = stderrHandler
		self.termHandler = terminationHandler
	}
	
	public convenience init(executablePath: String, stdoutHandler: @escaping pipedDataHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler) {
		self.init(executableURL: URL(fileURLWithPath: executablePath), stdoutHandler: stdoutHandler, stderrHandler: stderrHandler, terminationHandler: terminationHandler)
	}
	
	private var stdoutHandler: pipedDataHandler!
	private var stderrHandler: pipedDataHandler!
	private var termHandler: terminationHandler!
	
	private func exit(_ p: Process) {
		termHandler(p.terminationStatus)
	}
	
	
	public var currentlyRunningProcess: Process?
	/// Launches the command for monitoring.
	/// - Parameter args: The list of arguments to use.
	/// - Parameter env: The enviorment dictionary.
	/// - Parameter stdoutHandler: Repeatedly called when new data is present in stdout.
	/// - Parameter stderrHandler: Repeatedly called when new data is present in stderr.
	/// - Parameter terminationHandler: Called when the process exits.
	public func launch(args: [String], env: [String : String]?) throws {
		
		let proc = Process()
		let stdout = Pipe()
		let stderr = Pipe()
		proc.executableURL = execURL
		proc.standardOutput = stdout
		proc.standardError = stderr
		proc.arguments = args
		if env != nil {
			proc.environment = env
		}
		proc.qualityOfService = qualityOfService
		
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdout.fileHandleForReading, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			self.stdoutHandler(handle.availableData)
			handle.waitForDataInBackgroundAndNotify()
		}
		
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stderr.fileHandleForReading, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			self.stderrHandler(handle.availableData)
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
