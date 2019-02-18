//
//  SocketIoManager.swift
//  SparkDronie
//
//  Created by Vincent Riva on 11/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation
import SocketIO

class SocketIOManager {
    static let shared: SocketIOManager = SocketIOManager()
    
    private let manager: SocketManager
    private let socketURL: String = "https://dronie.vincentriva.fr"
    private let socket: SocketIOClient
    
    private init() {
        self.manager = SocketManager(socketURL: URL(string: self.socketURL)!, config: [.log(false), .compress])
        self.socket = manager.defaultSocket
    }
    
    func on(event: DroneEvent, callback : @escaping (_ data:Any) -> Void) {
        self.socket.on(event.rawValue) { (dataArray, ack) in
            callback(dataArray)
            print("Socket received: \(event.rawValue)")
        }
    }
    
    func emit(event: DroneEvent, data: Any = []) {
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
