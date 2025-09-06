//
//  SPCProcessResult.swift
//  SwiftProcessController
//

import Foundation

public struct SPCProcessResult {
	public let output: Data
	public let error: Data
	public let exitStatus: Int32
	public func outputString() -> String? {
		String.init(data: output, encoding: .utf8)
	}
	public func errorString() -> String? {
		String.init(data: error, encoding: .utf8)
	}
}

public struct SPCProcessResultTyped<T> {
	public let output: T
	public let error: Data
	public let exitStatus: Int32
	public func errorString() -> String? {
		String.init(data: error, encoding: .utf8)
	}
}
