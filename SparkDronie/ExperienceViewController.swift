//
//  ExperienceViewController.swift
//  SparkDronie
//
//  Created by Vincent Riva on 11/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation
import UIKit

class ExperienceViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        SocketIOManager.shared.connect()
        self.registerListenersScene1()
    }
    
    func registerListenersScene1() {
        SocketIOManager.shared.on(event: .DroneScene1TakeOff) { _ in
            MovementManager.shared.takeOffWithCompletion {
                SocketIOManager.shared.emit(event: .ClientTakeOff)
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move1) { _ in
            ParcoursManager.shared.open(file: "parcours2")
            ParcoursManager.shared.playParcours(duration: 5) {
                SocketIOManager.shared.emit(event: .ClientScene1Move1)
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move2) { _ in
            ParcoursManager.shared.open(file: "parcours3")
            ParcoursManager.shared.playParcours(duration: 3) {
                SocketIOManager.shared.emit(event: .ClientScene1Move2)
                MovementManager.shared.standBy()
            }
        }
        
        SocketIOManager.shared.on(event: .DroneScene1Move3) { _ in
            ParcoursManager.shared.open(file: "parcours4")
            ParcoursManager.shared.playParcours(duration: 3) {
                SocketIOManager.shared.emit(event: .ClientScene1Move3)
                MovementManager.shared.standBy()
            }
        }
        print("Finish register")
    }
}
