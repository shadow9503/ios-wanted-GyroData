//
//  CoreData.swift
//  GyroData
//
//  Created by 1 on 2022/09/20.
//

import Foundation
import UIKit



struct RunDataList: Codable {
   
    let timestamp: String
    let gyro: String
    let interval: Float
//    let acc: [Acc]
//    let gyro: [Gyro]   
}

class Acc: Codable {
    let x: Float
    let y: Float
    let z: Float
    
    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

class Gyro: Codable {
    let x: Float
    let y: Float
    let z: Float
    
    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

