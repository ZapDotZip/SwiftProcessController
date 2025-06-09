//
//  SPCBase.swift
//  SwiftProcessController
//

import Foundation

public class SPCBase {
	public var execURL: URL
	public var env: [String : String]?
	public var currentDirectory: URL?
	public var qualityOfService: QualityOfService = .default
	
	init(execURL: URL) {
		self.execURL = execURL
	}
	
	func CreateProcessObject(standardOutput: Pipe, standardError: Pipe, args: [String]) -> Process {
		let proc = Process()
		proc.executableURL = execURL
		proc.standardOutput = standardOutput
		proc.standardError = standardError
		if currentDirectory != nil {
			proc.currentDirectoryURL = currentDirectory
		}
		proc.arguments = args
		if env != nil {
			proc.environment = env
		}
		proc.qualityOfService = qualityOfService
		return proc
	}
}
