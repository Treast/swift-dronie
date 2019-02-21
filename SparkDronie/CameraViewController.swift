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
import GPUImage

struct Position {
    var x = 0
    var y = 0
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    @IBOutlet weak var testingImageView: UIImageView!
    var pixelBuffer: CVPixelBuffer?
    
    @IBOutlet weak var cameraView: RenderView!
    @IBOutlet weak var trackingView: TrackingView!
    @IBOutlet weak var trackingBarItem: UIBarButtonItem!
    
    var objectsToTrack = [TrackedPolyRect]()
    var selectedBounds: TrackedPolyRect?
    
    var previousCenterPoint: CGPoint?
    var calibrationCount = 0
    
    var magnetStartPoint: ParcoursPoint? = nil//ParcoursPoint(x : 10, y: 20)
    var magnet2StartPoint: ParcoursPoint? = nil //ParcoursPoint(x : 50, y: 60)
    var sliderEndPoint: ParcoursPoint? = nil
    
    var isTracking: Bool = false
    var timerDetect: Timer? = nil;
    
    let videoCamera:Camera?
    let filter = SobelEdgeDetection()
    
    var inputObservations = [VNDetectedObjectObservation]()
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        guard
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return session }
        session.addInput(input)
        return session
    }()
    
    required init(coder aDecoder: NSCoder)
    {
        do {
            videoCamera = try Camera(sessionPreset:.vga640x480, location:.backFacing)
        } catch {
            videoCamera = nil
            print("Couldn't initialize camera with error: \(error)")
        }
        
        super.init(coder: aDecoder)!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        filter.edgeStrength = Configuration.shared.filterValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoCamera!.addTarget(cameraView)
        cameraLayer.frame = cameraView.bounds
        cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        
        trackingView.imageAreaRect = cameraView.bounds
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        
        SocketIOManager.shared.connect()
        self.registerListenersScene1()
        /**
         *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[AVCaptureSession addOutput:] Cannot add output <AVCaptureVideoDataOutput: 0x281259100> to capture session <AVCaptureSession: 0x281078470 [AVCaptureSessionPresetInputPriority]> because more than one output of the same type is unsupported'
        */
        // videoCamera!.captureSession.addOutput(videoOutput) -> Bug
        videoCamera?.delegate = self
        videoCamera?.startCapture()
    }
    
    @IBAction func calibrate(_ sender: Any) {
        if calibrationCount < 4, let currentCenter = previousCenterPoint {
            SocketIOManager.shared.emit(event: .DroneCalibration, data: DroneDetection(point: currentCenter).toJson())
            calibrationCount += 1
        }
    }
    
    func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
            
        case .landscapeLeft:
            return .downMirrored
            
        case .landscapeRight:
            return .upMirrored
            
        default:
            return .leftMirrored
        }
    }
    
    
    func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }
    
    @IBAction func clear(_ sender: Any) {
        self.selectedBounds = nil
        trackingView.rubberbandingStart = CGPoint.zero
        trackingView.rubberbandingVector = CGPoint.zero
        trackingView.setNeedsDisplay()
    }
    
    @IBAction func startTracking(_ sender: Any) {
        if isTracking {
            if let t = timerDetect {
                t.invalidate()
            }
            isTracking = false
            self.trackingView.polyRect = nil
            self.selectedBounds = nil
            trackingView.rubberbandingStart = CGPoint.zero
            trackingView.rubberbandingVector = CGPoint.zero
            self.trackingView.setNeedsDisplay()
        } else {
            isTracking = true
            if let rect = selectedBounds {
                let inputObservation = VNDetectedObjectObservation(boundingBox: rect.boundingBox)
                
                inputObservations.append(inputObservation)
            }
            
            clear(self)
            setupTimedDetect()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    
    
    @IBAction func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            let locationInView = gestureRecognizer.location(in: trackingView)
            trackingView.rubberbandingStart = locationInView
        case .changed:
            let translation = gestureRecognizer.translation(in: trackingView)
            
            trackingView.rubberbandingVector = translation
            trackingView.setNeedsDisplay()
        case .ended:
            let selectedBBox = trackingView.rubberbandingRectNormalized
            if selectedBBox.width > 0 && selectedBBox.height > 0 {
                self.selectedBounds = TrackedPolyRect(cgRect: selectedBBox)
            }
        default:
            break
        }
    }
    
    func setupTimedDetect() {
        timerDetect = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.2), repeats: true) { t in
            if self.calibrationCount >= 4, let point = self.previousCenterPoint {
                SocketIOManager.shared.emit(event: .DroneDetect, data: DroneDetection(point: point).toJson())
            }
        }
    }
    
    func onMagnetOut(startPoint: inout ParcoursPoint?, _ callback : @escaping () -> Void) {
        ParcoursManager.shared.stop()
        if let startPointValue = startPoint {
            ParcoursManager.shared.stop()
            /*MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.55)
            MovementManager.shared.moveTo(x: startPointValue.x, y: startPointValue.y) { //move back to start ponit
                callback()
            }*/
        }
    }
    
    func onMagnetHover(startPoint: inout ParcoursPoint?,dataArray:[Any], _ callback : @escaping () -> Void) {
        if startPoint == nil {
            startPoint = ParcoursManager.shared.currentPoint
        }
        
        ParcoursManager.shared.stop()
        var data = dataArray.first as! [String: NSNumber]
        print("Data received: \(data)")
        
        if
            let x = data["x"],
            let y = data["y"] {
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.55)
            MovementManager.shared.moveTo(x: Float(x), y: Float(y)) {
                callback()
            }
        }
    }
    
    func onClickButton(dataArray:[Any], _ callback : @escaping () -> Void) {
        var data = dataArray.first as! [String: NSNumber]
        if
            let x = data["x"],
            let y = data["y"] {
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.55)
            MovementManager.shared.moveTo(x: Float(x), y: Float(y)) {
                callback()
            }
        }
    }
    
    @IBAction func stopMovement(_ sender: Any) {
        ParcoursManager.shared.stop()
    }
    
    func registerListenersScene1() {
        SocketIOManager.shared.on(event: .DroneScene1TakeOff) { _ in
            MovementManager.shared.takeOffWithCompletion {
                SocketIOManager.shared.emit(event: .ClientTakeOff)
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move1) { _ in
            ParcoursManager.shared.open(file: "parcours1")
            MovementManager.shared.setSpeed(speedX: 0.3, speedY: 0.4)
            ParcoursManager.shared.playParcours(duration: 6) {
                SocketIOManager.shared.emit(event: .ClientScene1Move1)
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move2) { _ in
            ParcoursManager.shared.open(file: "parcours2")
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.55)
            ParcoursManager.shared.playParcours(duration: 2) {
                SocketIOManager.shared.emit(event: .ClientScene1Move2)
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move3) { _ in
            ParcoursManager.shared.open(file: "parcours5")
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.55)
            ParcoursManager.shared.playParcours(duration: 3) {
                SocketIOManager.shared.emit(event: .ClientScene1Move3)
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Move1) { _ in
            //DRONE FINISHED TRANSFORM -> we can go outside the screen
            ParcoursManager.shared.open(file: "parcours6")
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.55)
            ParcoursManager.shared.playParcours(duration: 3) {
                SocketIOManager.shared.emit(event: .ClientScene2Move1)
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Magnet1Out) { _ in
            
            self.onMagnetOut(startPoint: &self.magnetStartPoint, {})
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Magnet1Hover) { (dataArray)  in
            print(dataArray)
            self.onMagnetHover(startPoint: &self.magnetStartPoint, dataArray: dataArray, {
                SocketIOManager.shared.emit(event: .ClientScene2Magnet1End)
            })
            
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Magnet2Out) { _ in
            self.onMagnetOut(startPoint: &self.magnet2StartPoint, {})
        }
        
        SocketIOManager.shared.on(event: .DroneScene2Magnet2Hover) { ( dataArray) in
            
            self.onMagnetHover(startPoint: &self.magnet2StartPoint, dataArray: dataArray, {
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
        
        print("Finish register")
    }
}

extension CameraViewController: CameraDelegate {
    func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // self.pixelBuffer = pixelBuffer
        
        guard isTracking else {
            return
        }
        
        var trackingRequests = [VNRequest]()
        
        for inputObservation in inputObservations {
            let request = VNTrackObjectRequest(detectedObjectObservation: inputObservation)
            request.trackingLevel = .accurate
            
            trackingRequests.append(request)
        }
        
        do {
            try sequenceRequestHandler.perform(trackingRequests, on: pixelBuffer, orientation: .up)
        } catch {
            
        }
        
        for processedRequest in trackingRequests {
            guard let results = processedRequest.results as? [VNObservation] else {
                continue
            }
            guard let observation = results.first as? VNDetectedObjectObservation else {
                continue
            }
            inputObservations = []
            inputObservations.append(observation)
        }
        
        DispatchQueue.main.async {
            /**
                if let pixel = self.pixelBuffer {
                    // self.testingImageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixel))
                }
                self.testingImageView.image = self.pictureOutput.synchronousImageCapture()
            */
            if let first = self.inputObservations.first {
                self.trackingView.polyRect = TrackedPolyRect(observation: first)
                
                self.previousCenterPoint = first.boundingBox.origin
                print(first.boundingBox)
                
                //do somethin with the bounding box
                self.trackingView.setNeedsDisplay()
            }
        }
    }
    
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
}
