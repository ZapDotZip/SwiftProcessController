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

/// Decoded object or error from attempted decoding of data.
public enum SPCStreamingResult<T> {
	/// The decoded object.
	case object(output: T)
	/// The error that occured while trying to decode the data.
	/// - Parameter rawData: The data that could not be decoded.
	/// - Parameter decodingError: The error that occured while trying to decode the data.
	case error(rawData: Data, decodingError: Error)
}

public enum ProcessState {
	/// There is no running process.
	case notRunning
	/// There is an active process running.
	case running
	/// There is an active process which is suspended.
	case suspended
}

