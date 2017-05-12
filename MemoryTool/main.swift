//
//  main.swift
//  MemoryTool
//  Tool to patch the memory of a running process.
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import MachKit
import CommandLineKit
import LoggerKit


let processOption = StringOption(shortFlag: "p", longFlag: "process", required: true, helpMessage: "Process name or PID.")
let expectedMemoryOption = StringOption(shortFlag: "e", longFlag: "expected", helpMessage: "Expected Memory as an hex string.")
let patchedMemoryOption = StringOption(shortFlag: "d", longFlag: "patched", helpMessage: "Patched Memory as an hex string.")
let offsetAddressOption = StringOption(shortFlag: "a", longFlag: "address", helpMessage: "Memory offset address to patch.")
let verboseOption = BoolOption(shortFlag: "v", longFlag: "verbose", helpMessage: "Verbose Mode.")
let helpOption = BoolOption(shortFlag: "h", longFlag: "help", helpMessage: "Prints a help message.")

let cli = CommandLineKit.CommandLine()
cli.addOptions(processOption, expectedMemoryOption, patchedMemoryOption, offsetAddressOption, verboseOption, helpOption)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

if helpOption.value {
    cli.printUsage()
    exit(0)
}

Logger.logMode = .commandLine
Logger.logLevel = verboseOption.value ? .debug : .info

guard getuid() == 0 else {
    Logger.log(error: "You have to run this as root.")
    exit(-1)
}

do {

    guard let processString = processOption.value else {
        Logger.log(error: "No process specified.")
        exit(EX_USAGE)
    }

    var process: MachProcess

    if let pid = Int(processString) {
        try process = MachProcess(pid: pid)
    }
    else {
        try process = MachProcess(processName: processString)
    }

    Logger.log(important: "PID: \(process.pid)")

    Logger.log(info: "ASLR Offset: \(process.memory.aslrOffset.hexString)")
    Logger.log(info: "Base Address: \(process.memory.baseAddress.hexString)")

    guard let expectedMemory = expectedMemoryOption.value, let patchedMemory = patchedMemoryOption.value, let offsetAddressString = offsetAddressOption.value else {
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
