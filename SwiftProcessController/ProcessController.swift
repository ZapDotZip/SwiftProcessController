//
//  SwiftProcessController.swift
//  SwiftProcessController
//

import Foundation

public class ProcessController: SPCBase {
	
	public init(executableURL: URL, stdoutHandler: @escaping pipedDataHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler) {
		super.init(execURL: executableURL)
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
	public func launch(args: [String], standardInput: Pipe? = nil) throws {
		
		let standardOutput = Pipe()
		let standardError = Pipe()
		
		let proc = CreateProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: standardOutput.fileHandleForReading, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			self.stdoutHandler(handle.availableData)
			handle.waitForDataInBackgroundAndNotify()
		}
		
		NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: standardError.fileHandleForReading, queue: nil) { (notif) in
			let handle = notif.object as! FileHandle
			self.stderrHandler(handle.availableData)
			handle.waitForDataInBackgroundAndNotify()
		}
		
		proc.terminationHandler = exit(_:)
		currentlyRunningProcess = proc
		try proc.run()
		standardOutput.fileHandleForReading.waitForDataInBackgroundAndNotify()
		standardError.fileHandleForReading.waitForDataInBackgroundAndNotify()
		proc.waitUntilExit()
		currentlyRunningProcess = nil
	}
	
}
