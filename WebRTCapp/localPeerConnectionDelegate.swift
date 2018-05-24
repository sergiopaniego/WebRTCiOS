//
//  localPeerConnectionDelegate.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 24/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import WebRTC

class localPeerConnectionDelegate: CustomPeerConnectionDelegate {
    override func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
super.peerConnection(<#T##peerConnection: RTCPeerConnection##RTCPeerConnection#>, didGenerate: <#T##RTCIceCandidate#>)
        var iceCandidateParams: [String: String] = [:]
        iceCandidateParams["sdpMid"] = candidate.sdpMid
        iceCandidateParams["sdpMLineIndex"] = String(candidate.sdpMLineIndex)
        iceCandidateParams["candidate"] = String(candidate.sdpMLineIndex)
        // TODO!
    }
}
