//
//  ProcessControllerTyped.swift
//  SwiftProcessController
//

import Foundation


public class ProcessControllerTyped<T: Decodable>: SPCBaseController {
	public typealias typedHandler = (T) -> Void
	public typealias errorHandler = (Error, Data) -> Void
	
	private let objectHandler: (T) -> Void
	private let separator: UInt8
	private var decoderFunc: ((Data) -> Void)!
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
	
	private func generateTypedObjectJSON(_ data: Data) {
		do {
			let obj = try jsonDecoder.decode(T.self, from: data)
			objectHandler(obj)
		} catch {
			NSLog("Error decoding json: \(error)")
			errHandler(error, data)
		}
	}
	
	private func generateTypedObjectPropertyList(_ data: Data) {
		do {
			let obj = try plistDecoder.decode(T.self, from: data)
			objectHandler(obj)
		} catch {
			NSLog("Error decoding json: \(error)")
			errHandler(error, data)
		}
	}
	
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
	
	public func launchTypedStream(args: [String], standardInput: Pipe? = nil) throws {
		let standardOutput = Pipe()
		let standardError = Pipe()
		
		let proc = CreateProcessObject(standardOutput: standardOutput, standardError: standardError, args: args)
		
		proc.terminationHandler = exitHandler(_:)
		addToNC(fileHandle: standardOutput.fileHandleForReading, handler: self.read(_:))
		addToNC(fileHandle: standardError.fileHandleForReading, handler: self.stderrHandler)
		try startProcess(proc: proc)
		if partial.count != 0 {
			decoderFunc(partial)
		}
	}
	
}
