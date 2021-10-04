//
//  PlayerViewController.swift
//  TPPlayer
//
//  Created by Truc Pham on 30/09/2021.
//

import Foundation
import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    let firstLocalVideoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")
    let secondLocalVideoURL = Bundle.main.url(forResource: "video2", withExtension: "mp4")

    let firstNetworkURL = URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")
    let secondNetworkURL = URL(string: "http://www.easy-fit.ae/wp-content/uploads/2014/09/WebsiteLoop.mp4")

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
