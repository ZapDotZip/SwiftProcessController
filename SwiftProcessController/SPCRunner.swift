//
//  SPCRunner.swift
//  SwiftProcessController
//

import Foundation

public class SPCRunner: _SPCBase {
	
	public override init(executableURL: URL) {
		super.init(executableURL: executableURL)
	}
	
	public convenience init(executablePath: String) {
		self.init(executableURL: URL(localPath: executablePath))
	}
	
	// MARK: Run
	/// Runs with the provided arguments and returns the process output as an ``SPCResult``.
	/// - Parameter args: The list of arguments to use.
	public func run(args: [String]) throws -> SPCResult {
		
		let standardOut = Pipe()
		let standardErr = Pipe()
		
		let proc = createProcessObject(standardOutput: standardOut, standardError: standardErr, args: args)
		
		try proc.run()
		currentlyRunningProcess = proc
		let out = standardOut.fileHandleForReading.readDataToEndOfFile()
		let err = standardErr.fileHandleForReading.readDataToEndOfFile()
		proc.waitUntilExit()
		currentlyRunningProcess = nil
		return SPCResult(output: out, stdError: err, exitStatus: proc.terminationStatus)
	}
	
	/// Runs with the provided arguments and returns the output as the provided Decodable class and stderr as a String, if any.
	/// - Parameters:
	///   - args: The list of arguments to use.
	///   - returning: The object type to return.
	///   - decodingWith: The type of decoder to use.
	/// - Returns: A process result which contains the output, standard error, and exit status of the program.
	public func run<T: Decodable>(args: [String], returning: T.Type, decodingWith: SPCResultDecoderType) throws -> SPCResultDecoded<T> {
		let result = try run(args: args)
		let obj = SPCDecodedResult.init(data: result.output, decoder: decodingWith, type: T.self)
		return SPCResultDecoded(output: obj, stdError: result.stdError, exitStatus: result.exitStatus)
	}
	
}
