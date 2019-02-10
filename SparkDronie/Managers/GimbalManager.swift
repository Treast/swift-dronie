//
//  GimbalManager.swift
//  fr.vincentriva.RivaVincentMentalist
//
//  Created by Digital on 21/01/2019.
//  Copyright © 2019 Digital. All rights reserved.
//

import Foundation
import DJISDK

class GimbalManager {
    static let shared = GimbalManager()
    
    func moveGimbal(direction: GimbalDirection) {
        if let spark = DJISDKManager.product() as? DJIAircraft {
            let point3d = direction.value()
            
            //spark.gimbal?.reset(completion: nil)
            spark.gimbal?.setMode(.free)
            
            let rotation = DJIGimbalRotation.init(pitchValue: NSNumber(value: point3d.x), rollValue: NSNumber(value: point3d.y), yawValue: NSNumber(value: point3d.z), time: 0.1, mode: .relativeAngle)
            spark.gimbal?.rotate(with: rotation)
        }
    }
}
