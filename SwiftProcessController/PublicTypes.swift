//
//  PublicTypes.swift
//  SwiftProcessController
//

import Foundation

public typealias PipedDataHandler = (Data) -> Void
public typealias TerminationHandler = (Int32) -> Void

public enum ProcessControllerError: Error {
	case couldNotDecodeStringOutput
	case couldNotDecodeJSON(String, String)
}

public enum SPCProcessResultDecoder {
	case JSON
	case PropertyList
}

public enum ProcessState {
	/// There is no running process.
	case notRunning
	/// There is an active process running.
	case running
	/// There is an active process which is suspended.
	case suspended
}

