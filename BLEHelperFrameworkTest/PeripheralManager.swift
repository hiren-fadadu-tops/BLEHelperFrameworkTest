//
//  PeripheralManager.swift
//  BLEFramework
//
//  Created by Tops on 10/02/25.
//

import CoreBluetooth

public struct CharacteristicValue {
    public let data: Data
    public let hexStringValue: String?
    public let stringValue: String?
    
    public init(data: Data) {
        self.data = data
        hexStringValue = data.map { String(format: "%02X", $0) }.joined()
        stringValue = String(data: data, encoding: .utf8)
    }
}

public enum WriteInput {
    case hexStringToEightBytesArray(value: String)
    case eightBytesArray(value: [UInt8])
    case data(value: Data)
}

public enum CharacteristicReadValueError: Error {
    case emptyData
}

public enum WriteValueError: Error {
    case dataConverstionError
}

public class PeripheralManager: NSObject {
    public typealias DiscoverServicesCompletion = (Error?) -> Void
    public typealias DiscoverCharacteristicsCompletion = (CBService, Error?) -> Void
    public typealias CharacteristicReadResult = Result<CharacteristicValue, Error>
    public typealias CharacteristicReadCompletion = (CBCharacteristic, CharacteristicReadResult) -> Void
    public typealias CharacteristicWriteResult = Error?
    public typealias CharacteristicWriteCompletion = (CBCharacteristic, CharacteristicWriteResult) -> Void
    public typealias ReadRSSIResult = Result<NSNumber, Error>
    public typealias ReadRSSICompletion = (CBPeripheral, ReadRSSIResult) -> Void

    private let peripheral: CBPeripheral
    private var discoverServicesCompletion: DiscoverServicesCompletion?
    private var discoverCharacteristicCompletion: DiscoverCharacteristicsCompletion?
    private var singleTimeCharacteristicReadCompletion: CharacteristicReadCompletion?
    private var characteristicReadListeners: [CharacteristicReadCompletion] = []
    private var singleTimeCharacteristicWriteCompletion: CharacteristicWriteCompletion?
    private var characteristicWriteListeners: [CharacteristicWriteCompletion] = []
    private var readRSSIListener: ReadRSSICompletion?

    public init(peripheral: CBPeripheral,
                delegate: CBPeripheralDelegate? = nil) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = delegate ?? self
    }
    
    public func discoverServices(withServiceIDs serviceIDs: [CBUUID]? = nil,
                                 completion: @escaping DiscoverServicesCompletion) {
        discoverServicesCompletion = completion
        peripheral.discoverServices(serviceIDs)
    }
    
    public func discoverCharacteristic(ofService service: CBService,
                                       withCharacteristicUUIDs characteristicUUIDs: [CBUUID]? = nil,
                                       completion: @escaping DiscoverCharacteristicsCompletion) {
        discoverCharacteristicCompletion = completion
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
    }
}

// MARK: - Read
extension PeripheralManager {
    public func readValueOnce(for characteristic: CBCharacteristic,
                              completion: @escaping CharacteristicReadCompletion) {
        singleTimeCharacteristicReadCompletion = completion
        peripheral.readValue(for: characteristic)
    }
    
    public func addCharacteristicReadListener(_ listener: @escaping CharacteristicReadCompletion) {
        characteristicReadListeners.append(listener)
    }
    
    public func clearCharacteristicReadListeners() {
        characteristicReadListeners.removeAll()
    }
}

// MARK: - Write
extension PeripheralManager {
    public func writeAndListenOnce(input: WriteInput,
                                   on characteristic: CBCharacteristic,
                                   withType type: CBCharacteristicWriteType,
                                   completion: @escaping CharacteristicWriteCompletion) {
        let inputData: Data
        switch input {
        case .eightBytesArray(let array):
            inputData = Data(array)
        case .hexStringToEightBytesArray(let hexString):
            guard let byteArray = DataConverter.shared.stringToBytes(hexString) else {
                printInfo("Not able to generage byte array from string")
                completion(characteristic, WriteValueError.dataConverstionError)
                return
            }
            inputData = Data(byteArray)
        case .data(let value):
            inputData = value
        }
        singleTimeCharacteristicWriteCompletion = completion
        peripheral.writeValue(inputData,
                              for: characteristic,
                              type: type)
    }
    
