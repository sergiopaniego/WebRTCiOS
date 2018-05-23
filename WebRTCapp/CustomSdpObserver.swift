//
//  CustomSdpObserver.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 03/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import WebRTC

class CustomSdpObserver {
    var tag: NSString
    var remoteParticipant: RemoteParticipant
    
    init (tag: NSString, remoteParticipant: RemoteParticipant) {
        self.tag = tag
        self.remoteParticipant = remoteParticipant
    }
}
