//
//  TrackingView.swift
//  DroniSocket
//
//  Created by Gweltaz calori on 09/02/2019.
//  Copyright © 2019 Gweltaz calori. All rights reserved.
//

import Foundation
import UIKit
import Vision

class TrackingView: UIView {
    
    var polyRect:TrackedPolyRect?
    var imageAreaRect = CGRect.zero
    var rubberbandingStart = CGPoint.zero
    var rubberbandingVector = CGPoint.zero
    var rubberbandingRect: CGRect {
        let pt1 = self.rubberbandingStart
        let pt2 = CGPoint(x: self.rubberbandingStart.x + self.rubberbandingVector.x, y: self.rubberbandingStart.y + self.rubberbandingVector.y)
        let rect = CGRect(x: min(pt1.x, pt2.x), y: min(pt1.y, pt2.y), width: abs(pt1.x - pt2.x), height: abs(pt1.y - pt2.y))
        
        return rect
    }
    
    var rubberbandingRectNormalized: CGRect {
        guard imageAreaRect.size.width > 0 && imageAreaRect.size.height > 0 else {
            return CGRect.zero
        }
        var rect = rubberbandingRect
        
        // Make it relative to imageAreaRect
        rect.origin.x = (rect.origin.x - self.imageAreaRect.origin.x) / self.imageAreaRect.size.width
        rect.origin.y = (rect.origin.y - self.imageAreaRect.origin.y) / self.imageAreaRect.size.height
        rect.size.width /= self.imageAreaRect.size.width
        rect.size.height /= self.imageAreaRect.size.height
        // Adjust to Vision.framework input requrement - origin at LLC
        rect.origin.y = 1.0 - rect.origin.y - rect.size.height
        
        return rect
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.saveGState()
        
        ctx.clear(rect)
        
        if self.rubberbandingRect != CGRect.zero {
            ctx.setStrokeColor(UIColor.blue.cgColor)
            
            ctx.stroke(self.rubberbandingRect)
        }
        
        if let poly = self.polyRect {
            ctx.setStrokeColor(UIColor.blue.cgColor)
            
            let cornerPoints = poly.cornerPoints
            var previous = scale(cornerPoint: cornerPoints[cornerPoints.count - 1], toImageViewPointInViewRect: rect)
            for cornerPoint in cornerPoints {
                ctx.move(to: previous)
                let current = scale(cornerPoint: cornerPoint, toImageViewPointInViewRect: rect)
                ctx.addLine(to: current)
                previous = current
            }
            ctx.strokePath()
        }
        
        
    }
    
    private func scale(cornerPoint point: CGPoint, toImageViewPointInViewRect viewRect: CGRect) -> CGPoint {
        // Adjust bBox from Vision.framework coordinate system (origin at LLC) to imageView coordinate system (origin at ULC)
        let pointY = 1.0 - point.y
        let scaleFactor = self.imageAreaRect.size
        
        return CGPoint(x: point.x * scaleFactor.width + self.imageAreaRect.origin.x, y: pointY * scaleFactor.height + self.imageAreaRect.origin.y)
    }
}



struct TrackedPolyRect {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
    
    var cornerPoints: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
    
    var boundingBox: CGRect {
        let topLeftRect = CGRect(origin: topLeft, size: .zero)
        let topRightRect = CGRect(origin: topRight, size: .zero)
        let bottomLeftRect = CGRect(origin: bottomLeft, size: .zero)
        let bottomRightRect = CGRect(origin: bottomRight, size: .zero)
        
        return topLeftRect.union(topRightRect).union(bottomLeftRect).union(bottomRightRect)
    }
    
    init(observation: VNDetectedObjectObservation) {
        self.init(cgRect: observation.boundingBox)
    }
    
    init(observation: VNRectangleObservation) {
        topLeft = observation.topLeft
        topRight = observation.topRight
        bottomLeft = observation.bottomLeft
        bottomRight = observation.bottomRight
    }
    
    init(cgRect: CGRect) {
        topLeft = CGPoint(x: cgRect.minX, y: cgRect.maxY)
        topRight = CGPoint(x: cgRect.maxX, y: cgRect.maxY)
        bottomLeft = CGPoint(x: cgRect.minX, y: cgRect.minY)
        bottomRight = CGPoint(x: cgRect.maxX, y: cgRect.minY)
    }
}
