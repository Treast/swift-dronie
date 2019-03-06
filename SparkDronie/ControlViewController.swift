//
//  ControlViewController.swift
//  SparkDronie
//
//  Created by Vincent Riva on 05/03/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation
import UIKit

class ControlViewController: UIViewController {
    
    func setSpeed() {
        MovementManager.shared.setSpeed(speedX: 0.2, speedY: 0.3)
    }

    
    @IBAction func onUpButtonPressed(_ sender: Any) {
        self.setSpeed()
        MovementManager.shared.forceMove(move: .Up)
        print("Up")
    }
    
    @IBAction func onDownButtonPressed(_ sender: Any) {
        self.setSpeed()
        MovementManager.shared.forceMove(move: .Down)
        print("Down")
    }
    
    @IBAction func onLeftButtonPressed(_ sender: Any) {
        self.setSpeed()
        MovementManager.shared.forceMove(move: .Left)
        print("Left")
    }
    
    @IBAction func onRightButtonPressed(_ sender: Any) {
        self.setSpeed()
        MovementManager.shared.forceMove(move: .Right)
        print("Right")
    }
    
    @IBAction func onFrontPressed(_ sender: Any) {
        self.setSpeed()
        MovementManager.shared.forceMove(move: .Front)
        print("Front")
    }
    
    @IBAction func onBackPressed(_ sender: Any) {
        MovementManager.shared.forceMove(move: .Back)
    }
    
    @IBAction func onButtonReleased(_ sender: Any) {
        MovementManager.shared.stop()
    }
    
    @IBAction func onTakeOffPressed(_ sender: Any) {
        MovementManager.shared.stop()
        MovementManager.shared.takeOff()
    }
    
    @IBAction func onLandPressed(_ sender: Any) {
        MovementManager.shared.stop()
        MovementManager.shared.land()
    }
}
