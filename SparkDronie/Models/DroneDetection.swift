//
//  DroneDetection.swift
//  SparkDronie
//
//  Created by Vincent Riva on 13/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import UIKit
import Foundation

class DroneDetection: Codable {
    var x: Float
    var y: Float
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    init(point: CGPoint) {
        self.x = Float(point.x)
        self.y = Float(point.y)
    }
    
    func toJson() -> Any {
        return ["x": self.x, "y": self.y]
    }
}
