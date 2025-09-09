//
//  SPCProcessDelegate.swift
//  SwiftProcessController
//

import Foundation

/// A protocol that is called when a Process emits processable data, or exits.
public protocol SPCProcessDelegate {
	/// Repeatedly called when new data is present in the process's `stdout`
	func stdoutHandler(_: Data)
	/// Repeatedly called when new data is present in the process's `stderr`
	func stderrHandler(_: Data)
	/// Called when the process exits.
	/// - Parameter exitCode: The exit code of the process.
	func terminationHandler(exitCode: Int32)
}

/// A protocol that is called when a Process emits processable data, or exits.
public protocol SPCProcessDecoderDelegate<D> {
	associatedtype D: Decodable
	/// Repeatedly called when new data is present in the process's `stdout`
	func stdoutHandler(_: SPCDecodedResult<D>)
	/// Repeatedly called when new data is present in the process's `stderr`
	func stderrHandler(_: Data)
	/// Called when the process exits.
	/// - Parameter exitCode: The exit code of the process.
	func terminationHandler(exitCode: Int32)
}
