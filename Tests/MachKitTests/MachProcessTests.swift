//
//  MachProcessTests.swift
//  MachKitTests
//
//  Created by Pedro José Pereira Vieito on 22/11/2019.
//  Copyright © 2019 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import FoundationKit
import XCTest
@testable import MachKit

class MachProcessTests: XCTestCase {
    static let machoHeader = Data(hexString: "CFFAEDFE")
    
    func testMachProcess() throws {
        XCTAssertThrowsError(try MachProcess(pid: -1))
        XCTAssertThrowsError(try MachProcess(processName: UUID().uuidString))
        
        let process = try MachProcess(pid: ProcessInfo.processInfo.processIdentifier)
        XCTAssertEqual(process.pid, ProcessInfo.processInfo.processIdentifier)
        XCTAssertGreaterThanOrEqual(process.memory.aslrOffset, 0)
        XCTAssertGreaterThanOrEqual(process.memory.baseAddress, MachVirtualMemory.machoBaseAddress)
        
        let headerAddressRange = MachVirtualMemory.AddressRange(
            start: process.memory.baseAddress, size: 4)
        let headerData = try process.memory.readData(on: headerAddressRange)
        XCTAssertEqual(headerData, MachProcessTests.machoHeader)
    }
}
