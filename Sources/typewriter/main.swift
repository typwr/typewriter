//
//  main.swift
//  typewriter
//
//  Created by mrriddler on 2017/12/29.
//  Copyright © 2017年 typewriter. All rights reserved.
//

import Foundation

func main(processInfo: ProcessInfo) {
    let arguments = processInfo.arguments.dropFirst()
    execute(withArgument: Array(arguments))
}

main(processInfo: ProcessInfo.processInfo)
