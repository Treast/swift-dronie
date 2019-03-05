//
//  CameraViewController.swift
//  SparkDronie
//
//  Created by Gweltaz calori on 12/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

struct Position {
    var x = 0
    var y = 0
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    @IBOutlet weak var testingImageView: UIImageView!
    var pixelBuffer: CVPixelBuffer?
    
    @IBOutlet weak var trackingBarItem: UIBarButtonItem!
    
    @IBOutlet weak var logTextView: UITextView!
    var objectsToTrack = [TrackedPolyRect]()
    var selectedBounds: TrackedPolyRect?
    
    var previousCenterPoint: CGPoint?
    var calibrationCount = 0
    
    var magnetStartPoint: ParcoursPoint? = nil//ParcoursPoint(x : 10, y: 20)
    var magnet2StartPoint: ParcoursPoint? = nil //ParcoursPoint(x : 50, y: 60)
    var sliderEndPoint: ParcoursPoint? = nil
    
    var isTracking: Bool = false
    var timerDetect: Timer? = nil;
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SocketIOManager.shared.onLogReceived = { str in
            self.logTextView.text += str+"\n"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        SocketIOManager.shared.connect()
        self.registerListenersScene1()
       
    }
    
    func onMagnetOut(startPoint: inout ParcoursPoint?, _ callback : @escaping () -> Void) {
        ParcoursManager.shared.stop()
    }
    
    func onMagnetHover(dataArray:[Any], _ callback : @escaping () -> Void) {
        
        var data = dataArray.first as! [String: NSNumber]
        if
            let ox = data["x1"],
            let oy = data["y1"],
            let x = data["x2"],
            let y = data["y2"],
            let c = data["c"]{
            MovementManager.shared.setSpeed(speedX: 0.7, speedY: 0.68)
            print("Duration: \( 3.5 * Float(c))")
            ParcoursManager.shared.currentPoint = ParcoursPoint(x: Float(ox), y: Float(oy))
            MovementManager.shared.moveTo(x: Float(x), y: Float(y), duration: 3.5 * Float(c)) {
                callback()
            }
            
            //SocketIOManager.shared.emit(event: .MoveToButton,data: [["x": -Float(x), "y": -Float(y)]])
        }
    }
    
    func onClickButton(dataArray:[Any], _ callback : @escaping () -> Void) {
        var data = dataArray.first as! [String: NSNumber]
        if
            let ox = data["x1"],
            let oy = data["y1"],
            let x = data["x2"],
            let y = data["y2"],
            let c = data["c"] {
            MovementManager.shared.setSpeed(speedX: 0.7, speedY: 0.68)
            print("Duration: \( 3.5 * Float(c))")
            ParcoursManager.shared.currentPoint = ParcoursPoint(x: Float(ox), y: Float(oy))
            MovementManager.shared.moveTo(x: Float(x), y: Float(y), duration: 3.5 * Float(c)) {
                callback()
            }
            
            //SocketIOManager.shared.emit(event: .MoveToButton,data: [["x": -Float(x), "y": -Float(y)]])
        }
    }
    
    @IBAction func stopMovement(_ sender: Any) {
        ParcoursManager.shared.stop()
    }
    
    
    
