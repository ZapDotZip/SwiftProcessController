//
//  _SPCBaseController.swift
//  SwiftProcessController
//

import Foundation

/// A base class to hold functionailty for SPCProcessController.
/// > Warning: Do not use directly.
public class _SPCBaseController: _SPCBase {
	public static let separatorNewLine: UInt8 = 0x0A
	public static let separatorNulChar: UInt8 = 0x00

	internal var stderrHandler: PipedDataHandler
	internal var termHandler: TerminationHandler
	
	internal init(executableURL: URL, stderrHandler: @escaping PipedDataHandler, terminationHandler: @escaping TerminationHandler) {
		termHandler = terminationHandler
		self.stderrHandler = stderrHandler
		super.init(executableURL: executableURL)
	}
	
	/// Default exit handler which sets the current process to nil and calls the user-provided `termHandler`.
	internal func exitHandler(_ p: Process) {
		currentlyRunningProcess = nil
		termHandler(p.terminationStatus)
	}
	
	/// Sets a read handler to repeatedly recieve data from a FileHandle
	internal func setupReadHandler(fileHandle: FileHandle, handler: @escaping PipedDataHandler) {
		fileHandle.readabilityHandler = { fileHandle in
			handler(fileHandle.availableData)
		}
	}
	
	/// Starts the process.
	/// - Parameter proc: The process to start
	internal func startProcess(proc: Process) throws {
		try proc.run()
		currentlyRunningProcess = proc
	}
	
	/// Starts the process and waits for it to exit.
	/// - Parameter proc: The process to start
	internal func startProcessAndWaitUntilExit(proc: Process) throws {
		try proc.run()
		currentlyRunningProcess = proc
		proc.waitUntilExit()
	}
	
	override func createProcessObject(standardOutput: Pipe, standardError: Pipe, args: [String]) -> Process {
		let proc = super.createProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		proc.terminationHandler = exitHandler(_:)
		return proc
	}
	
}
