//
//  MachVirtualMemory.swift
//  MachKit
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import FoundationKit

/// Class representing the memory of the process.
public class MachVirtualMemory {

    public enum InputError: LocalizedError {
        case invalidString(String)

        public var errorDescription: String? {
            switch self {
            case .invalidString(let hexString):
                return "Invalid hexadecimal input string: \(hexString)."
            }
        }
    }

    /// Options for the protection of the memory.
    public struct Protection: OptionSet {
        public let rawValue: vm_prot_t

        public static let none = Protection(rawValue: VM_PROT_NONE)
        public static let read = Protection(rawValue: VM_PROT_READ)
        public static let write = Protection(rawValue: VM_PROT_WRITE)
        public static let execute = Protection(rawValue: VM_PROT_EXECUTE)
        public static let all: Protection = [.read, .write, .execute]

        public init(rawValue: vm_prot_t) {
            self.rawValue = rawValue
        }
    }

    public typealias Address = mach_vm_address_t
    public typealias Size = mach_vm_size_t

    /// Struct that represents an address range.
    public struct AddressRange {
        public let start: Address
        public let size: Size

        public init(start: Address, size: Size) {
            self.start = start
            self.size = size
        }

        public init?(from start: Address, to end: Address) {
            guard end > start else {
                return nil
            }

            self.start = start
            self.size = end - start + 1
        }
    }

    private let pid: pid_t
    private let task: mach_port_name_t

    internal let machoBaseAddress: Address = 0x100000000

    /// Base address of the executable in the memory layout.
    public let baseAddress: Address

    /// Offset of the base address with respect of the typical Mach-O base addres, 0x100000000.
    public let aslrOffset: Address

    internal init(pid: pid_t) throws {
        self.pid = pid

        var task = mach_port_name_t()
        var result = task_for_pid(mach_task_self_, self.pid, &task)

        guard result == KERN_SUCCESS else {
            throw MachError(result)
        }

        var baseAddress = mach_vm_address_t()

        result = find_main_binary(pid, &baseAddress)
        guard result == KERN_SUCCESS else {
            throw MachError(result)
        }

        var aslrOffset = Address()

        guard get_image_size(baseAddress, pid, &aslrOffset) != -1 else {
            throw MachError(.aborted)
        }

        self.aslrOffset = aslrOffset
        self.baseAddress = baseAddress
        self.task = task
    }

    /// Changes the protection of the specified range of the memory.
    ///
    /// - Parameters:
    ///   - protection: Protection to set to the range of memory.
    ///   - adressRange: The address range where the protection change will the executed.
    /// - Throws: Error during the execution.
    public func setProtection(to protection: Protection, on adressRange: AddressRange) throws {

        let result = mach_vm_protect(self.task, adressRange.start, adressRange.size, 0, protection.rawValue)

        guard result == KERN_SUCCESS else {
            throw MachError(result)
        }
    }

    /// Reads data from the memory range specified.
    ///
    /// - Parameter addressRange: Memory range to read.
    /// - Returns: Data in the specified memory range.
    /// - Throws: Error during the read process.
    public func readData(on addressRange: AddressRange) throws -> Data {

        var dataOffset = vm_offset_t()
        var dataSize = mach_msg_type_number_t()

        let result = mach_vm_read(self.task, addressRange.start, addressRange.size, &dataOffset, &dataSize)

        guard result == KERN_SUCCESS else {
            throw MachError(result)
        }

        guard let dataPointer = UnsafeRawPointer(bitPattern: dataOffset) else {
            throw MachError(.invalidAddress)
        }

        return Data(bytes: dataPointer, count: Int(dataSize))
    }

    /// Writes bytes in the specified memory range.
    ///
    /// - Parameters:
    ///   - hexString: Bytes as an hexadecimal string to write in the specified memory range.
    ///   - adressRange: Memory range where to write the bytes.
    /// - Throws: Error during the write process.
    public func write(_ hexString: String, on adressRange: AddressRange) throws {

        guard let data = Data(hexString: hexString) else {
            throw InputError.invalidString(hexString)
        }

        try self.write(data, on: adressRange)
    }

    /// Writes bytes in the specified memory range.
    ///
    /// - Parameters:
    ///   - data: Data to write in the specified memory range.
    ///   - adressRange: Memory range where to write the bytes.
    /// - Throws: Error during the write process.
    public func write(_ data: Data, on adressRange: AddressRange) throws {

        guard data.count >= Int(adressRange.size) else {
            throw MachError(.invalidAddress)
        }

        var unsafeData = data

        try withUnsafePointer(to: &unsafeData) { (pointer) in

            let pointerAddress = pointer.hashValue

            let result = mach_vm_write(self.task, adressRange.start, vm_offset_t(pointerAddress), mach_msg_type_number_t(adressRange.size))

            guard result == KERN_SUCCESS else {
                throw MachError(result)
            }
        }
    }
}

extension MachVirtualMemory.Address {
    
    /// Hexadecimal representation.
    public var hexString: String {
        return "0x\(String(self, radix: 16, uppercase: true))"
    }

    public init?(hexString: String) {
        let hexString = hexString.hasPrefix("0x") ? hexString.substring(from: hexString.index(hexString.startIndex, offsetBy: 2)) : hexString

        self.init(hexString, radix: 16)
    }
}
