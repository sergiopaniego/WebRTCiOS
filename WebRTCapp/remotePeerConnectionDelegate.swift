//
//  remotePeerConnectionDelegate.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 25/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import WebRTC

class remotePeerConnectionDelegate: CustomPeerConnectionDelegate {
    
    var webSocketAdapter: WebSocketListener
    var remoteParticipant: RemoteParticipant
    
    init(webSocketAdapter: WebSocketListener, remoteParticipant: RemoteParticipant) {
        self.webSocketAdapter = webSocketAdapter
        self.remoteParticipant = remoteParticipant
    }
    
    override func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        super.peerConnection(peerConnection, didGenerate: candidate)
        var iceCandidateParams: [String: String] = [:]
        iceCandidateParams["sdpMid"] = candidate.sdpMid
        iceCandidateParams["sdpMLineIndex"] = String(candidate.sdpMLineIndex)
        iceCandidateParams["candidate"] = String(candidate.sdpMLineIndex)
        iceCandidateParams["endpointName"] =  remoteParticipant.id
        webSocketAdapter.sendJson(method: "onIceCandidate", params: iceCandidateParams)
    }
    
    override func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        super.peerConnection(peerConnection, didAdd: stream)
        // Add Media Stream to the view
    }

}
