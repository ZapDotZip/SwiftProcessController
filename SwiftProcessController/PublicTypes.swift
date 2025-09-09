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
public enum SPCDecodedResult<D: Decodable> {
	/// The decoded object.
	case object(output: D)
	/// The error that occured while trying to decode the data.
	/// - Parameter rawData: The data that could not be decoded.
	/// - Parameter decodingError: The error that occured while trying to decode the data.
	case error(rawData: Data, decodingError: Error)
	
	init(data: Data, decoder: SPCProcessResultDecoder, type: D.Type) {
		do {
			switch decoder {
			case .JSON: self = .object(output: try _SPCBase.jsonDecoder.decode(D.self, from: data))
			case .PropertyList: self = .object(output: try _SPCBase.plistDecoder.decode(D.self, from: data))
			}
		} catch {
			self = .error(rawData: data, decodingError: error)
		}
	}
}

public enum ProcessState {
	/// There is no running process.
	case notRunning
	/// There is an active process running.
	case running
	/// There is an active process which is suspended.
	case suspended
}

