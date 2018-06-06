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

    @IBOutlet weak var url: UITextField!
    @IBOutlet weak var sessionName: UITextField!
    @IBOutlet weak var participantName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Recognise gesture to hide keyboard
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        //Camera
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                print("Camera permission granted!")
            } else {
                
            }
        }
        print("Did Load")
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will Appear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Did Appear")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is VideosViewController
        {
            let vc = segue.destination as? VideosViewController
            vc?.url = url.text!
            vc?.sessionName = sessionName.text!
            vc?.participantName = participantName.text!
        }
    }

    @IBAction func startSocket(_ sender: UIButton) {
        print("Start new View!")
    }
}

