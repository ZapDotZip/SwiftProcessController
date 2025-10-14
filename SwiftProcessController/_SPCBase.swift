//
//  _SPCBase.swift
//  SwiftProcessController
//

import Foundation

/// A base class to hold functionailty for both ``SPCRunner`` and ``SPCController``.
/// > Warning: Do not use directly.
public class _SPCBase {
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
	
	/// The IO Policy controls how the OS handles disk access priority, similar to how `QualityOfService` controls CPU usage.
	///
	/// See the `setiopolicy_np` man page for information about each type, and the `taskpolicy` man page for more information.
	public enum SPCIOPolicy {
		case important, standard, utility, throttle, passive
		internal func taskPolicyArgs() -> [String] {
			switch self {
			case .important: return ["-d", "important"]
			case .standard: return ["-d", "standard"]
			case .utility: return ["-d", "utility", "-g", "utility"]
			case .throttle: return ["-d", "throttle", "-g", "throttle"]
			case .passive: return ["-d", "passive"]
			}
		}
	}
	
	/// The IO policy to set for the process. Defaults to `nil` which does not set a policy, and macOS sets the default to important.
	///
	/// When set, the process is run through `taskpolicy`.
	public var ioPolicy: SPCIOPolicy?
	private static let taskpolicyURL = URL(localPath: "/usr/sbin/taskpolicy")
	
	/// The currently running process, if there is one.
	/// > Warning: Avoid working with this object directly, if possible.
	public var currentlyRunningProcess: Process?
	internal var isSuspended: Bool = false
	
	/// The state of the process.
	public var processState: ProcessState {
		guard currentlyRunningProcess != nil else {
			return .notRunning
		}
		if isSuspended {
			return .suspended
		} else {
			return .running
		}
	}
	
	internal static let jsonDecoder = JSONDecoder()
	internal static let plistDecoder = PropertyListDecoder()
	
	
	internal init(executableURL: URL) {
		self.executableURL = executableURL
	}
	
	internal convenience init(executablePath: String) {
		self.init(executableURL: URL(localPath: executablePath))
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
	
	/// Sends a `SIGINT` to the running process, if it exists.
	public func interrupt() {
		if let currentlyRunningProcess {
			currentlyRunningProcess.interrupt()
		}
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
	public func kill() throws(SPCSignalError) {
		try signal(signal: SIGKILL)
	}
	
	/// Kills the process via `SIGKILL`, waiting for the process to exit before returning.
	public func killAndWaitForExit() throws(SPCSignalError) {
		try kill()
		currentlyRunningProcess?.waitUntilExit()
	}
	
	/// Sends the signal to the process.
	/// > Warning: Do not use `SIGSTOP`/`SIGCONT` and the `suspend()`/`resume()` functions at the same time.
	/// - Parameter signal: The signal to send.
	public func signal(signal: Int32) throws(SPCSignalError) {
		if let currentlyRunningProcess {
			let res = _signal.kill(currentlyRunningProcess.processIdentifier, SIGTERM)
			if res != 0 {
				throw SPCSignalError(errCode: res)
			}
		}
	}
	
	/// Creates a new Process object based off the provided arguments and class variables.
	/// - Parameters:
	///   - standardOutput: Pipe for the process's output
	///   - standardError: Pipe for the process's error
	///   - args: Process arguments
	/// - Returns: New Process object
	internal func createProcessObject(standardOutput: Pipe, standardError: Pipe, args: [String]) -> Process {
		let proc = Process()
		
		if let ioPolicy {
			proc.executableURL = _SPCBase.taskpolicyURL
			var args = ioPolicy.taskPolicyArgs()
			args.append(executableURL.localPath)
			args.append(contentsOf: args)
			proc.arguments = args
		} else {
			proc.executableURL = executableURL
			proc.arguments = args
		}
		
		proc.standardOutput = standardOutput
		proc.standardError = standardError
		if standardInput != nil {
			proc.standardInput = standardInput
		}
		if currentDirectory != nil {
			proc.currentDirectoryURL = currentDirectory
		}
		if env != nil {
			proc.environment = env
		}
		proc.qualityOfService = qualityOfService
		return proc
	}
}
