//
//  SPCProcessControllerDecoder.swift
//  SwiftProcessController
//

import Foundation

/// An object which launches a proess and decodes output to an object as it is generated.
public class SPCProcessControllerDecoder<T: Decodable>: _SPCBaseController {
	public typealias TypedHandler = (SPCDecodedResult<T>) -> Void
	public typealias ErrorHandler = (Error, Data) -> Void
	
	private let delegate: any SPCProcessDecoderDelegate<T>
	private let separator: UInt8
	private var decoderFunc: PipedDataHandler!
	
	private var partial = Data()
	
	public init(executableURL: URL, delegate: any SPCProcessDecoderDelegate<T>, decoderType: SPCProcessResultDecoder, separator: UInt8 = separatorNewLine) {
		self.separator = separator
		self.delegate = delegate
		super.init(executableURL: executableURL, stderrHandler: delegate.stderrHandler(_:), terminationHandler: delegate.terminationHandler(exitCode:))
		switch decoderType {
			case .JSON:
				decoderFunc = generateTypedObjectJSON
			case .PropertyList:
				decoderFunc = generateTypedObjectPropertyList
		}
	}
	
	public convenience init(executablePath: String, delegate: any SPCProcessDecoderDelegate<T>, decoderType: SPCProcessResultDecoder, separator: UInt8 = separatorNewLine) {
		self.init(executableURL: URL(localPath: executablePath), delegate: delegate, decoderType: decoderType, separator: separator)
	}
	
	/// Creates the `T` object from the provided JSON data, then calls the objectHandler on the object.
	/// - Parameter data: The data to decode into an object.
	private func generateTypedObjectJSON(_ data: Data) {
		do {
			let obj = try SPCProcessControllerDecoder<T>.jsonDecoder.decode(T.self, from: data)
			delegate.stdoutHandler(SPCDecodedResult.object(output: obj))
		} catch {
			delegate.stdoutHandler(SPCDecodedResult.error(rawData: data, decodingError: error))
		}
	}
	
	/// Creates the `T` object from the provided Property List data, then calls the objectHandler on the object.
	/// - Parameter data: The data to decode into an object.
	private func generateTypedObjectPropertyList(_ data: Data) {
		do {
			let obj = try SPCProcessControllerDecoder<T>.plistDecoder.decode(T.self, from: data)
			delegate.stdoutHandler(SPCDecodedResult.object(output: obj))
		} catch {
			delegate.stdoutHandler(SPCDecodedResult.error(rawData: data, decodingError: error))
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
	override func exitHandler(_ p: Process) {
		if partial.count != 0 {
			decoderFunc(partial)
		}
		super.exitHandler(p)
	}
	
	/// Starts the process and returns, letting it run in the background.
	/// - Parameters:
	///   - args: Process arguments
	///   - standardInput: Standard input provided to the process, if any.
	public func launch(args: [String], standardInput: Pipe? = nil) throws {
		let standardOutput = Pipe()
		let standardError = Pipe()
		
		let proc = createProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
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
