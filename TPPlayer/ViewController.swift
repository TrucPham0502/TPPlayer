//
//  ViewController.swift
//  TPPlayer
//
//  Created by Truc Pham on 30/09/2021.
//

import UIKit
import AVKit
class ViewController: UIViewController {
    
    private lazy var videoControl : VideoPlayerControls = {
        let v = VideoPlayerControls()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.newVideo()
        v.readyToPlayVideo(1000, currentTime: 0)
        return v
    }()
    
    let firstVideoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")
    let secondVideoURL = Bundle.main.url(forResource: "video2", withExtension: "mp4")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(videoControl)
        self.view.backgroundColor = .darkGray
        NSLayoutConstraint.activate([
            self.videoControl.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.videoControl.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.videoControl.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.videoControl.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
    }
}
extension UIView {
    func getConstraint(_ attributes: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        return constraints.filter {
            if $0.firstAttribute == attributes && $0.secondItem == nil {
                return true
            }
            return false
        }.first
    }
}

struct DeviceInfo {
    struct Orientation {
        // indicate current device is in the LandScape orientation
        static var isLandscape: Bool {
            get {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation.isLandscape
                    : UIApplication.shared.statusBarOrientation.isLandscape
            }
        }
        // indicate current device is in the Portrait orientation
        static var isPortrait: Bool {
            get {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation.isPortrait
                    : UIApplication.shared.statusBarOrientation.isPortrait
            }
        }
    }
}
