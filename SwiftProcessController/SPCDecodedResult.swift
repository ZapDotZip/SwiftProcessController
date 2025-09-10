//
//  SPCDecodedResult.swift
//  SwiftProcessController
//

import Foundation

/// An enum consisting of the decoded object or an error from the failed attempt to decode the data.
public enum SPCDecodedResult<D: Decodable> {
	/// The decoded object.
	case object(output: D)
	/// The error that occured while trying to decode the data.
	/// - Parameter rawData: The data that could not be decoded.
	/// - Parameter decodingError: The error that occured while trying to decode the data.
	case error(rawData: Data, decodingError: Error)
	
	init(data: Data, decoder: SPCResultDecoderType, type: D.Type) {
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
