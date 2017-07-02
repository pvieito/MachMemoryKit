//
//  MachVirtualMemoryPatch.swift
//  MachKit
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation

extension MachVirtualMemory {

    public enum PatchError: LocalizedError {
        case sizeMismatch
        case alreadyPatched
        case memoryNotPatched(Data)
        case memoryNotExpected(Data, Data)

        public var errorDescription: String? {
            switch self {
            case .sizeMismatch:
                return "Expected memory and patched memory should have the same size."
            case .alreadyPatched:
                return "Memory already patched."
            case .memoryNotPatched(let finalMemory):
                return "Memory not patched: \(finalMemory.hexString)."
            case .memoryNotExpected(let originalMemory, let expectedMemory):
                return "Memory data different to the expected. Original: \(originalMemory.hexString) vs. Expected: \(expectedMemory.hexString)."
            }
        }
    }

    /// Modifies the specified expected bytes with some patched bytes at the patch address.
    ///
    /// This function will check if the memory at the patch address is the expected one and then
    /// wil try to modify it with the specified patch.
    ///
    /// Note: the expected memory bytes and the patched memory bytes should be of the same length.
    ///
    /// - Parameters:
    ///   - expectedMemoryHexString: Bytes as an hex string expected at the patch address.
    ///   - patchedMemoryHexString: Bytes as an hex string to write at the patch address.
    ///   - patchAddress: Address where to modify the memory.
    /// - Throws: Error while executing the patch.
    public func patch(_ expectedMemoryHexString: String, with patchedMemoryHexString: String, on patchAddress: Address) throws {

        guard let expectedMemory = Data(hexString: expectedMemoryHexString) else {
            throw InputError.invalidString(expectedMemoryHexString)
        }

        guard let patchedMemory = Data(hexString: patchedMemoryHexString) else {
            throw InputError.invalidString(patchedMemoryHexString)
        }

        try self.patch(expectedMemory, with: patchedMemory, on: patchAddress)
    }

    /// Modifies the specified expected bytes with some patched bytes at the patch address.
    ///
    /// This function will check if the memory at the patch address is the expected one and then
    /// wil try to modify it with the specified patch.
    ///
    /// Note: the expected memory bytes and the patched memory bytes should be of the same length.
    ///
    /// - Parameters:
    ///   - expectedMemory: Data expected at the patch address.
    ///   - patchedMemory: Data to write at the patch address.
    ///   - patchAddress: Address where to modify the memory.
    /// - Throws: Error while executing the patch.
    public func patch(_ expectedMemory: Data, with patchedMemory: Data, on patchAddress: Address) throws {

        let patchSize = Size(patchedMemory.count)
        let expectedSize = Size(expectedMemory.count)

        guard patchSize == expectedSize else {
            throw PatchError.sizeMismatch
        }

        let patchRange = AddressRange(start: patchAddress, size: patchSize)

        try self.setProtection(to: .all, on: patchRange)

        let originalMemory = try self.readData(on: patchRange)

        guard originalMemory != patchedMemory else {
            throw PatchError.alreadyPatched
        }

        guard originalMemory == expectedMemory else {
            throw PatchError.memoryNotExpected(originalMemory, expectedMemory)
        }

        try self.write(patchedMemory, on: patchRange)

        let finalMemory = try self.readData(on: patchRange)

        guard finalMemory == patchedMemory else {
            throw PatchError.memoryNotPatched(finalMemory)
        }
    }
}
