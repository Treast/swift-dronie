//
//  DroneEvent.swift
//  SparkDronie
//
//  Created by Vincent Riva on 11/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation

enum DroneEvent: String {
    
    case DroneScene1TakeOff = "DRONE:SCENE1:TAKEOFF",
    DroneScene1Move1 = "DRONE:SCENE1:MOVE1",
    DroneScene1Move2 = "DRONE:SCENE1:MOVE2",
    DroneScene1Move3 = "DRONE:SCENE1:MOVE3",
    DroneScene2Move1 = "DRONE:SCENE2:MOVE1",
    DroneScene2Magnet1 = "DRONE:SCENE2:MAGNET1",
    DroneScene2Magnet2 = "DRONE:SCENE2:MAGNET2",
    DroneScene2Slider1 = "DRONE:SCENE2:SLIDER1",
    DroneScene2Slider2 = "DRONE:SCENE2:SLIDER2",
    DroneScene2Button1 = "DRONE:SCENE2:BUTTON1",
    DroneScene2Button2 = "DRONE:SCENE2:BUTTON2",
    DroneScene2Button3 = "DRONE:SCENE2:BUTTON3",
    DroneScene3Button1 = "DRONE:SCENE3:BUTTON1",
    DroneScene3Land = "DRONE:SCENE3:LAND",
    DroneCalibration = "DRONE:CALIBRATION",
    DroneDetect = "DRONE:DETECT",
    ClientTakeOff = "CLIENT:SCENE1:TAKEOFF",
    ClientScene1Move1 = "CLIENT:SCENE1:MOVE1",
    ClientScene1Move2 = "CLIENT:SCENE1:MOVE2",
    ClientScene2Move1 = "CLIENT:SCENE2:MOVE1",
    ClientScene2Button1 = "CLIENT:SCENE2:BUTTON1",
    ClientScene2Button2 = "CLIENT:SCENE2:BUTTON2"
}
