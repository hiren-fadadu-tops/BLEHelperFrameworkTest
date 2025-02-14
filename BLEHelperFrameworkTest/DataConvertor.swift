//
//  DataConvertor.swift
//  BLEFramework
//
//  Created by Tops on 12/02/25.
//

import Foundation

// Singleton class for data conversion
class DataConverter {
    private init() {}

    static let shared = DataConverter()
    
    internal func intToHex(_ value: UInt) -> String {
        return String(value, radix: 16)
    }
    
    // Converts a string to an array of bytes
    func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }

    // Converts hex string to UInt32, uses little endian
    func hexLittleEndianToUInt32(_ hexString: String) -> UInt32? {
        guard let beValue = UInt32(hexString, radix: 16),
              hexString.count == 8 else {
            return nil
        }
        return UInt32(beValue.byteSwapped)
    }
    
    // Converts hex string to little endian hex string
    func hexStringToLittleEndianHexString(_ hexString: String) -> String? {
        let originalTextLength: Int = hexString.count
        guard let beValue = UInt32(hexString, radix: 16),
              hexString.count == 8 else {
            return nil
        }
        let int = UInt(beValue.byteSwapped)
        let hex = intToHex(int).uppercased()
        let finalHex = repeatElement("0", count: 8 - hex.count) + hex
        return finalHex
    }
    
    // Converts hex string to UInt
    func hexStringToSingleUInt(_ hexString: String) -> UInt? {
      var hex = hexString
      if hex.hasPrefix("0x") {
        hex = String(hex.dropFirst(2))
      }
      return UInt(hex, radix: 16)
    }
    
    // Converts hex string to UInt8
    func hexStringtoSingleUInt8(_ hexString: String) -> UInt8? {
        var hex = hexString
        if hex.hasPrefix("0x") {
          hex = String(hex.dropFirst(2))
        }
        return UInt8(hex, radix: 16)
    }
    
    // Converts hex string to array of UInt8
    func hexStringToUInt8(_ hexString: String) -> [UInt8] {
        var start = hexString.startIndex
        return stride(from: 0,
                      to: hexString.count,
                      by: 2).compactMap { _ in   // use flatMap for older Swift versions
            let end = hexString.index(after: start)
            defer { start = hexString.index(after: end) }
            return UInt8(hexString[start...end], radix: 16)
        }
    }
    
    // Converts hex string to binary string
    func hexStringToBinary(_ hexString: String) -> String {
        let bytes = hexStringToUInt8(hexString)
        let arrayBinary = bytes.map {
            let binary = String($0, radix: 2)
            return repeatElement("0", count: 8-binary.count) + binary
        }
        let joinedArray = arrayBinary.joined()
        return joinedArray
    }
    
    // Converts binary string to decimal
    func binaryStringToDecimal(_ binaryString: String) -> Int? {
        return Int(binaryString, radix: 2)
    }
    
    // Converts to byte array of UInt8
    func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    
    // Convert data to hex string
    func dataToHex(_ data: Data) -> String {
        var hexStr = ""
        for byte in data {
            hexStr += String(format: "%02X", byte)
        }
        return hexStr
    }

    // Convert data to hex int array
    func dataToHexIntArray(_ data: Data) -> [UInt16] {
        var hex: [UInt16] = []
        for byte in data {
            let hexString = String(format: "%02X", byte)
            let intValue = UInt16(byte)
            hex.append(intValue)
            print("hex: \(hexString), int: \(intValue)")
        }
        return hex
    }
}

