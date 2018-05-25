//
//  PeersManager.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 20/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import WebRTC

class PeersManager {
    
    var localPeer: RTCPeerConnection?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    private var configuration: RTCConfiguration?
    private var connectionConstraints: RTCMediaConstraints?
    
    init() {
    }
    
    // Function that start everything related with WebRTC use
    func start() {
        
    }
    
    func createVideoGrabber() {
        
    }
    
    func createCameraGrabber() {
        
    }
    
    func createLocalPeerConnection() {
        
    }
    
    func createLocalOffer() {
        
    }
    
    func createRemotePeerConnection(sdpConstraints: RTCMediaConstraints) {
        var iceServers: [RTCIceServer] = []
        let iceServer = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        iceServers.append(iceServer)
        configuration = RTCConfiguration()
        configuration!.iceServers = iceServers
        configuration!.bundlePolicy = .maxBundle
        configuration!.rtcpMuxPolicy = .require
        
        let connectionConstraintsDict = ["DtlsSrtpKeyAgreement": "true"]
        connectionConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: connectionConstraintsDict)
        let delegate = CustomPeerConnectionDelegate()
        localPeer = peerConnectionFactory?.peerConnection(with: configuration!, constraints: connectionConstraints!, delegate: delegate)
    }
    
    func hangup() {
        
    }
}
