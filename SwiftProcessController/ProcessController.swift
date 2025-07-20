//
//  SwiftProcessController.swift
//  SwiftProcessController
//

import Foundation

/// An object which launches a proess and handles output as it is generated.
public class ProcessController: SPCBaseController {
	
	private var stdoutHandler: pipedDataHandler
	
	/// Creates a ProcessController object.
	/// - Parameters:
	///   - executableURL: The executable binary to run.
	///   - stdoutHandler: Repeatedly called when new data is present in stdout.
	///   - stderrHandler: Repeatedly called when new data is present in stderr.
	///   - terminationHandler: Called when the process exits.
	public init(executableURL: URL, stdoutHandler: @escaping pipedDataHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler) {
		self.stdoutHandler = stdoutHandler
		super.init(executableURL: executableURL, stderrHandler: stderrHandler, terminationHandler: terminationHandler)
	}
	
	/// Creates a ProcessController object.
	/// - Parameters:
	///   - executablePath: The executable binary to run.
	///   - stdoutHandler: Repeatedly called when new data is present in stdout.
	///   - stderrHandler: Repeatedly called when new data is present in stderr.
	///   - terminationHandler: Called when the process exits.
	public convenience init(executablePath: String, stdoutHandler: @escaping pipedDataHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler) {
		self.init(executableURL: URL(localPath: executablePath), stdoutHandler: stdoutHandler, stderrHandler: stderrHandler, terminationHandler: terminationHandler)
	}
	
	/// Launches the command for monitoring. Returns after starting the process.
	/// - Parameter args: The list of arguments to use.
	/// - Parameter env: The enviorment dictionary.
	public func launch(args: [String], standardInput: Pipe? = nil) throws {
		let standardOutput = Pipe()
		let standardError = Pipe()
		
		let proc = CreateProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
		proc.terminationHandler = exitHandler(_:)
		setupReadHandler(fileHandle: standardOutput.fileHandleForReading, handler: self.stdoutHandler)
		setupReadHandler(fileHandle: standardError.fileHandleForReading, handler: self.stderrHandler)
		
		try startProcess(proc: proc)
	}
	
	/// Launches the command for monitoring. Returns when the process exits.
	/// - Parameter args: The list of arguments to use.
	/// - Parameter env: The enviorment dictionary.
	public func launchAndWaitUntilExit(args: [String], standardInput: Pipe? = nil) throws {
		let standardOutput = Pipe()
		let standardError = Pipe()
		
		let proc = CreateProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
		proc.terminationHandler = exitHandler(_:)
		setupReadHandler(fileHandle: standardOutput.fileHandleForReading, handler: self.stdoutHandler)
		setupReadHandler(fileHandle: standardError.fileHandleForReading, handler: self.stderrHandler)
		
		try startProcessAndWaitUntilExit(proc: proc)
	}
	
}
