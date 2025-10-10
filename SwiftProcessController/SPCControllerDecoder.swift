//
//  SPCControllerDecoder.swift
//  SwiftProcessController
//

import Foundation

/// An object which launches a proess and decodes output to an object as it is generated.
public class SPCControllerDecoder<T: Decodable>: _SPCBaseController {
	public typealias TypedHandler = (SPCDecodedResult<T>) -> Void
	public typealias ErrorHandler = (Error, Data) -> Void
	
	private let delegate: any SPCDecoderDelegate<T>
	private let separator: UInt8
	private var decoder: SPCResultDecoderType
	
	/// This lock prevents the terminationHandler from running until all the data in `stdout` has been processed.
	private let lock = DispatchSemaphore(value: 1)
	private var partial = Data()
	
	public init(executableURL: URL, delegate: any SPCDecoderDelegate<T>, decoderType: SPCResultDecoderType, separator: UInt8 = separatorNewLine) {
		self.separator = separator
		self.delegate = delegate
		self.decoder = decoderType
		super.init(executableURL: executableURL, stderrHandler: delegate.stderrHandler(_:), terminationHandler: delegate.terminationHandler(exitCode:))
	}
	
	public convenience init(executablePath: String, delegate: any SPCDecoderDelegate<T>, decoderType: SPCResultDecoderType, separator: UInt8 = separatorNewLine) {
		self.init(executableURL: URL(localPath: executablePath), delegate: delegate, decoderType: decoderType, separator: separator)
	}
	
	/// Creates the `T` object from the provided data, then calls the objectHandler on the object.
	/// - Parameter data: The data to decode into an object.
	private func generateTypedObject(_ data: Data) {
		let obj = SPCDecodedResult(data: data, decoder: decoder, type: T.self)
		delegate.stdoutHandler(obj)
	}
	
	/// Repeatedly called to append new data to partial data, then splits the data as necessary to call the object handler.
	/// - Parameter data: The new data to add.
	private func read(_ data: Data) {
		guard !data.isEmpty else {
			if !partial.isEmpty {
				generateTypedObject(partial)
				partial = Data()
			}
			lock.signal()
			return
		}
		partial.append(data)
		var splits = partial.split(separator: separator)
		// if the last byte is not the separator, then the last split is not a complete chunk of data
		if partial.last != separator {
			if let last = splits.popLast() {
				partial = last // save the incomplete chunk for later
			}
		} else {
			partial = Data()
		}
		for split in splits {
			generateTypedObject(split)
		}
	}
	
	/// Ensures the rest of the data is processed before exiting.
	override func exitHandler(_ p: Process) {
		lock.wait()
		super.exitHandler(p)
		lock.signal()
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
		lock.wait()
		do {
			try startProcess(proc)
		} catch {
			lock.signal()
			throw error
		}
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
