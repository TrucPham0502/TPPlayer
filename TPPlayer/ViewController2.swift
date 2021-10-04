//
//  ViewController2.swift
//  TPPlayer
//
//  Created by TrucPham on 04/10/2021.
//

import Foundation
import UIKit
class ViewController2: UIViewController {
    private lazy var videoControl : VideoPlayerControls = {
        let v = VideoPlayerControls()
        v.translatesAutoresizingMaskIntoConstraints = false
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
            self.videoControl.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
}
