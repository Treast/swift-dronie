//
//  MovementManager.swift
//  fr.vincentriva.RivaVincentMentalist
//
//  Created by Digital on 11/01/2019.
//  Copyright © 2019 Digital. All rights reserved.
//

import Foundation
import UIKit
import DJISDK

class MovementManager {
    static let shared = MovementManager()
    
    var movements = [Movement]()
    var actions = [Action]()
    var speedFactor: Float = 0.0
    var speedFactorY: Float = 0.0
    var rotationFactor: Float = 0.0
    var startPoint = Point3D(x: 0, y: 0, z: 0, w: 0)
    var isMoving: Bool = false
    var isTesting = false
    
    func reset() {
        movements = []
        actions = []
    }
    
    func appendMovement(movement: Movement){
        DirectionSequence.shared.content.append(movement.description())
        movements.append(movement)
    }
    
    func moveTo(x:Float, y:Float, duration:Float = 3.5, _ callback: (() -> ())? = nil) {
        
        //ParcoursManager.shared.currentPoint = ParcoursPoint(x:0,y:0)
        
        if let currentPoint = ParcoursManager.shared.currentPoint {
            
            print("MOVE TO x:\(x) y:\(y) FROM \(currentPoint)")
            ParcoursManager.shared.setParcours(parcours: Parcours(
                points: [
                    ParcoursPoint(x: currentPoint.x, y: -1 * currentPoint.y), //where we are atm
                    ParcoursPoint(x: x, y: -1 * y) //where we want to go
                ])
            )
            
            ParcoursManager.shared.playParcours(duration: duration) {
                if let callbackValue = callback {
                    print("Callback")
                    callbackValue()
                }
            }
        }
    }
    
    func forceMove(move: Movement.Direction) {
        if let mySpark = DJISDKManager.product() as? DJIAircraft {
            if !self.isTesting {
                mySpark.mobileRemoteController?.rightStickVertical = self.speedFactor * Float(move.value().z)
                mySpark.mobileRemoteController?.rightStickHorizontal = self.speedFactor * Float(move.value().x)
                mySpark.mobileRemoteController?.leftStickVertical = self.speedFactorY * Float(move.value().y)
                mySpark.mobileRemoteController?.leftStickHorizontal = self.rotationFactor * Float(move.value().w)
            } else {
                print(move)
            }
        }
    }
    
    func appendAction(action: Action){
        actions.append(action)
    }
    
    func nextMovement() -> Movement? {
        if movements.count > 0 {
            let movement = movements.remove(at: 0)
            return movement
        }
        return nil
    }
    
    func nextAction() -> Action? {
        if actions.count > 0 {
            let action = actions.remove(at: 0)
            return action
        }
        return nil
    }
    
    func play() {
        print("Playing sequences")
        execute()
        executeAction()
    }
    
    func standBy() {
        let standByInterval = 1.5
        let speedStandBy: Float = 0.10
        isMoving = true
        var count = 0
        print("Standby")
        Timer.scheduledTimer(withTimeInterval: TimeInterval(standByInterval), repeats: true) { t in
            if let mySpark = DJISDKManager.product() as? DJIAircraft {
                if self.isMoving {
                    if count % 2 == 0 {
                        mySpark.mobileRemoteController?.leftStickVertical = speedStandBy
                    } else {
                        mySpark.mobileRemoteController?.leftStickVertical = -1 * speedStandBy
                    }
                    mySpark.mobileRemoteController?.leftStickHorizontal = 0.0
                    mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
                    mySpark.mobileRemoteController?.rightStickVertical = 0.0
                }
            }
            
            if(!self.isMoving) {
                print("Invalidate")
                t.invalidate()
            }
            
            count += 1
        }
    }
    
