//
//  PublicTypes.swift
//  SwiftProcessController
//

import Foundation

public typealias pipedDataHandler = (Data) -> Void
public typealias terminationHandler = (Int32) -> Void

public enum ProcessControllerError: Error {
	case couldNotDecodeStringOutput
	case couldNotDecodeJSON(String, String)
}

public enum ProcessResultDecoder {
	case JSON
	case PropertyList
}

/// Decoded object or error from attempted decoding of data.
public enum StreamingProcessResult<T> {
	case object(output: T)
	case error(rawData: Data, err: Error)
}

public enum ProcessState {
	/// There is no running process.
	case notRunning
	/// There is an active process running.
	case running
	/// There is an active process which is suspended.
	case suspended
}

/// Wrapper around POSIX error responses from kill()
public enum SignalError: Error {
	case invalid
	case incorrectPermissions
	case processDoesNotExists
	case unknownError(Int32)
	public init(errCode: Int32) {
		switch errCode {
			case EINVAL:
				self = .invalid
			case EPERM:
				self = .incorrectPermissions
			case ESRCH:
				self = .processDoesNotExists
			default:
				self = .unknownError(errCode)
		}
	}
	
	public var localizedDescription: String {
		switch self {
			case .invalid:
				return NSLocalizedString("Sig is not a valid, supported signal number.", comment: "Sig is not a valid, supported signal number.")
			case .incorrectPermissions:
				return NSLocalizedString("The sending process is not the super-user and its effective user id does not match the effective user-id of the receiving process.  When signaling a process group, this error is returned if any members of the group could not be signaled.", comment: "The sending process is not the super-user and its effective user id does not match the effective user-id of the receiving process.  When signaling a process group, this error is returned if any members of the group could not be signaled.")
			case .processDoesNotExists:
				return NSLocalizedString("No process or process group can be found corresponding to that specified by pid.", comment: "No process or process group can be found corresponding to that specified by pid.")
			case .unknownError(let unknown):
				return NSLocalizedString("An unknown error was received: \(unknown)", comment: "An unknown error was received")
		}
	}
}
