//
//  RemoteParticipant.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 08/04/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import WebRTC
import Starscream

class RemoteParticipant {
    
    var id: String?
    var mediaStream: RTCMediaStream?
    var peerConnection: RTCPeerConnection?
    var audioTrack: RTCAudioTrack?
    var videoTrack: RTCVideoTrack?
    var view: UIView?
    var participantName: String?
    var index: Int?
    /*var videoView: RTCSurfaceViewRenderer
    var view: View
    var participantNameText: TextField*/
    
    init() {
        
    }
    
    convenience init(id: String, mediaStream: RTCMediaStream, peerConnection: RTCPeerConnection, audioTrack: RTCAudioTrack, videoTrack: RTCVideoTrack/*,
         videoView: SurfaceViewRenderer, view: View, participantNameText: TextField*/) {
        self.init()
        self.id = id
        self.mediaStream = mediaStream
        self.peerConnection = peerConnection
        self.audioTrack = audioTrack
        self.videoTrack = videoTrack
        /*self.videoView = videoView
        self.view = view
        self.participantNameText = participantNameText*/
    }
}
