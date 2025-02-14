//
//  BLEManager.swift
//  BLEFramework
//
//  Created by Tops on 07/02/25.
//

import Foundation
import CoreBluetooth

public class BLEManager: NSObject {
    
    public struct DiscoveredPeripheral {
        public let peripheral: CBPeripheral
        public let advertisementData: [String: Any]
        public let rssi: NSNumber
        
        var advertisementLocalName: String? {
            advertisementData["kCBAdvDataLocalName"] as? String
        }
        
        public var displayName: String {
            advertisementLocalName ?? peripheral.name ?? "N/A"
        }
    }
    
    public struct PeripheralConnection {
        public let peripheral: CBPeripheral
        public let completion: PeripheralConnectionCompletion
    }
    
    public enum PeripheralError: Swift.Error {
        case unknown
    }
    
    public typealias PeripheralConnectionCompletion = (CBPeripheral, Result<Void, Error>) -> Void
    
    private lazy var centralManager: CBCentralManager = {
        let manager = CBCentralManager(delegate: self, queue: nil)
        manager.delegate = self
        return manager
    }()
    // Start can related variables
    private var startScanInvoker: (() -> Void)?
    private var servicesToScan: [CBUUID]?
    // Discover scanned peripheral related variables
    private var discoverPeripheralCompletion: ((DiscoveredPeripheral) -> Void)?
    // Peripheral connection related variables
    private var arrPeripheralConnection: [PeripheralConnection] = []
    
    public override init() {
        super.init()
        _ = centralManager
    }
    
    public var permissionStatus: CBManagerAuthorization {
        CBManager.authorization
    }
    
    public func stopScan() {
        centralManager.stopScan()
    }
    
    public func startScan(withServices services: [CBUUID]? = nil,
                          completion: @escaping (DiscoveredPeripheral) -> Void) {
        if centralManager.state == .poweredOn {
            discoverPeripheralCompletion = completion
            centralManager.scanForPeripherals(withServices: services)
        } else {
            startScanInvoker = {[weak self] in
                self?.centralManager.scanForPeripherals(withServices: services)
            }
        }
    }
    
    public func connect(to peripheral: CBPeripheral,
                        completion: @escaping PeripheralConnectionCompletion) {
        let connection = PeripheralConnection(peripheral: peripheral, completion: completion)
        arrPeripheralConnection.append(connection)
        centralManager.connect(peripheral)
    }
    
    public func discoverServices(of peripheral: CBPeripheral,
                                 withServiceUUIds uuids: [CBUUID]? = nil) {
        peripheral.discoverServices(uuids)
    }
}

// MARK: - Helper
extension BLEManager {
}

// MARK: - CentralManager Delegate
extension BLEManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        printInfo("CentralManager did update state: \(central.state)")
        switch central.state {
        case .poweredOn:
            startScanInvoker?()
        default: break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        assert(discoverPeripheralCompletion != nil)
        printInfo("<<<",
                  "Did discovered peripheral: \(peripheral)",
                  "with advertisement data: \(advertisementData)",
                  "RSSI: \(RSSI) >>>\n")
        let peripheral = DiscoveredPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        discoverPeripheralCompletion?(peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let index = arrPeripheralConnection.firstIndex(where: { $0.peripheral == peripheral }) else {
            assert(false, "Found connection completion nil")
            return
        }
        arrPeripheralConnection[index].completion(peripheral, Result.success(()))
        arrPeripheralConnection.remove(at: index)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        guard let index = arrPeripheralConnection.firstIndex(where: { $0.peripheral == peripheral }) else {
            assert(false, "Found connection completion nil")
            return
        }
        arrPeripheralConnection[index].completion(peripheral, Result.failure(error ?? PeripheralError.unknown))
        arrPeripheralConnection.remove(at: index)
    }
    
    public func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        printInfo("Updated authorization status for peripheral: \(peripheral), isANCSAuthorized: \(peripheral.ancsAuthorized)")
    }
}


