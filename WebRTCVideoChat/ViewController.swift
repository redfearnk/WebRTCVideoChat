//
//  ViewController.swift
//  WebRTCVideoChat
//
//  Created by Kyle Redfearn on 8/22/17.
//  Copyright © 2017 Kyle Redfearn. All rights reserved.
//

import UIKit
import WebRTC

class ViewController: UIViewController, WebRTCClientDelegate {

    @IBOutlet weak var connectButton: UIButton!
    weak var remoteView: RTCEAGLVideoView?
    weak var localView: RTCEAGLVideoView?
    
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
    
    func webRTCClientDidAddRemote(videoTrack: RTCVideoTrack) {
        DispatchQueue.main.async {
            self.connectButton.isHidden = true
            if self.remoteView == nil {
                let videoView = RTCEAGLVideoView(frame: self.view.bounds)
                if let local = self.localView {
                    self.view.insertSubview(videoView, belowSubview: local)
                } else {
                    self.view.addSubview(videoView)
                }
                self.remoteView = videoView
            }
            videoTrack.add(self.remoteView!)
        }
    }
    
    func webRTCClientDidAddLocal(videoTrack: RTCVideoTrack) {
        DispatchQueue.main.async {
            self.connectButton.isHidden = true
            if self.localView == nil {
                let videoView = RTCEAGLVideoView(frame: CGRect(x: 0, y: 0, width:100, height: 100))
                self.view.addSubview(videoView)
                self.localView = videoView
            }
            videoTrack.add(self.localView!)
        }
    }
    
    func didRecieve(image: UIImage) {
//        if let view = self.openGLView {
////            vie
//        }
    }
}

