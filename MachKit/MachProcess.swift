//
//  MachProcess.swift
//  MachKit
//
//  Created by Pedro José Pereira Vieito on 6/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation

public class MachProcess {

    public enum InitializationError: LocalizedError {
        case pidNotFoundForProcessName(String)

        public var errorDescription: String? {
            switch self {
            case .pidNotFoundForProcessName(let processName):
                return "Process Identifier of \(processName) unknown."
            }
        }
    }

    public let pid: pid_t
    public private(set) var memory: MachVirtualMemory

    public init(pid: pid_t) throws {
        self.pid = pid
        try self.memory = MachVirtualMemory(pid: pid)
    }

    public convenience init(pid: Int) throws {
        try self.init(pid: pid_t(pid))
    }

    public convenience init(processName: String) throws {
        guard let pid = pid_t(processName: processName) else {
            throw InitializationError.pidNotFoundForProcessName(processName)
        }

        try self.init(pid: pid)
    }
}

