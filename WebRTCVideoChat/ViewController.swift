//
//  ViewController.swift
//  WebRTCVideoChat
//
//  Created by Kyle Redfearn on 8/22/17.
//  Copyright © 2017 Kyle Redfearn. All rights reserved.
//

import UIKit

class ViewController: UIViewController, WebRTCClientDelegate {

    @IBOutlet weak var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        WebRTCClient.shared.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func connectTapped(_ sender: Any) {
        WebRTCClient.shared.startConnection()
    }

    func webRTCClientReady() {
        self.connectButton.isEnabled = true
    }
    
}

