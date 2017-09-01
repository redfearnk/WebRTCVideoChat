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
    func didRecieve(image: UIImage)
    func signalerReady()
}

class Signaler: NSObject, PNObjectEventListener {
    static let shared = Signaler()
    
    var pubnub: PubNub?
    weak var delegate: SignalingDelegate?
    let channel = "439"
    let publishKey = "<insert key here>"
    let subscribeKey = "<insert key here>"
    var uuid: String?
    var number: String?
    
    override init() {
        super.init()
        let config = PNConfiguration(publishKey: publishKey, subscribeKey: subscribeKey)
        self.pubnub = PubNub.clientWithConfiguration(config)
        self.pubnub?.addListener(self)
        self.pubnub?.subscribeToChannels([channel], withPresence: false)
    }
    
    func sendOffer(_ sdp: String) {
        let id = UUID().uuidString.lowercased()
        let num = "321"
        self.number = num
        self.uuid = id
        let message: [String : Any] = ["id": id,
                                       "number": num,
                                       "packet": [SingalingKey.type.rawValue: SignalingType.offer.rawValue,
                                                  SingalingKey.sdp.rawValue:sdp]]
        self.pubnub?.publish(message, toChannel: self.channel, withCompletion: { (status) in
            print("Offer sent with status: \(status.data.information)")
        })
    }
    
    func sendAnswer(_ sdp: String) {
        if let id = self.uuid, let num = self.number {
            let message: [String : Any] = ["id": id,
                                           "number": num,
                                           "packet": [SingalingKey.type.rawValue: SignalingType.answer.rawValue,
                                                      SingalingKey.sdp.rawValue:sdp]]
            self.pubnub?.publish(message, toChannel: self.channel, withCompletion: { (status) in
                print("Answer sent with status: \(status.data.information)")
            })
        }
    }
    
    func sendICECandidate(sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        if let id = self.uuid, let num = self.number {
            var message: [String : Any] = ["id": id,
                                           "number": num,
                                           "packet": ["candidate": sdp,
                                                      SingalingKey.sdpMLineIndex.rawValue: sdpMLineIndex]]
            
            if let sdpMid = sdpMid {
                if var package = message["packet"] as? [String : Any] {
                    package[SingalingKey.sdpMid.rawValue] = sdpMid
                    message["packet"] = package
                }
            }
            self.pubnub?.publish(message, toChannel: self.channel, withCompletion: { (status) in
                print("ICE candidate sent with status: \(status.data.information)")
            })
        }
    }
    
    func client(_ client: PubNub, didReceive status: PNStatus) {
        print("PubNub Status: \(status.category.rawValue)")
        if status.category == .PNConnectedCategory {
            self.delegate?.signalerReady()
        }
    }
    
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        if client.currentConfiguration().uuid != message.data.publisher {
//            print("PubNub: \(message.data.message!)")
            if let dict = message.data.message as? [String : Any] {
                if let packet = dict["packet"] as? [String : Any] {
                    if let type = packet[SingalingKey.type.rawValue] as? String {
                        if type == SignalingType.offer.rawValue {
                            if let sdp = packet[SingalingKey.sdp.rawValue] as? String {
                                self.delegate?.didReceiveOffer(sdp)
                            }
                            if let id = dict["id"] as? String {
                                self.uuid = id
                            }
                            if let num = dict["number"] as? String {
                                self.number = num
                            }
                        } else if type == SignalingType.answer.rawValue {
                            if let sdp = packet[SingalingKey.sdp.rawValue] as? String {
                                self.delegate?.didRecieveAnswer(sdp)
                            }
                        } else if type == SignalingType.ice.rawValue {
                            if let sdp = packet[SingalingKey.sdp.rawValue] as? String,
                                let sdpMLineIndex = packet[SingalingKey.sdpMLineIndex.rawValue] as? Int32 {
                                var sdpMidOptional: String? = nil
                                if let sdpMid = packet[SingalingKey.sdpMid.rawValue] as? String {
                                    sdpMidOptional = sdpMid
                                }
                                self.delegate?.didRecieveICECandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMidOptional)
                            }
                        }
                    }
                    if let candidate = packet["candidate"] as? String,
                       let sdpMLineIndex = packet[SingalingKey.sdpMLineIndex.rawValue] as? Int32 {
                        var sdpMidOptional: String? = nil
                        if let sdpMid = packet[SingalingKey.sdpMid.rawValue] as? String {
                            sdpMidOptional = sdpMid
                        }
                        self.delegate?.didRecieveICECandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMidOptional)
                    }
                    if let thumbnail = packet["thumbnail"] as? String {
                        if let url = URL(string: thumbnail) {
                            let data = try! Data(contentsOf: url)
                            if let image = UIImage(data: data) {
                                self.delegate?.didRecieve(image: image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func client(_ client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        print("PubNub Event: \(event)")
    }
    
    
}
