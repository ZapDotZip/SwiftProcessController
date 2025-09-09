//
//  SPCProcessResult.swift
//  SwiftProcessController
//

import Foundation

/// Contains the output, standard error, and exit status of the program.
public struct SPCProcessResult {
	/// The output of the program.
	public let output: Data
	/// The standard error of the program.
	public let stdError: Data
	/// The exit code of the program.
	public let exitStatus: Int32
	/// Returns a UTF-8 string from the output data, if possible.
	public func outputString() -> String? {
		String.init(data: output, encoding: .utf8)
	}
	/// Returns a UTF-8 string from the error data, if possible.
	public func errorString() -> String? {
		String.init(data: stdError, encoding: .utf8)
	}
}

public struct SPCProcessResultDecoded<D: Decodable> {
	/// The output of the program.
	public let output: SPCDecodedResult<D>
	/// The standard error of the program.
	public let stdError: Data
	/// The exit code of the program.
	public let exitStatus: Int32
	/// Returns a UTF-8 string from the error data, if possible.
	public func stdErrorString() -> String? {
		String.init(data: stdError, encoding: .utf8)
	}
}
