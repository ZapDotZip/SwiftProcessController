//
//  PublicTypes.swift
//  SwiftProcessController
//

import Foundation

public typealias pipedDataHandler = (Data) -> Void
public typealias terminationHandler = (Int32) -> Void

public enum ProcessControllerError: Error {
	case couldNotDecodeStringOutput
	case couldNotDecodeJSON(String, String)
}
