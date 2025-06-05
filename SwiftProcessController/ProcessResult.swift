//
//  ProcessResult.swift
//  SwiftProcessController
//

import Foundation

public struct ProcessResult {
	let output: Data
	let error: Data
	let exitStatus: Int32
	func outputString() -> String? {
		String.init(data: output, encoding: .utf8)
	}
	func errorString() -> String? {
		String.init(data: error, encoding: .utf8)
	}
}

public struct ProcessResultTyped<T> {
	let output: T
	let error: Data
	let exitStatus: Int32
	lazy var errorString: String? = {
		String.init(data: error, encoding: .utf8)
	}()
}
