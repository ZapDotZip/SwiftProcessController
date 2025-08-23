//
//  Extensions.swift
//  SwiftProcessController
//

import Foundation

internal extension URL {
	/// Creates a file URL that references a local path string, like `init(fileURLWithPath: String)` and `init(filePath: String)` (macOS 13+).
	/// - Parameter localPath: The location in the file system, as a string.
	init(localPath: String) {
		if #available(macOS 13.0, *) {
			self.init(filePath: localPath)
		} else {
			self.init(fileURLWithPath: localPath)
		}
	}
	
	/// Returns the path component of the URL, like `.path` and `.path()` (macOS 13+), suitable for displaying a local file path to the user.
	var localPath: String {
		if #available(macOS 13.0, *) {
			return self.path()
		} else {
			return self.path
		}
	}
}
