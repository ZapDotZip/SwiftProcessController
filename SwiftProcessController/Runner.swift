//
//  Runner.swift
//  SwiftProcessController
//

import Foundation

public class Runner {
	
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
	
	private static let jsonDecoder = JSONDecoder()
	var execPath: URL
	
	public init(executableURL: URL) {
		execPath = executableURL
	}
	
	public init(executablePath: String) {
		execPath = URL(fileURLWithPath: executablePath)
	}
	
	// MARK: Run
	/// Runs with the provided arguments and returns the process output as a ProcessResult.
	/// - Parameter args: The list of arguments to use.
	public func run(args: [String], env: [String : String]?) throws -> ProcessResult {
		let proc = Process()
		let stdout = Pipe()
		let stderr = Pipe()
		proc.executableURL = execPath
		proc.standardOutput = stdout
		proc.standardError = stderr
		proc.arguments = args
		if env != nil {
			proc.environment = env
		}
		
		try proc.run()
		let out = stdout.fileHandleForReading.readDataToEndOfFile()
		let err = stderr.fileHandleForReading.readDataToEndOfFile()
		proc.waitUntilExit()
		return ProcessResult(output: out, error: err, exitStatus: proc.terminationStatus)
	}
	
	/// Runs with the provided arguments and returns the output as the provided Decodable class and stderr as a String, if any.
	/// - Parameters:
	///   - args: The list of arguments to use.
	///   - returning: The object type to return.
	public func run<T: Decodable>(args: [String], env: [String : String]?, returning: T.Type) throws -> ProcessResultTyped<T> {
		let result = try run(args: args, env: env)
		let obj = try Runner.jsonDecoder.decode(T.self, from: result.output)
		return ProcessResultTyped(output: obj, error: result.error, exitStatus: result.exitStatus)
	}
	
}
