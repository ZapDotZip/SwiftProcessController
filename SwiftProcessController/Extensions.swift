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
			return self.path(percentEncoded: false)
		} else {
			return self.path
		}
	}
	
	/// Returns a URL by appending the specified path to the URL, like `appendingPathComponent(_: String, isDirectory: Bool)` or `appending(path: Stromg, directoryHint: URL.DirectoryHint)` (macOS 13+).
	/// - Parameters:
	///   - path: The path to add.
	///   - isDirectory: If true, the method treats the path component as a directory. If nil, checks the filesystem.
	/// - Returns: A new URL that appends the specified path to the original URL.
	func appending(path: String, isDirectory: Bool? = nil) -> URL {
		if #available(macOS 13.0, *) {
			if let isDirectory {
				return self.appending(path: path, directoryHint: isDirectory ? .isDirectory : .notDirectory)
			} else {
				return self.appending(path: path, directoryHint: .checkFileSystem)
			}
		} else {
			if let isDirectory {
				return self.appendingPathComponent(path, isDirectory: isDirectory)
			} else {
				return self.appendingPathComponent(path)
			}
		}
	}

}
