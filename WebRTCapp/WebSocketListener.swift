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
    var peersManager: PeersManager?
    
    init(url: String, sessionName: String, participantName: String, peersManager: PeersManager) {
        self.url = url
        self.sessionName = sessionName
        self.participantName = participantName
        self.peersManager = peersManager
        self.iceCandidatesParams = []
        participants = [String: RemoteParticipant]()
        socket = WebSocket(url: URL(string: url)!)
        socket.disableSSLCertValidation = useSSL
        socket.delegate = self
        socket.connect()
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("Connected")
        pingMessageHandler()
        var joinRoomParams: [String: String] = [:]
        joinRoomParams["dataChannels"] = "false"
        joinRoomParams[JSONConstants.Metadata] = "{\"clientData\": \"" + participantName + "\"}"
        joinRoomParams["secret"] = "MY_SECRET"
        joinRoomParams["session"] = url + sessionName
        joinRoomParams["token"] = "gr50nzaqe6avt65cg5v06"
        sendJson(method: "joinRoom", params: joinRoomParams)
        if localOfferParams != nil {
            sendJson(method: "publishVideo",params: localOfferParams!)
        }
    }
    
    func pingMessageHandler() {
        helloWorldTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(WebSocketListener.doPing), userInfo: nil, repeats: true)
    }
    
    @objc func doPing() {
        var pingParams: [String: String] = [:]
        pingParams["interval"] = "3000"
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
            let value = result[JSONConstants.Value]  as! [[String:Any]]
            if !value.isEmpty {
                addParticipantsAlreadyInRoom(result: result)
             }
            self.userId = result[JSONConstants.Id] as? String
            for var iceCandidate in iceCandidatesParams! {
                iceCandidate["endpointName"] = self.userId
                sendJson(method: "onIceCandidate",params:  iceCandidate)
            }
        } else if result[JSONConstants.Value] != nil {
            print("pong")
        } else {
            print("Unrecognized")
        }
    }
    
    func addParticipantsAlreadyInRoom(result: [String: Any]) {
        for participant in result[JSONConstants.Value] as! [[String: String]] {
            self.remoteParticipantId = participant[JSONConstants.Id]!
            let remoteParticipant = RemoteParticipant()
            remoteParticipant.id = participant[JSONConstants.Id]
            participants[remoteParticipant.id!] = remoteParticipant
            createVideoView(remoteParticipant: remoteParticipant);
            setRemoteParticipantName(name: participant[JSONConstants.Metadata]!, participant: remoteParticipant)
            self.peersManager?.createRemotePeerConnection(remoteParticipant: remoteParticipant)
            let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            remoteParticipant.peerConnection?.offer(for: sdpConstraints, completionHandler: {(sessionDescription, error) in
                remoteParticipant.peerConnection?.setLocalDescription(sessionDescription!, completionHandler: nil)
                var remoteOfferParams: [String:String] = [:]
                remoteOfferParams["sdpOffer"] = sessionDescription?.description
                remoteOfferParams["sender"] = self.remoteParticipantId! + "_CAMERA"
                self.sendJson(method: "receiverVideoFRom", params: remoteOfferParams)
            })
        }
    }
    
    func createVideoView(remoteParticipant: RemoteParticipant) {
        // Creates video view in main view
    }
    
    func setRemoteParticipantName(name: String, participant: RemoteParticipant) {
        // Sets participant name on video element
    }
    
    
    func saveAnwer(json: [String:Any]) {
        let sessionDescription = RTCSessionDescription(type: RTCSdpType.answer, sdp: json["sdpAnswer"] as! String)
        if (localPeer?.remoteDescription != nil) {
            participants[remoteParticipantId!]?.peerConnection?.setRemoteDescription(sessionDescription)
        } else {
            localPeer?.setRemoteDescription(sessionDescription)
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
        participants[JSONConstants.Id] = remoteParticipant
        createVideoView(remoteParticipant: remoteParticipant)
        var metadata = params[JSONConstants.Metadata] as! [String:String]
        setRemoteParticipantName(name: metadata["clientData"]!, participant: remoteParticipant)
        self.peersManager?.createRemotePeerConnection(remoteParticipant: remoteParticipant)
    }
    
    func participantPublished(params: Dictionary<String, Any>) {
        remoteParticipantId = params[JSONConstants.Id] as? String
        let remoteParticipantPublished: RemoteParticipant = participants[remoteParticipantId!]!
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
        let optionalConstraints = [ "DtlsSrtpKeyAgreement": "true", "RtpDataChannels" : "true", "internalSctpDataChannels" : "true"]
        remoteParticipantPublished.peerConnection?.offer(for: RTCMediaConstraints.init(mandatoryConstraints: mandatoryConstraints, optionalConstraints: optionalConstraints), completionHandler: { (sessionDescription, error) in
            remoteParticipantPublished.peerConnection?.setLocalDescription(sessionDescription!, completionHandler: nil)
            var remoteOfferParams:  [String: String] = [:]
            remoteOfferParams["sdpOffer"] = sessionDescription?.description
            remoteOfferParams["sender"] = remoteParticipantPublished.id! + "_webcam"
            self.sendJson(method: "receiveVideoFrom", params: remoteOfferParams)
        })
    }
    
    func participantLeft(params: Dictionary<String, Any>) {
        let participantId = params["name"] as! String
        participants[participantId]?.peerConnection?.close()
        //REMOVE VIEW
        participants.removeValue(forKey: participantId)
    }
    
    func saveIceCandidate(json: Dictionary<String, Any>, endPointName: String?) {
        let iceCandidate = RTCIceCandidate(sdp: json["sdpMid"] as! String, sdpMLineIndex: json["sdpMLineIndex"] as! Int32, sdpMid: json["candidate"] as? String)
        if (endPointName == nil) {
            localPeer?.add(iceCandidate)
        } else {
            participants[endPointName!]?.peerConnection?.add(iceCandidate)
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
            print("json string = \(jsonString)")
            socket.write(string: jsonString)
        } catch _ {
            print ("JSON Failure")
        }
    }
    
    func addIceCandidate(iceCandidateParams: [String: String]) {
        iceCandidatesParams?.append(iceCandidateParams)
    }
    
}
