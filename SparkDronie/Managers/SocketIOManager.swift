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
    private let socketURL: String = "http://localhost:8080"
    private let socket: SocketIOClient
    
    private init() {
        self.manager = SocketManager(socketURL: URL(string: self.socketURL)!, config: [.log(true), .compress])
        self.socket = manager.defaultSocket
    }
    
    func on(event: String, callback : @escaping (_ data:Any) -> Void) {
        self.socket.on(event) { (dataArray, ack) in
            callback(dataArray)
        }
    }
    
    func emit(event: String, data: Any) {
        self.socket.emit(event, with: [data])
    }
    
    func connect() {
        self.socket.connect()
    }
}
