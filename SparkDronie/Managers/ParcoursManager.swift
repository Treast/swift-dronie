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
    var currentPoint: ParcoursPoint? = ParcoursPoint(x: 0, y: 0)
    var timer:Timer? = nil
    var isFirstMove = false
    
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
    
    func playParcours(duration: Float, _ callback: (() -> ())? = nil) {
        guard let parcours = currentParcours else {
            return
        }
        
        var length: Float = 0.0
        
        isFirstMove = true
        
        if(parcours.points.count > 2) {
            for i in 0...parcours.points.count - 2 {
                let pointA = parcours.points[i]
                let pointB = parcours.points[i + 1]
                let x = pointB.x - pointA.x
                let y = pointB.y - pointA.y
                length += sqrt(x * x + y * y)
            }
        } else {
            let pointA = parcours.points[0]
            let pointB = parcours.points[1]
            let x = pointB.x - pointA.x
            let y = pointB.y - pointA.y
            length += sqrt(x * x + y * y)
        }
        
        currentParcoursLength = length
        MovementManager.shared.stop()
        
        currentParcoursDuration = duration
        
        executeParcours(callback)
    }
    
    func executeParcours(_ callback: (() -> ())? = nil) {
        guard let parcours = currentParcours else { return }
        let yFactor: Float = 1.7 // Si le drone descend, on va plus vite
        if let distance = self.nextDistance(), let move = self.nextMove() {
            var timerInterval = currentParcoursDuration * distance / currentParcoursLength;
            if (isFirstMove) {
                timerInterval = 0.0
            }
            self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timerInterval), repeats: false) { (t) in
                // Code exécuté après move.duration seconds

                if self.currentParcours != nil {
                    self.isFirstMove = false
                    self.executeParcours(callback)
                    
                    var xDirection = MovementManager.shared.speedFactor * cos(move)
                    var yDirection = MovementManager.shared.speedFactorY * sin(move)
                    
                    if yDirection < 0 {
                        yDirection *= yFactor
                    }
                    
                    if MovementManager.shared.isTesting {
                        print("Moving angle: Angle: \(move * 180 / Float.pi) X: \(xDirection) Y: \(yDirection)")
                    } else {
                        if let mySpark = DJISDKManager.product() as? DJIAircraft {
                            mySpark.mobileRemoteController?.rightStickHorizontal = xDirection
                            mySpark.mobileRemoteController?.leftStickVertical = yDirection
                        }
                    }
                    
                    self.currentPoint = parcours.points[self.currentIndex]
                }
            }
        } else {
            if currentParcours != nil {
                Timer.scheduledTimer(withTimeInterval: TimeInterval(currentParcoursDuration / Float(parcours.points.count - 1)), repeats: false) { (t) in
                    self.stop()
                    if let cb = callback {
                        cb()
                    }
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
        self.timer?.invalidate()
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