    public func addCharacteristicWriteListener(_ listener: @escaping CharacteristicWriteCompletion) {
        characteristicWriteListeners.append(listener)
    }
    
    public func clearCharacteristicWriteListeners() {
        characteristicWriteListeners.removeAll()
    }
}

// MARK: - Notify
extension PeripheralManager {
    public func setNotify(onCharacteristic characteristic: CBCharacteristic,
                          completion: @escaping CharacteristicReadCompletion) {
        characteristicReadListeners.append(completion)
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    public func removeNotify(onCharacteristic characteristic: CBCharacteristic) {
        characteristicReadListeners.removeAll()
        peripheral.setNotifyValue(false, for: characteristic)
    }
}

// MARK: - Read RSSI
extension PeripheralManager {
    public func setReadRSSIListener(_ completion: @escaping ReadRSSICompletion) {
        self.readRSSIListener = completion
    }
    
    public func removeRSSIListener() {
        self.readRSSIListener = nil
    }
    
    public func readRSSI() {
        peripheral.readRSSI()
    }
}

// MARK: - Peripheral Delegate
extension PeripheralManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverServices error: (any Error)?) {
        assert(discoverServicesCompletion != nil)
        printInfo("Discovered services error: \(String(describing: error))")
        discoverServicesCompletion?(error)
        discoverServicesCompletion = nil
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverIncludedServicesFor service: CBService,
                           error: (any Error)?) {
        printInfo("Discovered service: \(service), error: \(String(describing: error))")
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: (any Error)?) {
        assert(discoverCharacteristicCompletion != nil)
        printInfo("Discovered characteristic for service: \(service), error: \(String(describing: error))")
        discoverCharacteristicCompletion?(service, error)
        discoverCharacteristicCompletion = nil
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: (any Error)?) {
        func updateListeners(result: CharacteristicReadResult) {
            singleTimeCharacteristicReadCompletion?(characteristic, result)
            characteristicReadListeners.forEach({ $0(characteristic, result) })
        }
        assert(singleTimeCharacteristicReadCompletion != nil || !characteristicReadListeners.isEmpty)
        if let error = error {
            printInfo("Read, characteristic: \(characteristic.uuid), Error reading characteristic value: \(error.localizedDescription)")
            updateListeners(result: .failure(error))
        } else if let value = characteristic.value {
            let hexString = value.map { String(format: "%02X", $0) }.joined()
            let stringValue = String(data: value, encoding: .utf8)
            printInfo("Read, characteristic: \(characteristic.uuid) data: \(value), hexString: \(hexString), string: \(stringValue ?? "N/A")")
            let characteristicValue = CharacteristicValue(data: value)
            updateListeners(result: .success(characteristicValue))
        } else {
            printInfo("Read, characteristic: \(characteristic.uuid), Empty")
            updateListeners(result: .failure(CharacteristicReadValueError.emptyData))
        }
        singleTimeCharacteristicReadCompletion = nil
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic,
                           error: (any Error)?) {
        assert(singleTimeCharacteristicWriteCompletion != nil)
        singleTimeCharacteristicWriteCompletion?(characteristic, error)
        characteristicWriteListeners.forEach({ $0(characteristic, error) })
        singleTimeCharacteristicWriteCompletion = nil
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didReadRSSI RSSI: NSNumber,
                           error: (any Error)?) {
        if let error = error {
            readRSSIListener?(peripheral, .failure(error))
        } else {
            readRSSIListener?(peripheral, .success(RSSI))
        }
    }
}
