//
//  MachMemoryTool.swift
//  MachMemoryTool
//  Tool to patch the memory of a running process.
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import FoundationKit
import MachMemoryKit
import ArgumentParser
import LoggerKit

@main
struct MachMemoryTool: ParsableCommand {
    static var configuration: CommandConfiguration {
        return CommandConfiguration(commandName: String(describing: Self.self))
    }
    
    @Option(name: .shortAndLong, help: "Input item.")
    var input: String

    @Option(name: .shortAndLong, help: "Memory offset to read (hex).")
    var offset: String

    @Option(name: [.customShort("z"), .long], help: "Memory size to read.")
    var size: Int

    @Flag(name: .shortAndLong, help: "Verbose mode.")
    var verbose: Bool = false
    
    func run() throws {
        Logger.logMode = .commandLine
        Logger.logLevel = verbose ? .debug : .info

        do {
            var process: MachProcess
            if input == "-" {
                try process = MachProcess(pid: ProcessInfo.processInfo.processIdentifier)
            }
            else if let pid = Int(input) {
                try process = MachProcess(pid: pid)
            }
            else {
                try process = MachProcess(processName: input)
            }

            Logger.log(important: "PID: \(process.pid)")

            Logger.log(info: "ASLR Offset: \(process.memory.aslrOffset.hexString)")
            Logger.log(info: "Base Address: \(process.memory.baseAddress.hexString)")

            guard let offsetAddress = MachVirtualMemory.Address(hexString: offset) else {
                throw NSError(description: "Input memory offset not valid.")
            }

            let addressRange = MachVirtualMemory.AddressRange(start: process.memory.baseAddress + offsetAddress, size: MachVirtualMemory.Size(size))
            let data = try process.memory.readData(on: addressRange)
            Logger.log(success: "Memory correctly read: 0x\(data.hexString)")
        }
        catch {
            Logger.log(fatalError: error)
        }
    }
}

