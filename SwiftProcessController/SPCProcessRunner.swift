//
//  SPCProcessRunner.swift
//  SwiftProcessController
//

import Foundation

public class SPCProcessRunner: _SPCBase {
	
	public override init(executableURL: URL) {
		super.init(executableURL: executableURL)
	}
	
	public convenience init(executablePath: String) {
		self.init(executableURL: URL(localPath: executablePath))
	}
	
	// MARK: Run
	/// Runs with the provided arguments and returns the process output as an SPCProcessResult.
	/// - Parameter args: The list of arguments to use.
	public func run(args: [String]) throws -> SPCProcessResult {
		
		let standardOut = Pipe()
		let standardErr = Pipe()
		
		let proc = createProcessObject(standardOutput: standardOut, standardError: standardErr, args: args)
		
		try proc.run()
		currentlyRunningProcess = proc
		let out = standardOut.fileHandleForReading.readDataToEndOfFile()
		let err = standardErr.fileHandleForReading.readDataToEndOfFile()
		proc.waitUntilExit()
		currentlyRunningProcess = nil
		return SPCProcessResult(output: out, error: err, exitStatus: proc.terminationStatus)
	}
	
	/// Runs with the provided arguments and returns the output as the provided Decodable class and stderr as a String, if any.
	/// - Parameters:
	///   - args: The list of arguments to use.
	///   - returning: The object type to return.
	public func run<T: Decodable>(args: [String], returning: T.Type, decodingWith: SPCProcessResultDecoder) throws -> SPCProcessResultTyped<T> {
		let result = try run(args: args)
		let obj = try {
			switch decodingWith {
			case .JSON:
				return try SPCProcessRunner.jsonDecoder.decode(T.self, from: result.output)
			case .PropertyList:
				return try SPCProcessRunner.plistDecoder.decode(T.self, from: result.output)
			}
		}()
		return SPCProcessResultTyped(output: obj, error: result.error, exitStatus: result.exitStatus)
	}
	
}
