//
//  ProcessControllerTyped.swift
//  SwiftProcessController
//

import Foundation

/// An object which launches a proess and decodes output to an object as it is generated.
public class ProcessControllerTyped<T: Decodable>: _SPCBaseController {
	public typealias TypedHandler = (StreamingProcessResult<T>) -> Void
	public typealias ErrorHandler = (Error, Data) -> Void
	
	private let objectHandler: TypedHandler
	private let separator: UInt8
	private var decoderFunc: PipedDataHandler!
	
	private var partial = Data()
	
	public init(executableURL: URL, stdoutHandler: @escaping TypedHandler,
				stderrHandler: @escaping PipedDataHandler, terminationHandler: @escaping TerminationHandler,
				decoderType: SPCProcessResultDecoder, separator: UInt8 = separatorNewLine) {
		self.objectHandler = stdoutHandler
		self.separator = separator
		super.init(executableURL: executableURL, stderrHandler: stderrHandler, terminationHandler: terminationHandler)
		switch decoderType {
			case .JSON:
				decoderFunc = generateTypedObjectJSON
			case .PropertyList:
				decoderFunc = generateTypedObjectPropertyList
		}
	}
	
	public convenience init(executablePath: String, stdoutHandler: @escaping TypedHandler,
							stderrHandler: @escaping PipedDataHandler, terminationHandler: @escaping TerminationHandler,
							decoderType: SPCProcessResultDecoder, separator: UInt8 = separatorNewLine) {
		self.init(executableURL: URL(localPath: executablePath), stdoutHandler: stdoutHandler, stderrHandler: stderrHandler, terminationHandler: terminationHandler, decoderType: decoderType, separator: separator)
	}
	
	/// Creates the `T` object from the provided JSON data, then calls the objectHandler on the object.
	/// - Parameter data: The data to decode into an object.
	private func generateTypedObjectJSON(_ data: Data) {
		do {
			let obj = try ProcessControllerTyped<T>.jsonDecoder.decode(T.self, from: data)
			objectHandler(StreamingProcessResult.object(output: obj))
		} catch {
			objectHandler(StreamingProcessResult.error(rawData: data, decodingError: error))
		}
	}
	
	/// Creates the `T` object from the provided Property List data, then calls the objectHandler on the object.
	/// - Parameter data: The data to decode into an object.
	private func generateTypedObjectPropertyList(_ data: Data) {
		do {
			let obj = try ProcessControllerTyped<T>.plistDecoder.decode(T.self, from: data)
			objectHandler(StreamingProcessResult.object(output: obj))
		} catch {
			objectHandler(StreamingProcessResult.error(rawData: data, decodingError: error))
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
		for split in splits {
			decoderFunc(split)
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
		
		let proc = createProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
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
