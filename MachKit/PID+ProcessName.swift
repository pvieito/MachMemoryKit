//
//  PID+ProcessName.swift
//  MachKit
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation

extension pid_t {

    init?(processName: String) {

        let pgrepPath = "/usr/bin/pgrep"

        guard FileManager.default.fileExists(atPath: pgrepPath) else {
            return nil
        }

        let task = Process()
        task.launchPath = pgrepPath
        task.arguments = ["-o", "-i", "-x", processName]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let outputComponents = String(data: data, encoding: String.Encoding.utf8)?.components(separatedBy: "\n") else {
            return nil
        }

        guard let pidString = outputComponents.first, let pid = pid_t(pidString) else {
            return nil
        }
        
        self = pid
    }
}
