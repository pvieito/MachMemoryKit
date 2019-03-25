//
//  MachProcess.swift
//  MachKit
//
//  Created by Pedro José Pereira Vieito on 6/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation

/// Class that represents a Mach Process.
///
/// Instantiate it to obtain access to its underlying Virtual Memory.
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

    /// Process Identifier / PID.
    public let pid: pid_t

    /// Memory of the process.
    public private(set) var memory: MachVirtualMemory

    /// Initialize the MachProcess using the process PID.
    ///
    /// - Parameter pid: PID of the running process as a `pid_t`.
    /// - Throws: Error while getting access to the process memory.
    public init(pid: pid_t) throws {
        self.pid = pid
        try self.memory = MachVirtualMemory(pid: pid)
    }

    /// Initialize the MachProcess using the process PID.
    ///
    /// - Parameter pid: PID of the running process as an `Int`.
    /// - Throws: Error while getting access to the process memory.
    public convenience init(pid: Int) throws {
        try self.init(pid: pid_t(pid))
    }

    /// Initialize the MachProcess using the process name.
    ///
    /// If multiple process run with the same name, it will choose the older instance.
    ///
    /// - Parameter processName: Name of the process.
    /// - Throws: Error while obtaining the process name or getting access to the process memory.
    public convenience init(processName: String) throws {
        guard let pid = pid_t(processName: processName) else {
            throw InitializationError.pidNotFoundForProcessName(processName)
        }

        try self.init(pid: pid)
    }
}

