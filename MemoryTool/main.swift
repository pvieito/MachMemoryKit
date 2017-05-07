//
//  main.swift
//  MachKit
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import MachKit
import Commander
import LoggerKit

Logger.logMode = .commandLine

let processArgument = Argument<String>("process")

let expectedMemoryOption = Option("expected", "--", flag: "e", description: "Expected Memory as an hex string")
let patchedMemoryOption = Option("patched", "--", flag: "p", description: "Patched Memory as an hex string")
let offsetAddressOption = Option("address", "--", flag: "a", description: "Memory offset address to patch")

let verboseFlag = Flag("verbose", flag: "v", description: "Verbose Mode", default: false)

let main = command(processArgument, expectedMemoryOption, patchedMemoryOption, offsetAddressOption, verboseFlag) { processArgument, expectedMemory, patchedMemory, offsetAddressString, verbose in

    Logger.logLevel = verbose ? .debug : .info

    if getuid() != 0 {
        Logger.log(error: "You have to run this as root.")
        exit(-1)
    }

    do {
        var process: MachProcess

        if let pid = Int(processArgument) {
            try process = MachProcess(pid: pid)
        }
        else {
            try process = MachProcess(processName: processArgument)
        }

        Logger.log(important: "PID: \(process.pid)")

        Logger.log(info: "ASLR Offset: \(process.memory.aslrOffset.hexString)")
        Logger.log(info: "Base Address: \(process.memory.baseAddress.hexString)")

        guard expectedMemory != "--", patchedMemory != "--", offsetAddressString != "--" else {
            exit(0)
        }

        guard let offsetAddress = MachVirtualMemory.Address(hexString: offsetAddressString) else {
            Logger.log(error: "Offset Address not valid.")
            exit(-1)
        }

        let patchAddress = offsetAddress + process.memory.baseAddress

        try process.memory.patch(expectedMemory, with: patchedMemory, on: patchAddress)

        Logger.log(success: "Memory correctly patched at \(patchAddress.hexString): \(expectedMemory) -> \(patchedMemory)")
    }
    catch {
        Logger.log(error: error.localizedDescription)
    }
}

main.run()
