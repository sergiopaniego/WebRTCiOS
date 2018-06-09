//
//  WebSocketListener.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 01/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import Starscream
import WebRTC

class WebSocketListener: WebSocketDelegate {
    let JSON_RPCVERSION = "2.0"
    let useSSL = true
    
    var socket: WebSocket
    var helloWorldTimer: Timer?
    var id = 0
    var url: String
    var sessionName: String
    var participantName: String
    var localOfferParams: [String: String]?
    var iceCandidatesParams: [[String:String]]?
    var userId: String?
    var remoteParticipantId: String?
    var participants: [String: RemoteParticipant]
    var localPeer: RTCPeerConnection?
    var peersManager: PeersManager
    var token: String
    private var videoCapturer: RTCVideoCapturer?
    var views: [UIView]!
    
    init(url: String, sessionName: String, participantName: String, peersManager: PeersManager, token: String, views: [UIView]) {
        self.url = url
        self.sessionName = sessionName
        self.participantName = participantName
        self.peersManager = peersManager
        self.localPeer = self.peersManager.localPeer
        self.iceCandidatesParams = []
        self.token = token
        self.participants = [String: RemoteParticipant]()
        self.views = views
        socket = WebSocket(url: URL(string: url)!)
        socket.disableSSLCertValidation = useSSL
        socket.delegate = self
        socket.connect()
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("Connected")
        pingMessageHandler()
        var joinRoomParams: [String: String] = [:]
        joinRoomParams["recorder"] = "false"
        joinRoomParams[JSONConstants.Metadata] = "{\"clientData\": \"" + participantName + "\"}"
        joinRoomParams["secret"] = "MY_SECRET"
        joinRoomParams["session"] = sessionName
        joinRoomParams["token"] = token
        sendJson(method: "joinRoom", params: joinRoomParams)
        if localOfferParams != nil {
            sendJson(method: "publishVideo",params: localOfferParams!)
        }
    }
    
