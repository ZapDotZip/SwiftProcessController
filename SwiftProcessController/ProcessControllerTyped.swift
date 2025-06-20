//
//  ProcessControllerTyped.swift
//  SwiftProcessController
//

import Foundation

/// An object which launches a proess and decodes output to an object as it is generated.
public class ProcessControllerTyped<T: Decodable>: SPCBaseController {
	public typealias typedHandler = (T) -> Void
	public typealias errorHandler = (Error, Data) -> Void
	
	private let objectHandler: typedHandler
	private let separator: UInt8
	private var decoderFunc: pipedDataHandler!
	private let errHandler: errorHandler
	
	private let jsonDecoder = JSONDecoder()
	private let plistDecoder = PropertyListDecoder()
	
	private var partial = Data()
	
	public init(executableURL: URL, stdoutHandler: @escaping typedHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler, decoderType: ProcessResultDecoder, errHandler: @escaping errorHandler, separator: UInt8 = separatorNewLine) {
		self.objectHandler = stdoutHandler
		self.separator = separator
		self.errHandler = errHandler
		super.init(executableURL: executableURL, stderrHandler: stderrHandler, terminationHandler: terminationHandler)
		switch decoderType {
			case .JSON:
				decoderFunc = generateTypedObjectJSON
			case .PropertyList:
				decoderFunc = generateTypedObjectPropertyList
		}
	}
	
	public convenience init(executablePath: String, stdoutHandler: @escaping typedHandler, stderrHandler: @escaping pipedDataHandler, terminationHandler: @escaping terminationHandler, decoderType: ProcessResultDecoder, errHandler: @escaping errorHandler, separator: UInt8 = separatorNewLine) {
		self.init(executableURL: URL(fileURLWithPath: executablePath), stdoutHandler: stdoutHandler, stderrHandler: stderrHandler, terminationHandler: terminationHandler, decoderType: decoderType, errHandler: errHandler, separator: separator)
	}
	
	/// Creates the `T` object from the provided JSON data, then calls the objectHandler on the object.
	/// - Parameter data: The data to decode into an object.
	private func generateTypedObjectJSON(_ data: Data) {
		do {
			let obj = try jsonDecoder.decode(T.self, from: data)
			objectHandler(obj)
		} catch {
			errHandler(error, data)
		}
	}
	
	/// Creates the `T` object from the provided Property List data, then calls the objectHandler on the object.
	/// - Parameter data: The data to decode into an object.
	private func generateTypedObjectPropertyList(_ data: Data) {
		do {
			let obj = try plistDecoder.decode(T.self, from: data)
			objectHandler(obj)
		} catch {
			errHandler(error, data)
		}
	}
	
	/// Repeatedly called to append new data to partial data, then splits the data as necessary to call the object handler.
	/// - Parameter data: The new data to add.
	func read(_ data: Data) {
		partial.append(data)
		var splits = partial.split(separator: separator)
		if partial.last != separator {
			if let last = splits.popLast() {
				partial = last
			}
		} else {
			partial = Data()
		}
		for i in splits {
			decoderFunc(i)
		}
	}
	
	/// Ensures the rest of the data is processed before exiting.
	func typedExitHandler(_ p: Process) {
		if partial.count != 0 {
			decoderFunc(partial)
		}
		exitHandler(p)
	}
	
	/// Starts the process and returns, letting it run in the background.
	/// - Parameters:
	///   - args: Process arguments
	///   - standardInput: Standard input provided to the process, if any.
	public func launch(args: [String], standardInput: Pipe? = nil) throws {
		let standardOutput = Pipe()
		let standardError = Pipe()
		
		let proc = CreateProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
		proc.terminationHandler = typedExitHandler(_:)
		setupReadHandler(fileHandle: standardOutput.fileHandleForReading, handler: self.read(_:))
		setupReadHandler(fileHandle: standardError.fileHandleForReading, handler: self.stderrHandler)
		try startProcess(proc: proc)
	}
	
	/// Starts the process, then waits for it to exit.
	/// - Parameters:
	///   - args: Process arguments
	///   - standardInput: Standard input provided to the process, if any.
	public func launchAndWaitUntilExit(args: [String], standardInput: Pipe? = nil) throws {
		try launch(args: args, standardInput: standardInput)
		currentlyRunningProcess?.waitUntilExit()
	}
	
}
