//
//  JSONLineDecoder.swift
//  SwiftProcessController
//

import Foundation

/// <#Description#>
class JSONLineDecoder {
	let newLine: UInt8 = "\n".data(using: .ascii)![0]
	
	var readHandler: SwiftProcessController.pipedDataHandler
	var errHandler: SwiftProcessController.pipedDataHandler
	var termHandler: SwiftProcessController.terminationHandler
	
	var partial: Data = Data()
	
	/// Creates a JSONLineDecoder.
	/// - Parameters:
	///   - readHandler: <#readHandler description#>
	///   - errHandler: <#errHandler description#>
	///   - termHandler: <#termHandler description#>
	init(readHandler:@escaping SwiftProcessController.pipedDataHandler,
		 errHandler: @escaping SwiftProcessController.pipedDataHandler,
		 termHandler: @escaping SwiftProcessController.terminationHandler) {
		self.readHandler = readHandler
		self.errHandler = errHandler
		self.termHandler = termHandler
	}
	
	func read(_ data: Data) {
		// This function:
		// 1. takes in new data
		// 2. appends it to the existing partial data
		// 3. Calls the readHandler on each line
		
		partial.append(data)
		var splits = partial.split(separator: newLine)
		let last: Data? = splits.popLast()
		for i in splits {
			readHandler(i)
		}
		if last != nil {
			if JSONSerialization.isValidJSONObject(last as Any) {
				readHandler(last!)
				partial = Data()
			} else {
				partial = last!
				partial.append(newLine)
			}
		}
	}
	
}
