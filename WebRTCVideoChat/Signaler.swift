//
//  Signaler.swift
//  WebRTCVideoChat
//
//  Created by Kyle Redfearn on 8/23/17.
//  Copyright © 2017 Kyle Redfearn. All rights reserved.
//

import UIKit
import PubNub

enum SingalingKey: String {
    case type = "type"
    case sdp = "sdp"
    case sdpMid = "sdpMid"
    case sdpMLineIndex = "sdpMLineIndex"
}

enum SignalingType: String {
    case offer = "offer"
    case answer = "answer"
    case ice = "ice"
}

protocol SignalingDelegate: class {
    func didReceiveOffer(_ sdp: String)
    func didRecieveAnswer(_ sdp: String)
    func didRecieveICECandidate(sdp: String, sdpMLineIndex: Int32, sdpMid: String?)
    func signalerReady()
}

class Signaler: NSObject, PNObjectEventListener {
    static let shared = Signaler()
    
    var pubnub: PubNub?
    weak var delegate: SignalingDelegate?
    let channel = "Channel-1w7tkamaw"
    let publishKey = "pub-c-ef5d6fcd-3c21-4385-b02f-baee7b92349d"
    let subscribeKey = "sub-c-e7757fca-87b5-11e7-abf7-cae3e7536ffb"
    
    override init() {
        super.init()
        let config = PNConfiguration(publishKey: publishKey, subscribeKey: subscribeKey)
        self.pubnub = PubNub.clientWithConfiguration(config)
        self.pubnub?.addListener(self)
        self.pubnub?.subscribeToChannels([channel], withPresence: false)
    }
    
    func sendOffer(_ sdp: String) {
        let message = [SingalingKey.type.rawValue: SignalingType.offer.rawValue,
                       SingalingKey.sdp.rawValue:sdp]
        self.pubnub?.publish(message, toChannel: self.channel, withCompletion: { (status) in
            print("Offer sent with status: \(status.data.information)")
        })
    }
    
    func sendAnswer(_ sdp: String) {
        let message = [SingalingKey.type.rawValue: SignalingType.answer.rawValue,
                       SingalingKey.sdp.rawValue:sdp]
        self.pubnub?.publish(message, toChannel: self.channel, withCompletion: { (status) in
            print("Answer sent with status: \(status.data.information)")
        })
    }
    
    func sendICECandidate(sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        var message: [String : Any] = [SingalingKey.type.rawValue: SignalingType.ice.rawValue,
                                       SingalingKey.sdp.rawValue: sdp,
                                       SingalingKey.sdpMLineIndex.rawValue: sdpMLineIndex]
        if let sdpMid = sdpMid {
            message[SingalingKey.sdpMid.rawValue] = sdpMid
        }
        self.pubnub?.publish(message, toChannel: self.channel, withCompletion: { (status) in
            print("ICE candidate sent with status: \(status.data.information)")
        })
    }
    
    func client(_ client: PubNub, didReceive status: PNStatus) {
        print("PubNub Status: \(status.category.rawValue)")
        if status.category == .PNConnectedCategory {
            self.delegate?.signalerReady()
        }
    }
    
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        print("PubNub: \(message.data.message!)")
        if let dict = message.data.message as? [String : Any] {
            if let type = dict[SingalingKey.type.rawValue] as? String {
                if type == SignalingType.offer.rawValue {
                    if let sdp = dict[SingalingKey.sdp.rawValue] as? String {
                        self.delegate?.didReceiveOffer(sdp)
                    }
                } else if type == SignalingType.answer.rawValue {
                    if let sdp = dict[SingalingKey.sdp.rawValue] as? String {
                        self.delegate?.didRecieveAnswer(sdp)
                    }
                } else if type == SignalingType.ice.rawValue {
                    if let sdp = dict[SingalingKey.sdp.rawValue] as? String,
                        let sdpMLineIndex = dict[SingalingKey.sdpMLineIndex.rawValue] as? Int32 {
                        var sdpMidOptional: String? = nil
                        if let sdpMid = dict[SingalingKey.sdpMid.rawValue] as? String {
                            sdpMidOptional = sdpMid
                        }
                        self.delegate?.didRecieveICECandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMidOptional)
                    }
                }
            }
        }
    }
    
    func client(_ client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        print("PubNub Event: \(event)")
    }
    
    
}
