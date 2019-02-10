//
//  GimbalDirection.swift
//  fr.vincentriva.RivaVincentMentalist
//
//  Created by Digital on 21/01/2019.
//  Copyright © 2019 Digital. All rights reserved.
//

import Foundation
import UIKit

struct Point3D {
    var x: Float
    var y: Float
    var z: Float
    var w: Float
}

enum GimbalDirection: String, CaseIterable {
    case Reset, Up, Down, Left, Right
    
    func value() -> Point3D {
        switch self {
        case .Reset:
            return Point3D(x: 0, y: 0, z: 0, w: 0)
        case .Up:
            return Point3D(x: 90, y: 0, z: 0, w: 0)
        case .Down:
            return Point3D(x: -90, y: 0, z: 0, w: 0)
        case .Left:
            return Point3D(x: 0, y: 90, z: 0, w: 0)
        case .Right:
            return Point3D(x: 0, y: -90, z: 0, w: 0)
        }
    }
}
