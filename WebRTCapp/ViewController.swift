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
        let url = URL(string: "https://demos.openvidu.io:8443/api/tokens")!
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic T1BFTlZJRFVBUFA6TVlfU0VDUkVU", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let json = "{\"session\": \"SessionA\"}"
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
            let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
            var sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
            self.self.socket = WebSocketListener(url: "wss://demos.openvidu.io:8443/openvidu", sessionName: "SessionA", participantName: "Participant1", peersManager: self.peersManager!, token: token)
            self.peersManager?.webSocketListener = self.socket
            self.peersManager?.start()
            
            self.mediaStream = (self.self.peersManager?.peerConnectionFactory?.mediaStream(withStreamId: "102"))!
            self.localAudioTrack = self.peersManager?.peerConnectionFactory?.audioTrack(withTrackId: "101")
            sdpConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            self.videoSource = self.peersManager?.peerConnectionFactory?.avFoundationVideoSource(with: sdpConstraints)
            self.videoSource?.captureSession.startRunning()
            // videoSource.adaptOutputFormat(toWidth: 640, height: 480, fps: 15)
            self.captureSession = self.videoSource!.captureSession
            self.localVideoTrack = self.peersManager?.peerConnectionFactory?.videoTrack(with: self.self.videoSource!, trackId: "100")
            self.mediaStream!.addAudioTrack(self.self.localAudioTrack!)
            self.mediaStream!.addVideoTrack(self.localVideoTrack!)
            self.mediaStream!.audioTracks[0].isEnabled = true
            self.mediaStream!.videoTracks[0].isEnabled = true
            
            do{
                try self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
                try self.self.audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
                try self.audioSession.setActive(true)
            } catch let error as NSError{
                print(error.localizedDescription)
            }
            
            self.peersManager!.createLocalOffer(mediaConstraints: sdpConstraints);
            // socket = WebSocketListener(url: "wss://demos.openvidu.io:8443/openvidu", sessionName: sessionName.text as! String, participantName: participantName.text as! String)
        }
        task.resume()
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

