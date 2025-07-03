//
//  FileManagerHelper.swift
//  IPlay
//
//  Created by Aswanth K on 01/07/25.
//

import Foundation

class FileManagerHelper {
    static let shared = FileManagerHelper()
    
    private init() {}

    /// Returns path to Documents directory
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// Lists all `.mp3` files in Documents
    func listAudioFiles() -> [URL] {
        let directory = getDocumentsDirectory()
        let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        return contents?.filter { $0.pathExtension.lowercased() == "mp3" } ?? []
    }
}
