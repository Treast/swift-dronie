//
//  ParcoursManager.swift
//  SparkDronie
//
//  Created by Vincent Riva on 10/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation
import DJISDK

class ParcoursManager {
    var currentParcours: Parcours?
    var currentIndex: Int = 0
    var currentParcoursDuration: Float = 0
    
    static let shared: ParcoursManager = ParcoursManager()
    private init() {}
    
    func open(file: String) {
        if let path = Bundle.main.path(forResource: file, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                
                let parcours = try JSONDecoder().decode(Parcours.self, from: data)
                print("Loading file: \(file)")
                setParcours(parcours: parcours)
            } catch let error {
                print("Parse error: \(error.localizedDescription)")
            }
        }
    }
    
    func setParcours(parcours: Parcours) {
        currentIndex = 0
        currentParcours = parcours
    }
    
    func playParcours(duration: Float) {
        guard let parcours = currentParcours else {
            return
        }
        
        currentParcoursDuration = duration / Float(parcours.points.count)
        
        executeParcours()
    }
    
    func executeParcours() {
        if let move = self.nextMove() {
            Timer.scheduledTimer(withTimeInterval: TimeInterval(currentParcoursDuration), repeats: false) { (t) in
                // Code exécuté après move.duration seconds
                self.executeParcours()
                
                let xDirection = MovementManager.shared.speedFactor * cos(move)
                let yDirection = MovementManager.shared.speedFactorY * sin(move)
                
                if MovementManager.shared.isTesting {
                    print("Moving angle: Angle: \(move * 180 / Float.pi) X: \(xDirection) Y: \(yDirection)")
                } else {
                    if let mySpark = DJISDKManager.product() as? DJIAircraft {
                        mySpark.mobileRemoteController?.rightStickHorizontal = xDirection
                        mySpark.mobileRemoteController?.leftStickVertical = yDirection
                    }
                }
            }
        } else {
            Timer.scheduledTimer(withTimeInterval: TimeInterval(currentParcoursDuration), repeats: false) { (t) in
               self.stop()
            }
        }
    }
    
    func reset() {
        currentParcours = nil
        currentParcoursDuration = 0.0
    }
    
    func stop() {
        self.reset()
        MovementManager.shared.stop()
    }
    
    func nextMove() -> Float? {
        guard let parcours = currentParcours else { return nil }
        guard currentIndex < parcours.points.count - 1 else { return nil }
        
        let currentPosition = parcours.points[currentIndex]
        let nextPosition = parcours.points[currentIndex + 1]
        
        let deltaX = nextPosition.x - currentPosition.x
        let deltaY = nextPosition.y - currentPosition.y
        
        currentIndex += 1
        return atan2f(deltaY, deltaX)
    }
}
