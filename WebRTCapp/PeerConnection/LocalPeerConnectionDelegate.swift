//
//  localPeerConnectionDelegate.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 24/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import WebRTC

class LocalPeerConnectionDelegate: CustomPeerConnectionDelegate {
    
    var webSocketAdapter: WebSocketListener
    
    init(webSocketAdapter: WebSocketListener) {
        self.webSocketAdapter = webSocketAdapter
    }
    
    override func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        super.peerConnection(peerConnection, didGenerate: candidate)
        var iceCandidateParams: [String: String] = [:]
        iceCandidateParams["sdpMid"] = candidate.sdpMid
        iceCandidateParams["sdpMLineIndex"] = String(candidate.sdpMLineIndex)
        iceCandidateParams["candidate"] = String(candidate.sdpMLineIndex)
        if webSocketAdapter.userId != nil {
            iceCandidateParams["endpointName"] =  webSocketAdapter.userId
            webSocketAdapter.sendJson(method: "onIceCandidate", params: iceCandidateParams)
        } else {
            webSocketAdapter.addIceCandidate(iceCandidateParams: iceCandidateParams)
        }
    }
}
