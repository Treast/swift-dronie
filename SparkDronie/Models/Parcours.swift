//
//  Parcours.swift
//  SparkDronie
//
//  Created by Vincent Riva on 10/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation

struct ParcoursPoint: Codable {
    var x: Float
    var y: Float
}

struct Parcours: Codable {
    var points: [ParcoursPoint]
}

struct ParcoursDelta {
    var x: Float
    var y: Float
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}
