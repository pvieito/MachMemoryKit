//
//  main.swift
//  MachMemoryTool
//  Tool to patch the memory of a running process.
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import MachKit
import CommandLineKit
import LoggerKit

let inputOption = StringOption(shortFlag: "i", longFlag: "input", required: true, helpMessage: "Input process name or PID.")
let expectedMemoryOption = StringOption(shortFlag: "e", longFlag: "expected", helpMessage: "Expected Memory as an hex string.")
let patchedMemoryOption = StringOption(shortFlag: "d", longFlag: "patched", helpMessage: "Patched Memory as an hex string.")
let offsetAddressOption = StringOption(shortFlag: "a", longFlag: "address", helpMessage: "Memory offset address to patch.")
let verboseOption = BoolOption(shortFlag: "v", longFlag: "verbose", helpMessage: "Verbose mode.")
let helpOption = BoolOption(shortFlag: "h", longFlag: "help", helpMessage: "Prints a help message.")

let cli = CommandLineKit.CommandLine()
cli.addOptions(inputOption, expectedMemoryOption, patchedMemoryOption, offsetAddressOption, verboseOption, helpOption)

do {
    try cli.parse(strict: true)
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
    Logger.log(fatalError: "You have to run this as root.")
}

do {    
    guard let input = inputOption.value else {
        Logger.log(fatalError: "No process specified.")
    }

    var process: MachProcess
    
    if let pid = Int(input) {
        try process = MachProcess(pid: pid)
    }
    else {
        try process = MachProcess(processName: input)
    }

    Logger.log(important: "PID: \(process.pid)")

    Logger.log(info: "ASLR Offset: \(process.memory.aslrOffset.hexString)")
    Logger.log(info: "Base Address: \(process.memory.baseAddress.hexString)")

    guard let expectedMemory = expectedMemoryOption.value, let patchedMemory = patchedMemoryOption.value, let offsetAddressString = offsetAddressOption.value else {
        exit(0)
    }

    guard let offsetAddress = MachVirtualMemory.Address(hexString: offsetAddressString) else {
        Logger.log(fatalError: "Offset Address not valid.")
    }

    let patchAddress = offsetAddress + process.memory.baseAddress
    
    Logger.log(info: "Patch Address: \(patchAddress.hexString)")
    
    try process.memory.patch(expectedMemory, with: patchedMemory, on: patchAddress)

    Logger.log(success: "Memory correctly patched at \(patchAddress.hexString): \(expectedMemory) -> \(patchedMemory)")
}
catch {
    Logger.log(fatalError: error)
}
