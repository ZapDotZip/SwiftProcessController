//
//  SPCBase.swift
//  SwiftProcessController
//

import Foundation

/// A base class to hold functionailty for both `ProcessRunner` and `ProcessController`.
/// > Warning: Do not use directly.
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
	
	/// The currently running process, if there is one.
	/// > Warning: Avoid working with this object directly, if possible.
	public var currentlyRunningProcess: Process?
	var isSuspended: Bool = false
	
	/// The state of the process.
	public var processState: ProcessState {
		get {
			guard currentlyRunningProcess != nil else {
				return .notRunning
			}
			if isSuspended {
				return .suspended
			} else {
				return .running
			}
		}
	}
	
	init(executableURL: URL) {
		self.executableURL = executableURL
	}
	
	convenience init(executablePath: String) {
		self.init(executableURL: URL(fileURLWithPath: executablePath))
	}
	
	/// Suspends the currently running process.
	/// - Returns: true if the process was suspended, false if otherwise.
	public func suspend() -> Bool {
		if let currentlyRunningProcess, !isSuspended {
			if currentlyRunningProcess.suspend() {
				isSuspended = true
				return true
			}
		}
		return false
	}
	
	/// Resumes the currently running process.
	/// - Returns: True if the process was suspended, false if otherwise.
	public func resume() -> Bool {
		if let currentlyRunningProcess, isSuspended {
			if currentlyRunningProcess.resume() {
				isSuspended = false
				return true
			}
		}
		return false
	}
	
	/// Sends a `SIGTERM` to the running process, if it exists.
	public func terminate() {
		if let currentlyRunningProcess {
			currentlyRunningProcess.terminate()
		}
	}
	
	/// Sends a `SIGTERM` to the running process, if it exists, then waits for the process to exit before returning.
	public func terminateAndWaitForExit() {
		terminate()
		currentlyRunningProcess?.waitUntilExit()
	}
	
	/// Kills the process via `SIGKILL`.
	public func kill() throws {
		try signal(signal: SIGKILL)
	}
	
	/// Kills the process via `SIGKILL`, waiting for the process to exit before returning.
	public func killAndWaitForExit() throws {
		try kill()
		currentlyRunningProcess?.waitUntilExit()
	}
	
	/// Sends the signal to the process.
	/// > Warning: Do not use `SIGSTOP`/`SIGCONT` and the `suspend()`/`resume()` functions at the same time.
	/// - Parameter signal: The signal to send.
	public func signal(signal: Int32) throws(SignalError) {
		if let currentlyRunningProcess {
			let res = _signal.kill(currentlyRunningProcess.processIdentifier, SIGTERM)
			if res != 0 {
				throw SignalError(errCode: res)
			}
		}
	}
	
	/// Creates a new Process object based off the provided arguments and class variables.
	/// - Parameters:
	///   - standardOutput: Pipe for the process's output
	///   - standardError: Pipe for the process's error
	///   - args: Process arguments
	/// - Returns: New Process object
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
	public static let separatorNewLine: UInt8 = 0x0A
	public static let separatorNulChar: UInt8 = 0x00

	var stderrHandler: pipedDataHandler
	var termHandler: terminationHandler
	
	init(executableURL: URL, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler) {
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
	func setupReadHandler(fileHandle: FileHandle, handler: @escaping pipedDataHandler) {
		fileHandle.readabilityHandler = { fh in
			handler(fh.availableData)
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