    func stop() {
        print("Stop")
        isMoving = false
        if isTesting {
            DirectionSequence.shared.content.append(DirectionSequence.ActionType.Stop.rawValue)
        } else {
            reset()
            if let mySpark = DJISDKManager.product() as? DJIAircraft {
                mySpark.mobileRemoteController?.leftStickVertical = 0.0
                mySpark.mobileRemoteController?.leftStickHorizontal = 0.0
                mySpark.mobileRemoteController?.rightStickHorizontal = 0.0
                mySpark.mobileRemoteController?.rightStickVertical = 0.0
            }
        }
    }
    
    func takeOff() {
        if isTesting {
            DirectionSequence.shared.content.append(DirectionSequence.ActionType.TakeOff.rawValue)
        } else {
            if let mySpark = DJISDKManager.product() as? DJIAircraft {
                if let flightController = mySpark.flightController {
                    flightController.startTakeoff(completion: { (err) in
                        print(err.debugDescription)
                    })
                }
            }
        }
    }
    
    func takeOffWithCompletion(callback: @escaping () -> ()) {
        if isTesting {
            DirectionSequence.shared.content.append(DirectionSequence.ActionType.TakeOff.rawValue)
            callback()
        } else {
            if let mySpark = DJISDKManager.product() as? DJIAircraft {
                if let flightController = mySpark.flightController {
                    flightController.startTakeoff(completion: { (err) in
                        callback()
                        print(err.debugDescription)
                    })
                }
            }
        }
    }
    
    func land() {
        if isTesting {
            DirectionSequence.shared.content.append(DirectionSequence.ActionType.Landing.rawValue)
        } else {
            if let mySpark = DJISDKManager.product() as? DJIAircraft {
                self.stop()
                if let flightController = mySpark.flightController {
                    flightController.startLanding(completion: { (err) in
                        print(err.debugDescription)
                    })
                }
            }
        }
    }
    
    func execute() {
        if let move = self.nextMovement() {
            Timer.scheduledTimer(withTimeInterval: TimeInterval(move.duration), repeats: false) { (t) in
                // Code exécuté après move.duration seconds
                self.execute()
                
                if self.isTesting {
                    print(move.description())
                } else {
                    if let mySpark = DJISDKManager.product() as? DJIAircraft {
                        mySpark.mobileRemoteController?.rightStickVertical = self.speedFactor * Float(move.direction.value().z)
                        mySpark.mobileRemoteController?.rightStickHorizontal = self.speedFactor * Float(move.direction.value().x)
                        mySpark.mobileRemoteController?.leftStickVertical = self.speedFactorY * Float(move.direction.value().y)
                        mySpark.mobileRemoteController?.leftStickHorizontal = self.rotationFactor * Float(move.direction.value().w)
                    }
                }
            }
            
        }
    }
    
    func executeAction() {
        if let action = self.nextAction() {
            Timer.scheduledTimer(withTimeInterval: TimeInterval(action.duration), repeats: false) { (t) in
                // Code exécuté après move.duration seconds
                self.executeAction()
                print(action.description())
                
                if !self.isTesting {
                    switch(action.action) {
                    case .CameraUp:
                        GimbalManager.shared.moveGimbal(direction: .Up)
                    case .CameraDown:
                        GimbalManager.shared.moveGimbal(direction: .Down)
                    case .None:
                        break
                    case .TakeOff:
                        self.takeOff()
                    case .Land:
                        self.land()
                    case .TurnBack:
                        break
                    case .Custom:
                        if let actionCallBack = action.callback {
                            actionCallBack()
                        }
                    }
                } else {
                    switch(action.action) {
                    case .CameraUp:
                        GimbalManager.shared.moveGimbal(direction: .Up)
                    case .CameraDown:
                        GimbalManager.shared.moveGimbal(direction: .Down)
                    case .None:
                        break
                    case .TakeOff:
                        break
                    case .Land:
                        break
                    case .TurnBack:
                        break
                    case .Custom:
                        if let actionCallBack = action.callback {
                            actionCallBack()
                        }
                    }
                }
            }
        }
    }
    
    func setSpeed(speedX: Float, speedY: Float) {
        self.speedFactor = speedX
        self.speedFactorY = speedY
    }
}
