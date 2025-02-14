//
//  Helpers.swift
//  BLEFrameworkUsageExample
//
//  Created by Tops on 07/02/25.
//

import Foundation

internal func printInfo(_ content: Any...) {
    print("BLE Framework", terminator: "")
    for item in content {
        print(item)
    }
}
