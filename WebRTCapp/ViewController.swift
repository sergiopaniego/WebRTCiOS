//
//  ViewController.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 12/03/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC

class ViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    var session: AVCaptureSession?
    var input: AVCaptureDeviceInput?
    var output: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var socket: WebSocketListener?
    var peersManager: PeersManager?
    var mediaStream: RTCMediaStream?
    var localAudioTrack: RTCAudioTrack?
    var localVideoTrack: RTCVideoTrack?
    var videoSource: RTCAVFoundationVideoSource?
    private var captureSession: AVCaptureSession?
    private var audioSession = AVAudioSession.sharedInstance()
    @IBOutlet weak var url: UITextField!
    @IBOutlet weak var sessionName: UITextField!
    @IBOutlet weak var participantName: UITextField!
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
        // getCameraView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startSocket(_ sender: UIButton) {
        print("HEY")
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
    
    func getCameraView() {
        var defaultVideoDevice: AVCaptureDevice?
        
        // Choose the back dual camera if available, otherwise default to a wide angle camera.
        if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
            defaultVideoDevice = dualCameraDevice
        }
            
        else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            defaultVideoDevice = backCameraDevice
        }
            
        else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            defaultVideoDevice = frontCameraDevice
        }
        // The camera won't be available on iOS simulator
        do {
            input = try AVCaptureDeviceInput(device: defaultVideoDevice!)
        } catch let error as NSError {
            print(error)
            input = nil
        }
        
        //Initialize session an output variables this is necessary
        session = AVCaptureSession()
        output = AVCapturePhotoOutput()

        session?.addInput(input!)
        session?.addOutput(output!)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        previewLayer?.frame = cameraView.bounds
        session?.startRunning()
    }
}

