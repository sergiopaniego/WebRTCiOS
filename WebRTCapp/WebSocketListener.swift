//
//  WebSocketListener.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 01/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

/*
 TODO
 * Connect it to GitHub
 * JSON rfc 2.0
 */

import Foundation
import Starscream

class WebSocketListener: WebSocketDelegate{
    var socket: WebSocket
    var helloWorldTimer: Timer?
    
    init(url: String) {
        socket = WebSocket(url: URL(string: url)!)
        socket.delegate = self
        socket.connect()
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("Connected")
        pingMessageHandler()
    }
    
    func pingMessageHandler() {
        helloWorldTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(WebSocketListener.doPing), userInfo: nil, repeats: true)
    }
    
    @objc func doPing() {
        socket.write(ping: Data())
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("Disconnect: " + error.debugDescription)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("Redieved message: " + text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("Received data: " + data.description)
    }
    
    
}
