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

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var trackingView: TrackingView!
    
    var objectsToTrack = [TrackedPolyRect]()
    var selectedBounds: TrackedPolyRect?
    
    var previousCenterPoint: CGPoint?
    var calibrationCount = 0
    
    var inputObservations = [VNDetectedObjectObservation]()
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return session }
        session.addInput(input)
        return session
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView?.layer.addSublayer(cameraLayer)
        cameraLayer.frame = cameraView.bounds
        cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        trackingView.imageAreaRect = cameraView.bounds
        print(cameraLayer.frame.size)
        print(cameraView.frame.size)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        
        SocketIOManager.shared.connect()
        self.registerListenersScene1()
        self.captureSession.addOutput(videoOutput)
        self.captureSession.startRunning()
    }
    
    @IBAction func calibrate(_ sender: Any) {
        if calibrationCount < 4, let currentCenter = previousCenterPoint {
            SocketIOManager.shared.emit(event: .DroneCalibration, data: DroneDetection(point: currentCenter).toJson())
            calibrationCount += 1
        }
        
        if calibrationCount == 4 {
            self.registerListenersScene1()
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
        if let rect = selectedBounds {
            let inputObservation = VNDetectedObjectObservation(boundingBox: rect.boundingBox)

            inputObservations.append(inputObservation)
        }
        
        clear(self)
        setupTimedDetect()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var trackingRequests = [VNRequest]()
        
        for inputObservation in inputObservations {
            let request = VNTrackObjectRequest(detectedObjectObservation: inputObservation)
            request.trackingLevel = .accurate
            
            trackingRequests.append(request)
        }
        
        do {
            try sequenceRequestHandler.perform(trackingRequests, on: pixelBuffer, orientation: .right)
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
            if let first = self.inputObservations.first {
                self.trackingView.polyRect = TrackedPolyRect(observation: first)
                
                self.previousCenterPoint = first.boundingBox.origin
                
                //do somethin with the bounding box
                self.trackingView.setNeedsDisplay()
            }
        }
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
        Timer.scheduledTimer(withTimeInterval: TimeInterval(0.2), repeats: true) { t in
            if self.calibrationCount >= 4, let point = self.previousCenterPoint {
                SocketIOManager.shared.emit(event: .DroneDetect, data: DroneDetection(point: point).toJson())
            }
        }
    }
    
    func registerListenersScene1() {
        SocketIOManager.shared.on(event: .DroneScene1TakeOff) { _ in
            MovementManager.shared.takeOffWithCompletion {
                SocketIOManager.shared.emit(event: .ClientTakeOff, data: [])
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move1) { _ in
            ParcoursManager.shared.open(file: "parcours2")
            ParcoursManager.shared.playParcours(duration: 10) {
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move2) { _ in
            ParcoursManager.shared.open(file: "parcours3")
            ParcoursManager.shared.playParcours(duration: 4) {
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move3) { _ in
            ParcoursManager.shared.open(file: "parcours4")
            ParcoursManager.shared.playParcours(duration: 4) {
                MovementManager.shared.standBy()
            }
        }
        print("Finish register")
    }
}
