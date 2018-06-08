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

class PeersManager: NSObject {
    
    var localPeer: RTCPeerConnection?
    var remotePeer: RTCPeerConnection?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var connectionConstraints: RTCMediaConstraints?
    var webSocketListener: WebSocketListener?
    var webSocket: WebSocket?
    var localVideoTrack: RTCVideoTrack?
    var localAudioTrack: RTCAudioTrack?
    var peerConnection: RTCPeerConnection?
    var view: UIView!
    var renderer: RTCMTLVideoView!
    private var videoCapturer: RTCVideoCapturer?
    var remoteStreams: [RTCMediaStream]
    var remoteParticipant: RemoteParticipant?
    
    init(view: UIView) {
        self.view = view
        self.remoteStreams = []
    }
    
    func setWebSocketAdapter(webSocketAdapter: WebSocketListener) {
        self.webSocketListener = webSocketAdapter
    }
    
    // Function that start everything related with WebRTC use
    func start() {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)

        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        createLocalPeerConnection(sdpConstraints: sdpConstraints)
    }
    
    func createLocalPeerConnection(sdpConstraints: RTCMediaConstraints) {
        let config = RTCConfiguration()
        config.bundlePolicy = .maxCompat
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.rtcpMuxPolicy = .require

        localPeer = peerConnectionFactory!.peerConnection(with: config, constraints: sdpConstraints, delegate: nil)
    }
    
    func createLocalOffer(mediaConstraints: RTCMediaConstraints) {
        localPeer!.offer(for: mediaConstraints, completionHandler: { (sessionDescription, error) in
            self.localPeer!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                print("Local Peer local Description set: " + error.debugDescription)
            })
            var localOfferParams: [String:String] = [:]
            localOfferParams["audioActive"] = "true"
            localOfferParams["videoActive"] = "true"
            localOfferParams["doLoopback"] = "false"
            localOfferParams["frameRate"] = "30"
            localOfferParams["typeOfVideo"] = "CAMERA"
            localOfferParams["sdpOffer"] = sessionDescription!.sdp
            if (self.webSocketListener!.id) > 1 {
                self.webSocketListener!.sendJson(method: "publishVideo", params: localOfferParams)
            } else {
                self.webSocketListener!.localOfferParams = localOfferParams
            }
        })
    }
    
    func createRemotePeerConnection(remoteParticipant: RemoteParticipant) {
        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        
        let config = RTCConfiguration()
        config.bundlePolicy = .maxCompat
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.rtcpMuxPolicy = .require
        self.remotePeer = (peerConnectionFactory?.peerConnection(with: config, constraints: sdpConstraints, delegate: nil))!
        remoteParticipant.peerConnection = self.remotePeer
        self.remoteParticipant = remoteParticipant
        self.remoteParticipant?.peerConnection = self.remotePeer
    }
    
    func hangup() {
        if webSocketListener != nil && localPeer != nil {
            webSocketListener!.sendJson(method: "leaveRoom", params: [:])
            webSocket!.disconnect()
            localPeer!.close()
            var participants = webSocketListener!.participants
            for remoteParticipant in (participants.values) {
                remoteParticipant.peerConnection!.close()
                // views_container.removeView(remoteParticipant.view)
            }
        }
        /*if localVideoTrack != nil {
            loalVideoView.removeRender(localRender)
            localVideoView.clearImage()
            videoGrabber.dispose()
        }*/
    }

}

extension PeersManager: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if peerConnection == self.localPeer {
            print("local peerConnection did add stream")
        } else {
            print("remote peerConnection did add stream")
            
            if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
                print("Weird looking stream")
            }
            remoteStreams.append(stream)
            // self.remoteStream = stream
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("peerConnection did remote stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        if peerConnection == self.localPeer {
            print("local peerConnection should negotiate")
        } else {
            print("remote peerConnection should negotiate")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("peerConnection new connection state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("peerConnection new gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if peerConnection == self.localPeer {
            var iceCandidateParams: [String: String] = [:]
            iceCandidateParams["sdpMid"] = candidate.sdpMid
            iceCandidateParams["sdpMLineIndex"] = String(candidate.sdpMLineIndex)
            iceCandidateParams["candidate"] = String(candidate.sdp)
            if self.webSocketListener!.userId != nil {
                iceCandidateParams["endpointName"] =  self.webSocketListener!.userId
                self.webSocketListener!.sendJson(method: "onIceCandidate", params: iceCandidateParams)
            } else {
                self.webSocketListener!.addIceCandidate(iceCandidateParams: iceCandidateParams)
            }
            print("NEW local ice candidate")
        } else {
            var iceCandidateParams: [String: String] = [:]
            iceCandidateParams["sdpMid"] = candidate.sdpMid
            iceCandidateParams["sdpMLineIndex"] = String(candidate.sdpMLineIndex)
            iceCandidateParams["candidate"] = String(candidate.sdp)
            iceCandidateParams["endpointName"] =  self.remoteParticipant!.id
            self.webSocketListener!.sendJson(method: "onIceCandidate", params: iceCandidateParams)
            print("NEW remote ice candidate")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peerConnection did open data channel")
    }
}
