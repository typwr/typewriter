//
//  FileGenerator.swift
//  typewriter
//
//  Created by mrriddler on 2017/6/19.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

struct FileGenerator {
    static func generateFile(fileRepresents: [FileRepresent], outputDirectory: URL) {
        for var fileRepresent in fileRepresents {
            do {
                let fileEntity = fileRepresent.representEntity()
                try fileEntity.write(to: URL(string: fileRepresent.representName, relativeTo: outputDirectory)!,
                                     atomically: true,
                                     encoding: .utf8)
            } catch let error as NSError {
                print("Error: write file To Directory -> \(outputDirectory.absoluteString) \(error.domain) \(error.code)")
                exit(1)
            }
        }
    }
}
