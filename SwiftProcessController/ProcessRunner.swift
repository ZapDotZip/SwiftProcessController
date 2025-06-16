//
//  Runner.swift
//  SwiftProcessController
//

import Foundation

public class ProcessRunner: SPCBase {
	
	private static let jsonDecoder = JSONDecoder()
	
	// MARK: Run
	/// Runs with the provided arguments and returns the process output as a ProcessResult.
	/// - Parameter args: The list of arguments to use.
	public func run(args: [String]) throws -> ProcessResult {
		
		let standardOut = Pipe()
		let standardErr = Pipe()
		
		let proc = CreateProcessObject(standardOutput: standardOut, standardError: standardErr, args: args)
		
		try proc.run()
		currentlyRunningProcess = proc
		let out = standardOut.fileHandleForReading.readDataToEndOfFile()
		let err = standardErr.fileHandleForReading.readDataToEndOfFile()
		proc.waitUntilExit()
		currentlyRunningProcess = nil
		return ProcessResult(output: out, error: err, exitStatus: proc.terminationStatus)
	}
	
	/// Runs with the provided arguments and returns the output as the provided Decodable class and stderr as a String, if any.
	/// - Parameters:
	///   - args: The list of arguments to use.
	///   - returning: The object type to return.
	public func run<T: Decodable>(args: [String], returning: T.Type) throws -> ProcessResultTyped<T> {
		let result = try run(args: args)
		let obj = try ProcessRunner.jsonDecoder.decode(T.self, from: result.output)
		return ProcessResultTyped(output: obj, error: result.error, exitStatus: result.exitStatus)
	}
	
}
