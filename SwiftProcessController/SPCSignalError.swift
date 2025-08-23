//
//  SPCSignalError.swift
//  SwiftProcessController
//
//

import Foundation

/// Wrapper around POSIX error responses from kill()
public enum SPCSignalError: Error {
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
