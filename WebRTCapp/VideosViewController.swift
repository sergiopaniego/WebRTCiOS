//
//  VideosViewController.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 31/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import Foundation
import UIKit
import WebRTC

class VideosViewController: UIViewController {
    
    var peersManager: PeersManager?
    var session: AVCaptureSession?
    var input: AVCaptureDeviceInput?
    var output: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var socket: WebSocketListener?
    var mediaStream: RTCMediaStream?
    var localAudioTrack: RTCAudioTrack?
    var localVideoTrack: RTCVideoTrack?
    var videoSource: RTCAVFoundationVideoSource?
    private var captureSession: AVCaptureSession?
    private var audioSession = AVAudioSession.sharedInstance()
    var renderer: RTCEAGLVideoView!
    var renderer_sub: RTCEAGLVideoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Did Load")
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will Appear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did Appear")
        self.peersManager = PeersManager()
        start()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func start() {
        let url = URL(string: "https://demos.openvidu.io:8443/api/sessions")!
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic T1BFTlZJRFVBUFA6TVlfU0VDUkVU", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let json = "{\"customSessionId\": \"SessionA\"}"
        request.httpBody = json.data(using: .utf8)
        var responseString = ""
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            responseString = String(data: data, encoding: .utf8)!
            print(responseString)
            
            let jsonData = responseString.data(using: .utf8)!
            var sessionId = ""
            do {
                let json = try JSONSerialization.jsonObject(with: jsonData, options : .allowFragments) as? Dictionary<String,Any>
                sessionId = json!["id"] as! String
            } catch let error as NSError {
                print(error)
            }
            // Get Token
            let url = URL(string: "https://demos.openvidu.io:8443/api/tokens")!
            var request = URLRequest(url: url)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.addValue("Basic T1BFTlZJRFVBUFA6TVlfU0VDUkVU", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            let json = "{\"session\": \"" + sessionId + "\"}"
            request.httpBody = json.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(String(describing: error))")
                    return
                }
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(String(describing: response))")
                }
                
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(String(describing: responseString))")
                let jsonData = responseString?.data(using: .utf8)!
                var token: String = ""
                do {
                    let jsonArray = try JSONSerialization.jsonObject(with: jsonData!, options : .allowFragments) as? Dictionary<String,Any>
                    token = jsonArray!["token"] as! String
                } catch let error as NSError {
                    print(error)
                }
                self.createSocket(token: token)
                
                DispatchQueue.main.async {
                    self.createLocalVideoView()
                }
            }
            task.resume()
        }
        task.resume()
    }
    
    func createSocket(token: String) {
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        self.self.socket = WebSocketListener(url: "wss://demos.openvidu.io:8443/openvidu", sessionName: "SessionA", participantName: "Participant1", peersManager: self.peersManager!, token: token)
        self.peersManager?.webSocketListener = self.socket
        self.peersManager?.start()
        
        self.peersManager!.createLocalOffer(mediaConstraints: sdpConstraints);
        // socket = WebSocketListener(url: "wss://demos.openvidu.io:8443/openvidu", sessionName: sessionName.text as! String, participantName: participantName.text as! String)
        
    }
    
    func createLocalVideoView() {
        self.renderer = RTCEAGLVideoView(frame: self.view.frame)
        let rect = CGRect(x: 20, y: 50, width: 90, height: 120)
        self.renderer_sub = RTCEAGLVideoView(frame: rect)
        self.view.addSubview(self.renderer)
        self.view.addSubview(self.renderer_sub)
        self.renderer.delegate = self as? RTCEAGLVideoViewDelegate
        
        var device: AVCaptureDevice! = nil
        for captureDevice in AVCaptureDevice.devices(for: AVMediaType.video) {
            if (captureDevice.position == AVCaptureDevice.Position.front) {
                device = captureDevice as AVCaptureDevice
            }
        }
        
        if (device != nil) {
            let videoSource = self.peersManager?.peerConnectionFactory?.videoSource()
            let localVideoTrack = self.peersManager?.peerConnectionFactory?.videoTrack(with: videoSource!, trackId: "100")
            let audioSource = self.peersManager?.peerConnectionFactory?.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
            let localAudioTrack = self.peersManager?.peerConnectionFactory?.audioTrack(with: audioSource!, trackId: "101")
            
            let mediaStream: RTCMediaStream = (self.peersManager?.peerConnectionFactory?.mediaStream(withStreamId: "105"))!
            mediaStream.addVideoTrack(localVideoTrack!)
            mediaStream.addAudioTrack(localAudioTrack!)
            
            localVideoTrack!.add(self.renderer_sub)
        }
    }
}
