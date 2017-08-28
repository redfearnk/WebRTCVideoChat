//
//  WebRTCClient.swift
//  WebRTCVideoChat
//
//  Created by Kyle Redfearn on 8/23/17.
//  Copyright © 2017 Kyle Redfearn. All rights reserved.
//

import UIKit
import WebRTC

protocol WebRTCClientDelegate: class {
    func webRTCClientReady()
}

class WebRTCClient: NSObject, SignalingDelegate, RTCPeerConnectionDelegate {
    static let shared = WebRTCClient()
    weak var delegate: WebRTCClientDelegate?
    
    let factory = RTCPeerConnectionFactory()
    var peerConnection: RTCPeerConnection!
    let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue, kRTCMediaConstraintsOfferToReceiveVideo : kRTCMediaConstraintsValueTrue])
    let stunServer = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
    
    var outboundStream: RTCMediaStream!
    var inboundStream: RTCMediaStream?
    
    override init() {
        super.init()
        Signaler.shared.delegate = self
    }
    
    func startConnection() {
        self.createPeerConnectionIfNeeded()
        self.peerConnection.offer(for: self.constraints) { (desc, error) in
            if let desc = desc {
                print("Offer created")
                self.peerConnection.setLocalDescription(desc, completionHandler: { (error) in
                    if error != nil {
                        print("Local Description Set")
                        Signaler.shared.sendOffer(desc.sdp)
                    }
                })
            }
        }
    }
    
    func createPeerConnectionIfNeeded() {
        if self.peerConnection == nil {
            let config = RTCConfiguration()
            config.iceServers = [stunServer]
            self.peerConnection = self.factory.peerConnection(with: config, constraints: self.constraints, delegate: self)
            
            self.outboundStream = self.factory.mediaStream(withStreamId: "stream")
            let videoSource = self.factory.videoSource()
            let videoTrack = self.factory.videoTrack(with: videoSource, trackId: "video")
            self.outboundStream.addVideoTrack(videoTrack)
            let audioSource = self.factory.audioSource(with: self.constraints)
            let audioTrack = self.factory.audioTrack(with: audioSource, trackId: "audio")
            self.outboundStream.addAudioTrack(audioTrack)
        }
    }
    
    func didReceiveOffer(_ sdp: String) {
        self.createPeerConnectionIfNeeded()
        let desc = RTCSessionDescription(type: .offer, sdp: sdp)
        weak var weakPeer = self.peerConnection
        self.peerConnection.setRemoteDescription(desc) { (error) in
            if error != nil {
                print("Remote Description Set")
                weakPeer?.answer(for: self.constraints, completionHandler: { (desc, error) in
                    if let desc = desc {
                        print("Answer created")
                        weakPeer?.setLocalDescription(desc, completionHandler: { (error) in
                            print("Local Description Set")
                            Signaler.shared.sendAnswer(desc.sdp)
                        })
                    }
                })
            }
        }
    }
    
    func didRecieveAnswer(_ sdp: String) {
        let desc = RTCSessionDescription(type: .offer, sdp: sdp)
        self.peerConnection.setRemoteDescription(desc) { (error) in
            if error != nil {
                print("Remote Description Set")
            }
        }
    }
    
    func didRecieveICECandidate(sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        self.createPeerConnectionIfNeeded()
        let iceCandidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
        self.peerConnection.add(iceCandidate)
        print("Added ICE candidate")
    }
    
    func signalerReady() {
        self.delegate?.webRTCClientReady()
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("peerConnectionShouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        self.inboundStream = stream
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        Signaler.shared.sendICECandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("RTCIceGatheringState: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("RTCIceConnectionState: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("RTCSignalingState: \(stateChanged.rawValue)")
    }
}