    func pingMessageHandler() {
        helloWorldTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(WebSocketListener.doPing), userInfo: nil, repeats: true)
        doPing()
    }
    
    @objc func doPing() {
        var pingParams: [String: String] = [:]
        pingParams["interval"] = "5000"
        sendJson(method: "ping", params: pingParams)
        socket.write(ping: Data())
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("Disconnect: " + error.debugDescription)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("Recieved message: " + text)
        let data = text.data(using: .utf8)!
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any]
            {
                if json[JSONConstants.Result] != nil {
                    handleResult(json: json)
                } else {
                    handleMethod(json: json)
                }
            } else {
                print("bad json")
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    func handleResult(json: [String: Any]) {
        let result: [String: Any] = json[JSONConstants.Result] as! [String: Any]
        if result[JSONConstants.SdpAnswer] != nil {
            saveAnwer(json: result)
        } else if result[JSONConstants.SessionId] != nil {
            if result[JSONConstants.Value] != nil {
                let value = result[JSONConstants.Value]  as! [[String:Any]]
                if !value.isEmpty {
                    addParticipantsAlreadyInRoom(result: result)
                }
                self.userId = result[JSONConstants.Id] as? String
                for var iceCandidate in iceCandidatesParams! {
                    iceCandidate["endpointName"] = self.userId
                    sendJson(method: "onIceCandidate", params:  iceCandidate)
                }
            }
        } else if result[JSONConstants.Value] != nil {
            print("pong")
        } else {
            print("Unrecognized")
        }
    }
    
    func addParticipantsAlreadyInRoom(result: [String: Any]) {
        let values = result[JSONConstants.Value] as! [[String: Any]]
        for participant in values {
            print(participant[JSONConstants.Id]!)
            self.remoteParticipantId = participant[JSONConstants.Id]! as? String
            let remoteParticipant = RemoteParticipant()
            remoteParticipant.id = participant[JSONConstants.Id] as? String
            self.participants[remoteParticipant.id!] = remoteParticipant
            self.peersManager.createRemotePeerConnection(remoteParticipant: remoteParticipant)
            let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
            let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
            remoteParticipant.peerConnection!.offer(for: sdpConstraints, completionHandler: {(sessionDescription, error) in
                print("Remote Offer: " + error.debugDescription)
                self.participants[remoteParticipant.id!]!.peerConnection!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                    print("Remote Peer Local Description set " + error.debugDescription)
                })
                var remoteOfferParams: [String:String] = [:]
                remoteOfferParams["sdpOffer"] = sessionDescription!.sdp
                remoteOfferParams["sender"] = self.remoteParticipantId! + "_CAMERA"
                self.sendJson(method: "receiveVideoFrom", params: remoteOfferParams)
            })
            self.peersManager.remotePeer!.delegate = self.peersManager
        }
    }

    func saveAnwer(json: [String:Any]) {
        let sessionDescription = RTCSessionDescription(type: RTCSdpType.answer, sdp: json["sdpAnswer"] as! String)
        if localPeer == nil {
            self.localPeer = self.peersManager.localPeer
        }
        if (localPeer!.remoteDescription != nil) {
            participants[remoteParticipantId!]!.peerConnection!.setRemoteDescription(sessionDescription, completionHandler: {(error) in
                print("Remote Peer Remote Description set: " + error.debugDescription)
                if self.peersManager.remoteStreams.count >= self.participants.count {
                    DispatchQueue.main.async {
                        print("Count: " + self.participants.count.description)
                        let renderer = RTCMTLVideoView(frame: self.views[self.participants.count-1].frame)
                        let videoTrack = self.peersManager.remoteStreams[self.participants.count-1].videoTracks[0]
                        videoTrack.add(renderer)
                        self.embedView(renderer, into: self.views[self.participants.count-1])
                    }
                }
            })
        } else {
            localPeer!.setRemoteDescription(sessionDescription, completionHandler: {(error) in
                print("Local Peer Remote Description set: " + error.debugDescription)
            })
        }
    }
    
    func handleMethod(json: Dictionary<String,Any>) {
        if json[JSONConstants.Params] != nil {
            let method = json[JSONConstants.Method] as! String
            let params = json[JSONConstants.Params] as! Dictionary<String, Any>
            switch method {
                case JSONConstants.IceCandidate:
                    iceCandidateMethod(params: params)
                case JSONConstants.ParticipantJoined:
                    participantJoinedMethod(params: params)
                case JSONConstants.ParticipantPublished:
                    participantPublished(params: params)
                case JSONConstants.ParticipantLeft:
                    participantLeft(params: params)
            default:
                print("Error")
            }
        }
    }
    func iceCandidateMethod(params: Dictionary<String, Any>) {
        if (params["endpointName"] as? String == userId) {
            saveIceCandidate(json: params, endPointName: nil)
        } else {
            saveIceCandidate(json: params, endPointName: params["endpointName"] as? String)
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("Received data: " + data.description)
    }
    
    func participantJoinedMethod(params: Dictionary<String, Any>) {
        let remoteParticipant = RemoteParticipant()
        remoteParticipant.id = params[JSONConstants.Id] as? String
        participants[params[JSONConstants.Id] as! String] = remoteParticipant
        
        let metadataString = params[JSONConstants.Metadata] as! String
        let data = metadataString.data(using: .utf8)!
        do {
            if let metadata = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? Dictionary<String,Any>
            {
                self.peersManager.createRemotePeerConnection(remoteParticipant: remoteParticipant)
            } else {
                print("bad json")
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    func participantPublished(params: Dictionary<String, Any>) {
        remoteParticipantId = params[JSONConstants.Id] as? String
        print("ID: " + remoteParticipantId!)
        let remoteParticipantPublished = participants[remoteParticipantId!]!
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
        remoteParticipantPublished.peerConnection!.offer(for: RTCMediaConstraints.init(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil), completionHandler: { (sessionDescription, error) in
            remoteParticipantPublished.peerConnection!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                print("Remote Peer Local Description set")
            })
            var remoteOfferParams:  [String: String] = [:]
            remoteOfferParams["sdpOffer"] = sessionDescription!.description
            remoteOfferParams["sender"] = remoteParticipantPublished.id! + "_webcam"
            self.sendJson(method: "receiveVideoFrom", params: remoteOfferParams)
        })
        self.peersManager.remotePeer!.delegate = self.peersManager
    }
    
    func participantLeft(params: Dictionary<String, Any>) {
        let participantId = params["name"] as! String
        participants[participantId]!.peerConnection!.close()

        //REMOVE VIEW
        let renderer = RTCMTLVideoView(frame: self.views[self.participants.count-1].frame)
        let videoTrack = self.peersManager.remoteStreams[self.participants.count-1].videoTracks[0]
        videoTrack.remove(renderer)
        self.views[self.participants.count-1].willRemoveSubview(renderer)
        participants.removeValue(forKey: participantId)
    }
    
    func saveIceCandidate(json: Dictionary<String, Any>, endPointName: String?) {
        let iceCandidate = RTCIceCandidate(sdp: json["candidate"] as! String, sdpMLineIndex: json["sdpMLineIndex"] as! Int32, sdpMid: json["sdpMid"] as? String)
        if (endPointName == nil) {
            self.localPeer!.add(iceCandidate)
        } else {
            participants[endPointName!]!.peerConnection!.add(iceCandidate)
        }
    }
    
    func sendJson(method: String, params: [String: String]) {
        let json: NSMutableDictionary = NSMutableDictionary()
        json.setValue(method, forKey: JSONConstants.Method)
        json.setValue(id, forKey: JSONConstants.Id)
        id += 1
        json.setValue(params, forKey: JSONConstants.Params)
        json.setValue(JSON_RPCVERSION, forKey: JSONConstants.JsonRPC)
        let jsonData: NSData
        do {
            jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions()) as NSData
            let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            print("Sending = \(jsonString)")
            socket.write(string: jsonString)
        } catch _ {
            print ("JSON Failure")
        }
    }
    
    func addIceCandidate(iceCandidateParams: [String: String]) {
        iceCandidatesParams!.append(iceCandidateParams)
    }
    
    func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        // view.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        // containerView.layoutIfNeeded()
    }
    
}
