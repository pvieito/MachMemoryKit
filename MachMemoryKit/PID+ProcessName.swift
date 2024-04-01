//
//  PID+ProcessName.swift
//  MachMemoryKit
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import FoundationKit

extension pid_t {
    internal init?(processName: String) {
        guard let process = try? Process(executableName: "pgrep", arguments: ["-n", "-i", "-x", processName]),
              let output = try? process.runAndGetOutputString(),
              let output = output.trimmingWhitespacesAndNewlines().components(separatedBy: .newlines).first,
              let pid = pid_t(output) else {
            return nil
        }
        self = pid
    }
}
