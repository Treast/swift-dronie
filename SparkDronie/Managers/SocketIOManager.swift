//
//  SocketIoManager.swift
//  SparkDronie
//
//  Created by Vincent Riva on 11/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation
import SocketIO

struct VirtualEvent {
    var event: DroneEvent
    var callback: (_ data:[Any]) -> Void
    
    init(event: DroneEvent, callback: @escaping (_ data:[Any]) -> Void) {
        self.event = event
        self.callback = callback
    }
}

class SocketIOManager {
    static let shared: SocketIOManager = SocketIOManager()
    
    private let manager: SocketManager
    private let socketURL: String = "https://dronie.vincentriva.fr"
    private let socket: SocketIOClient
    private var stockedEvents: [VirtualEvent]
    
    private init() {
        self.manager = SocketManager(socketURL: URL(string: self.socketURL)!, config: [.log(false), .compress])
        self.socket = manager.defaultSocket
        self.stockedEvents = []
    }
    
    func on(event: DroneEvent, callback : @escaping (_ data:[Any]) -> Void) {
        self.stockedEvents.append(VirtualEvent(event: event, callback: callback))
        self.socket.on(event.rawValue) { (dataArray, ack) in
            
            callback(dataArray)
            
            if event != DroneEvent.DroneDetect {
                print("Socket received: \(event.rawValue)")
            }
        }
    }
    
    func virtualEmit(event: DroneEvent, data: [Any] = []) {
        for virtualEvent in stockedEvents {
            if virtualEvent.event == event {
                virtualEvent.callback(data)
            }
        }
    }
    
    func emit(event: DroneEvent, data: Any? = nil) {
        self.socket.emit(event.rawValue, with: [data])
        print("Socket emit: \(event.rawValue)")
    }
    
    func connect() {
        self.socket.connect()
        self.socket.on("connect") { (dataArray, ack) in
            print("Socket connected")
        }
    }
}
