//
//  MachVirtualMemory.swift
//  MachKit
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation
import CryptoSwift

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
    private var task: mach_port_name_t

    internal let machoBaseAddress: Address = 0x100000000
    public let baseAddress: Address
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

    public func setProtection(to protection: Protection, on adressRange: AddressRange) throws {

        let result = mach_vm_protect(self.task, adressRange.start, adressRange.size, 0, protection.rawValue)

        guard result == KERN_SUCCESS else {
            throw MachError(result)
        }
    }

    public func readBytes(on addressRange: AddressRange) throws -> [UInt8] {

        let data = try self.readData(on: addressRange)

        return data.bytes
    }

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

    public func write(_ data: Data, on adressRange: AddressRange) throws {

        try self.write(data.bytes, on: adressRange)
    }

    public func write(_ hexString: String, on adressRange: AddressRange) throws {

        let bytes = Array<UInt8>(hex: hexString)

        guard bytes.count > 0 else {
            throw InputError.invalidString(hexString)
        }

        try self.write(bytes, on: adressRange)
    }

    public func write(_ bytes: [UInt8], on adressRange: AddressRange) throws {

        guard bytes.count >= Int(adressRange.size) else {
            throw MachError(.invalidAddress)
        }

        try bytes.withUnsafeBufferPointer { (bufferPointer) in

            guard let pointerAddress = bufferPointer.baseAddress?.hashValue else {
                throw MachError(.invalidAddress)
            }

            let result = mach_vm_write(self.task, adressRange.start, vm_offset_t(pointerAddress), mach_msg_type_number_t(adressRange.size))

            guard result == KERN_SUCCESS else {
                throw MachError(result)
            }
        }
    }
}

extension MachVirtualMemory.Address {
    
    public var hexString: String {
        return "0x\(String(self, radix: 16, uppercase: true))"
    }

    public init?(hexString: String) {
        let hexString = hexString.hasPrefix("0x") ? hexString.substring(from: hexString.index(hexString.startIndex, offsetBy: 2)) : hexString

        self.init(hexString, radix: 16)
    }
}

extension Array where Element == UInt8 {

    public var hexString: String {
        return "0x".appending(self.toHexString().uppercased())
    }
}
