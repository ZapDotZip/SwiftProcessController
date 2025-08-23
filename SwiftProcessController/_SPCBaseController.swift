//
//  _SPCBaseController.swift
//  SwiftProcessController
//

import Foundation

/// A base class to hold functionailty for SPCProcessController. Do not use directly.
public class _SPCBaseController: _SPCBase {
	public static let separatorNewLine: UInt8 = 0x0A
	public static let separatorNulChar: UInt8 = 0x00

	var stderrHandler: PipedDataHandler
	var termHandler: TerminationHandler
	
	init(executableURL: URL, stderrHandler: @escaping PipedDataHandler, terminationHandler: @escaping TerminationHandler) {
		termHandler = terminationHandler
		self.stderrHandler = stderrHandler
		super.init(executableURL: executableURL)
	}
	
	/// Default exit handler which sets the current process to nil and calls the user-provided `termHandler`.
	func exitHandler(_ p: Process) {
		currentlyRunningProcess = nil
		termHandler(p.terminationStatus)
	}
	
	/// Sets a read handler to repeatedly recieve data from a FileHandle
	func setupReadHandler(fileHandle: FileHandle, handler: @escaping PipedDataHandler) {
		fileHandle.readabilityHandler = { fileHandle in
			handler(fileHandle.availableData)
		}
	}
	
	/// Starts the process.
	/// - Parameter proc: The process to start
	func startProcess(proc: Process) throws {
		try proc.run()
		currentlyRunningProcess = proc
	}
	
	/// Starts the process and waits for it to exit.
	/// - Parameter proc: The process to start
	func startProcessAndWaitUntilExit(proc: Process) throws {
		try proc.run()
		currentlyRunningProcess = proc
		proc.waitUntilExit()
	}
	
}
