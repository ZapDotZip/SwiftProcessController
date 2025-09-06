//
//  SwiftProcessController.swift
//  SwiftProcessController
//

import Foundation

/// An object which launches a proess and handles output as it is generated.
public class SPCProcessController: _SPCBaseController {
	
	private let delegate: SPCProcessDelegate
	
	/// Creates an SPCProcessController object.
	/// - Parameters:
	///   - executableURL: The executable binary to run.
	///   - delegate: Repeatedly called when the process outputs new data to stdout, stderr, or when the process exits.
	public init(executableURL: URL, delegate: SPCProcessDelegate) {
		self.delegate = delegate
		super.init(executableURL: executableURL, stderrHandler: delegate.stderrHandler, terminationHandler: delegate.terminationHandler(exitCode:))
	}
	
	/// Creates an SPCProcessController object.
	/// - Parameters:
	///   - executablePath: The executable binary to run.
	///   - delegate: Repeatedly called when the process outputs new data to stdout, stderr, or when the process exits.
	public convenience init(executablePath: String, delegate: SPCProcessDelegate) {
		self.init(executableURL: URL(localPath: executablePath), delegate: delegate)
	}
	
	/// Launches the command for monitoring. Returns after starting the process.
	/// - Parameter args: The list of arguments to use.
	/// - Parameter env: The enviorment dictionary.
	public func launch(args: [String], standardInput: Pipe? = nil) throws {
		let standardOutput = Pipe()
		let standardError = Pipe()
		
		let proc = createProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
		setupReadHandler(fileHandle: standardOutput.fileHandleForReading, handler: delegate.stdoutHandler)
		setupReadHandler(fileHandle: standardError.fileHandleForReading, handler: delegate.stderrHandler)
		
		try startProcess(proc: proc)
	}
	
	/// Launches the command for monitoring. Returns when the process exits.
	/// - Parameter args: The list of arguments to use.
	/// - Parameter env: The enviorment dictionary.
	public func launchAndWaitUntilExit(args: [String], standardInput: Pipe? = nil) throws {
		let standardOutput = Pipe()
		let standardError = Pipe()
		
		let proc = createProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
		setupReadHandler(fileHandle: standardOutput.fileHandleForReading, handler: delegate.stdoutHandler)
		setupReadHandler(fileHandle: standardError.fileHandleForReading, handler: delegate.stderrHandler)
		
		try startProcessAndWaitUntilExit(proc: proc)
	}
	
}
