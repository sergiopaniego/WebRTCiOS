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
    private var configuration: RTCConfiguration?
    private var connectionConstraints: RTCMediaConstraints?
    private var webSocketListener: WebSocketListener?
    private var webSocket: WebSocket?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var videoGrabber: RTCVideoCapturer?
    
    init() {
    }
    
    // Function that start everything related with WebRTC use
    func start() {
        peerConnectionFactory = RTCPeerConnectionFactory()
        videoGrabber = createVideoGrabber()
        var contraints: RTCMediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        
        var videoSource = peerConnectionFactory?.videoSource()
        localVideoTrack = peerConnectionFactory?.videoTrack(with: videoSource!, trackId: "100")
        
        var audioSource = peerConnectionFactory?.audioSource(with: contraints)
        localAudioTrack = peerConnectionFactory?.audioTrack(with: audioSource!, trackId: "101")
        
        if videoGrabber != nil {
            // videoGrabber.
        }
        
        // var localRenderer = RTCVideoRenderer()
        // localVideoTrack?.add(localRenderer)
        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        var sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        createLocalPeerConnection(sdpConstraints: sdpConstraints)
    }
    
    func createVideoGrabber() -> RTCVideoCapturer {
        var videoCapturer: RTCVideoCapturer
        videoCapturer = createCameraGrabber()
        return videoCapturer
    }
    
    func createCameraGrabber() -> RTCVideoCapturer {
        
    }
    
    func createLocalPeerConnection(sdpConstraints: RTCMediaConstraints) {
        var iceServers: [RTCIceServer] = []
        let iceServer = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        iceServers.append(iceServer)
        configuration = RTCConfiguration()
        configuration!.iceServers = iceServers
        configuration!.bundlePolicy = .maxBundle
        configuration!.rtcpMuxPolicy = .require
        
        let delegate = CustomPeerConnectionDelegate()
        localPeer = peerConnectionFactory?.peerConnection(with: configuration!, constraints: sdpConstraints, delegate: delegate)
    }
    
    func createLocalOffer(mediaConstraints: RTCMediaConstraints) {
        localPeer?.offer(for: mediaConstraints, completionHandler: { (sessionDescription, error) in
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
        var sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        
        configuration = RTCConfiguration()
        configuration!.iceServers = iceServers
        configuration!.bundlePolicy = .maxBundle
        configuration!.rtcpMuxPolicy = .require
        let delegate = remotePeerConnectionDelegate(webSocketAdapter: webSocketListener!, remoteParticipant: remoteParticipant)
        var remotePeer: RTCPeerConnection = (peerConnectionFactory?.peerConnection(with: configuration!, constraints: sdpConstraints, delegate: delegate))!
        // var mediaStream: RTCMediaStream = (peerConnectionFactory?.mediaStream(withStreamId: "105"))!
        // mediaStream.tra
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