    func registerListenersScene1() {
        SocketIOManager.shared.on(event: .DroneScene1TakeOff) { _ in
            MovementManager.shared.takeOffWithCompletion {
                MovementManager.shared.setSpeed(speedX: 0.2, speedY: 0.2)
                
                let moveDuration:CGFloat = 1.9
                
                MovementManager.shared.appendMovement(movement: Movement(direction: .Down, duration: moveDuration))
                MovementManager.shared.play()
                
                Timer.scheduledTimer(withTimeInterval: TimeInterval(moveDuration), repeats: false) {_ in
                    SocketIOManager.shared.emit(event: .ClientTakeOff)
                }
                
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move1) { _ in
            ParcoursManager.shared.open(file: "parcours8")
            MovementManager.shared.setSpeed(speedX: 0.3, speedY: 0.3)
            ParcoursManager.shared.playParcours(duration: 6) {
                SocketIOManager.shared.emit(event: .ClientScene1Move1)
                MovementManager.shared.standBy()
            }
        }
        
        /*
 SocketIOManager.shared.on(event: .DroneDetect) { dataArray in
            var data = dataArray.first as! [String: NSNumber]
            print("Data received: \(data)")
            
            if
                let x = data["x"],
                let y = data["y"] {
                
                ParcoursManager.shared.currentPoint = ParcoursPoint(x: Float(x), y: Float(y))
                //SocketIOManager.shared.emit(event: .CurrentPoint,data: [ParcoursManager.shared.currentPoint])
            }
            
        }
 */
        
        SocketIOManager.shared.on(event: .DroneScene1Move2) { _ in
            ParcoursManager.shared.open(file: "parcours9")
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.3)
            ParcoursManager.shared.playParcours(duration: 2) {
                SocketIOManager.shared.emit(event: .ClientScene1Move2)
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move3) { _ in
            ParcoursManager.shared.open(file: "parcours10")
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.3)
            ParcoursManager.shared.playParcours(duration: 3) {
                SocketIOManager.shared.emit(event: .ClientScene1Move3)
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Move1) { _ in
            //DRONE FINISHED TRANSFORM -> we can go outside the screen
            ParcoursManager.shared.open(file: "parcours6")
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.3)
            ParcoursManager.shared.playParcours(duration: 3) {
                SocketIOManager.shared.emit(event: .ClientScene2Move1)
                MovementManager.shared.standBy()
            }
        }
        
        /*
        SocketIOManager.shared.on(event: .DroneScene2Magnet1Out) { _ in
            self.onMagnetOut(startPoint: &self.magnetStartPoint, {})
        }
         */
        
        SocketIOManager.shared.on(event: .DroneScene2Magnet1Hover) { (dataArray)  in
            self.onMagnetHover(dataArray: dataArray, {
                SocketIOManager.shared.emit(event: .ClientScene2Magnet1End)
            })
            
        }
        /*
        SocketIOManager.shared.on(event: .DroneScene2Magnet2Out) { _ in
            self.onMagnetOut(startPoint: &self.magnet2StartPoint, {})
        }
 */
        
        SocketIOManager.shared.on(event: .DroneScene2Magnet2Hover) { ( dataArray) in
            self.onMagnetHover(dataArray: dataArray, {
                SocketIOManager.shared.emit(event: .ClientScene2Magnet2End)
            })
        }
        
        
        SocketIOManager.shared.on(event: .DroneScene2SliderInit) { dataArray in
            var data = dataArray.first as! [String: NSNumber]
            
            if
                let x = data["x"],
                let y = data["y"]
            {
                self.sliderEndPoint = ParcoursPoint(x : Float(x), y: Float(y))
            }
            
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Slider1) { dataArray in
            var data = dataArray.first as! [String: NSNumber]
            
            if let value = data["value"] {
                let alphaValue = Float(value)
                
                if(alphaValue >= 1.0) {
                    
                    SocketIOManager.shared.emit(event: .ClientScene2Slider1End)
                }
                    
                else if
                    let currPoint = ParcoursManager.shared.currentPoint,
                    let endPoint = self.sliderEndPoint
                {
                    let pointToGoTo = ParcoursPoint(
                        x : (endPoint.x - currPoint.x) * alphaValue + currPoint.x,
                        y: (endPoint.y - currPoint.y) * alphaValue + currPoint.y
                    )
                    
                    //SocketIOManager.shared.emit(event: .Sliding,data: [pointToGoTo])
                    MovementManager.shared.setSpeed(speedX: 0.45, speedY: 0.4)
                    MovementManager.shared.moveTo(x: pointToGoTo.x, y: pointToGoTo.y)
                }
            }
            
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Button1) { dataArray in
            self.onClickButton(dataArray: dataArray, {
                SocketIOManager.shared.emit(event: .ClientScene2Button1)
            })
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Button2) { dataArray in
            self.onClickButton(dataArray: dataArray, {
                SocketIOManager.shared.emit(event: .ClientScene2Button2)
            })
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Button3) { dataArray in
            self.onClickButton(dataArray: dataArray, {
                SocketIOManager.shared.emit(event: .ClientScene2Button3)
            })
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Button4) { dataArray in
            self.onClickButton(dataArray: dataArray, {
                SocketIOManager.shared.emit(event: .ClientScene2Button4)
            })
        }
        
        SocketIOManager.shared.on(event: .DroneScene3Button1) { dataArray in
            
            //@todo rideau tombe
            //@todo move forward
            //@todo land
            
            Timer.scheduledTimer(withTimeInterval: TimeInterval(6), repeats: false) {_ in
                
                let moveDuration:CGFloat = 3
                
                MovementManager.shared.appendMovement(movement: Movement(direction: .Front, duration: moveDuration))
                MovementManager.shared.play()
                
                Timer.scheduledTimer(withTimeInterval: TimeInterval(moveDuration), repeats: false) {_ in
                    MovementManager.shared.land()
                }
            }
            
            
        }
        
        SocketIOManager.shared.on(event: .DroneStop) { dataArray in
            
            self.stopMovement(self)
            
            
        }
        
        print("Finish register")
    }
}

