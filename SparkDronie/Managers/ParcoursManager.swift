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
    var currentParcoursDuration: Float = 0.0
    var currentParcoursLength: Float = 0.0
    
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
        var length: Float = 0.0
        for i in 0...parcours.points.count - 2 {
            let pointA = parcours.points[i]
            let pointB = parcours.points[i + 1]
            let x = pointB.x - pointA.x
            let y = pointB.y - pointA.y
            length += sqrt(x * x + y * y)
        }
        currentParcoursLength = length
    }
    
    func playParcours(duration: Float, _ callback: (() -> ())? = nil) {
        guard currentParcours != nil else {
            return
        }
        MovementManager.shared.stop()
        
        currentParcoursDuration = duration
        
        executeParcours(callback)
    }
    
    func executeParcours(_ callback: (() -> ())? = nil) {
        guard let parcours = currentParcours else { return }
        
        if let distance = self.nextDistance(), let move = self.nextMove() {
            let timerInterval = currentParcoursDuration * distance / currentParcoursLength;
            Timer.scheduledTimer(withTimeInterval: TimeInterval(timerInterval), repeats: false) { (t) in
                // Code exécuté après move.duration seconds
                self.executeParcours(callback)
                
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
            Timer.scheduledTimer(withTimeInterval: TimeInterval(currentParcoursDuration / Float(parcours.points.count)), repeats: false) { (t) in
               self.stop()
                if let cb = callback {
                    cb()
                }
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
    
    func nextDistance() -> Float? {
        guard let parcours = currentParcours else { return nil }
        guard currentIndex < parcours.points.count - 1 else { return nil }
        
        let currentPosition = parcours.points[currentIndex]
        let nextPosition = parcours.points[currentIndex + 1]
        
        let x = nextPosition.x - currentPosition.x
        let y = nextPosition.y - currentPosition.y
        return sqrt(x * x + y * y)
    }
}
