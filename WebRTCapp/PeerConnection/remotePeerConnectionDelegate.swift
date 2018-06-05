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
    var view: UIView?
    
    init(webSocketAdapter: WebSocketListener, remoteParticipant: RemoteParticipant/*, view: UIView*/) {
        self.webSocketAdapter = webSocketAdapter
        self.remoteParticipant = remoteParticipant
        // self.view = view
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
        let remoteVideoView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        remoteParticipant.view = remoteVideoView
        self.view?.addSubview(remoteVideoView)
        let renderer = RTCMTLVideoView(frame: remoteVideoView.frame)
        stream.videoTracks.first?.add(renderer)
        self.embedView(renderer, into: remoteVideoView)
    }
    
    func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }

}
