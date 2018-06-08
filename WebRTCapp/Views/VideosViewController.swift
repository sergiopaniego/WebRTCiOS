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
    var videoSource: RTCVideoSource?
    private var captureSession: AVCaptureSession?
    private var audioSession = AVAudioSession.sharedInstance()
    var renderer: RTCMTLVideoView!
    private var videoCapturer: RTCVideoCapturer?
    var url: String = ""
    var sessionName: String = ""
    var participantName: String = ""
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!
    @IBOutlet weak var remoteVideoView2: UIView!
    var remoteViews: [UIView]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var someInts = [Int]()
        someInts.append(1)
        remoteViews = [UIView]()
        remoteViews?.append(remoteVideoView)
        remoteViews?.append(remoteVideoView2)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        print("BUTTTON PRESSED")
        self.socket?.sendJson(method: "leaveRoom", params: [:])
        self.socket?.socket.disconnect()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will Appear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did Appear")
        self.peersManager = PeersManager(view: self.view)
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
        let json = "{\"customSessionId\": \"SessionB\"}"
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
                    if jsonArray?["token"] != nil {
                        print("response someKey exists")
                        token = jsonArray?["token"] as! String
                    } else {
                        token = "wss://demos.openvidu.io:8443?sessionId=SessionB&token=6m6xfsbfvme5rhek"
                    }
                } catch let error as NSError {
                    print(error)
                }
                self.createSocket(token: token)
                
                DispatchQueue.main.async {
                    self.createLocalVideoView()
                    let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
                    let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
                    self.peersManager!.createLocalOffer(mediaConstraints: sdpConstraints);
                }
            }
            task.resume()
        }
        task.resume()
    }
    
    func createSocket(token: String) {
        self.socket = WebSocketListener(url: self.url, sessionName: self.sessionName, participantName: self.participantName, peersManager: self.peersManager!, token: token, views: remoteViews!)
        self.peersManager!.webSocketListener = self.socket
        self.peersManager!.start()
    }
    
    func createLocalVideoView() {
        self.renderer = RTCMTLVideoView(frame: self.localVideoView.frame)
        startCapureLocalVideo(renderer: self.renderer)
        
        self.embedView(self.renderer, into: self.localVideoView)
    }
    
    func startCapureLocalVideo(renderer: RTCVideoRenderer) {
        createMediaSenders()
        
        guard let stream = self.peersManager!.localPeer!.localStreams.first ,
            let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
                return
        }

        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
            
            // choose highest res
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }).last,
            
            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
                return
        }
        
        capturer.startCapture(with: frontCamera,
                                    format: format,
                                    fps: Int(fps.maxFrameRate))
        
        
        stream.videoTracks.first?.add(renderer)
    }
    
    private func createMediaSenders() {
        let streamId = "stream"
        let stream = self.peersManager!.peerConnectionFactory!.mediaStream(withStreamId: streamId)
        
        // Audio
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peersManager!.peerConnectionFactory!.audioSource(with: audioConstrains)
        let audioTrack = self.peersManager!.peerConnectionFactory!.audioTrack(with: audioSource, trackId: "audio0")
        self.localAudioTrack = audioTrack
        self.peersManager!.localAudioTrack = audioTrack
        stream.addAudioTrack(audioTrack)
        
        // Video
        let videoSource = self.peersManager!.peerConnectionFactory!.videoSource()
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        let videoTrack = self.peersManager!.peerConnectionFactory!.videoTrack(with: videoSource, trackId: "video0")
        self.peersManager!.localVideoTrack = videoTrack
        self.localVideoTrack = videoTrack
        stream.addVideoTrack(videoTrack)
        
        self.peersManager!.localPeer!.add(stream)
        self.peersManager!.localPeer!.delegate = self.peersManager!
    }
    
    func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let width = (UIScreen.main.bounds.width)
        let height = (UIScreen.main.bounds.height)
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[view(" + width.description + ")]",
                                                                    options: NSLayoutFormatOptions(),
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(" + height.description + ")]",
                                                                    options:NSLayoutFormatOptions(),
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
}
