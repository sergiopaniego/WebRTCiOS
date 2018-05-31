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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startSocket(_ sender: UIButton) {
        print("Start new View!")
    }
}

