//
//  PeersManager.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 20/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import WebRTC
import Starscream

class PeersManager {
    
    var localPeer: RTCPeerConnection?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var configuration: RTCConfiguration?
    var connectionConstraints: RTCMediaConstraints?
    var webSocketListener: WebSocketListener?
    var webSocket: WebSocket?
    var localVideoTrack: RTCVideoTrack?
    var localAudioTrack: RTCAudioTrack?
    var videoGrabber: RTCVideoCapturer?
    var peerConnection: RTCPeerConnection?
    
    init() {
    }
    
    func setWebSocketAdapter(webSocketAdapter: WebSocketListener) {
        self.webSocketListener = webSocketAdapter
    }
    
    // Function that start everything related with WebRTC use
    func start() {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        self.peerConnection = peerConnectionFactory!.peerConnection(with: config, constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: nil)

        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        createLocalPeerConnection(sdpConstraints: sdpConstraints)
    }
    
    func createVideoGrabber() -> RTCVideoCapturer {
        var videoCapturer: RTCVideoCapturer
        videoCapturer = createCameraGrabber()
        return videoCapturer
    }
    
    func createCameraGrabber() -> RTCVideoCapturer {
        return RTCVideoCapturer()
    }
    
    func createLocalPeerConnection(sdpConstraints: RTCMediaConstraints) {
        var iceServers: [RTCIceServer] = []
        let iceServer = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        iceServers.append(iceServer)
        configuration = RTCConfiguration()
        configuration!.iceServers = iceServers
        configuration!.bundlePolicy = .maxBundle
        configuration!.rtcpMuxPolicy = .require
        
        let delegate = localPeerConnectionDelegate(webSocketAdapter: webSocketListener!)
        localPeer = peerConnectionFactory?.peerConnection(with: configuration!, constraints: sdpConstraints, delegate: delegate)
    }
    
    func createLocalOffer(mediaConstraints: RTCMediaConstraints) {
        localPeer!.offer(for: mediaConstraints, completionHandler: { (sessionDescription, error) in
            self.localPeer?.setLocalDescription(sessionDescription!, completionHandler: {(error) in ()})
            var localOfferParams: [String:String] = [:]
            localOfferParams["audioActive"] = "true"
            localOfferParams["videoActive"] = "true"
            localOfferParams["doLoopback"] = "false"
            localOfferParams["frameRate"] = "30"
            localOfferParams["typeOfVideo"] = "CAMERA"
            localOfferParams["sdpOffer"] = sessionDescription?.description
            if (self.webSocketListener?.id)! > 1 {
                self.webSocketListener?.sendJson(method: "publishVideo", params: localOfferParams)
            } else {
                self.webSocketListener?.localOfferParams = localOfferParams
            }
        })
    }
    
    func createRemotePeerConnection(remoteParticipant: RemoteParticipant) {
        var iceServers: [RTCIceServer] = []
        let iceServer = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        iceServers.append(iceServer)
        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        
        configuration = RTCConfiguration()
        configuration!.iceServers = iceServers
        configuration!.bundlePolicy = .maxBundle
        configuration!.rtcpMuxPolicy = .require
        let delegate = remotePeerConnectionDelegate(webSocketAdapter: webSocketListener!, remoteParticipant: remoteParticipant)
        let remotePeer: RTCPeerConnection = (peerConnectionFactory?.peerConnection(with: configuration!, constraints: sdpConstraints, delegate: delegate))!
        // var mediaStream: RTCMediaStream = (peerConnectionFactory?.mediaStream(withStreamId: "105"))!
        // mediaStream.tra
        remoteParticipant.peerConnection = remotePeer
    }
    
    func hangup() {
        if webSocketListener != nil && localPeer != nil {
            webSocketListener?.sendJson(method: "leaveRoom", params: [:])
            webSocket?.disconnect()
            localPeer?.close()
            var participants = webSocketListener?.participants
            for remoteParticipant in (participants?.values)! {
                remoteParticipant.peerConnection?.close()
                // views_container.removeVie(remoteParticipant.view)
            }
        }
        /*if localVideoTrack != nil {
            loalVideoView.removeRender(localRender)
            localVideoView.clearImage()
            videoGrabber.dispose()
        }*/
    }
}
