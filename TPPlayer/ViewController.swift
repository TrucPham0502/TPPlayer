//
//  ViewController.swift
//  TPPlayer
//
//  Created by Truc Pham on 30/09/2021.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var video: ASPVideoPlayerView!
    @IBOutlet weak var topCon: NSLayoutConstraint!
    @IBOutlet weak var trailingCon: NSLayoutConstraint!
    @IBOutlet weak var leadingCon: NSLayoutConstraint!
    weak var bottomCon: NSLayoutConstraint!
    
    let firstVideoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")
    let secondVideoURL = Bundle.main.url(forResource: "video2", withExtension: "mp4")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        video.videoURL = firstVideoURL
        video.gravity = .aspectFit
        video.shouldLoop = true
        video.startPlayingWhenReady = true

        video.backgroundColor = UIColor.black
        
        video.newVideo = {
            print("newVideo")
        }
        
        video.readyToPlayVideo = {
            print("readyToPlay")
        }
        
        video.startedVideo = {
            print("start")
            
        }
        
        video.finishedVideo = { [weak self] in
            guard let strongSelf = self else { return }
            
            print("finishedVideo")
            if strongSelf.video.videoURL == strongSelf.firstVideoURL {
                strongSelf.video.startPlayingWhenReady = true
                strongSelf.video.videoURL = strongSelf.secondVideoURL
            }
            
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
//                strongSelf.topCon.constant = 150.0
//                strongSelf.videoBottomConstraint.constant = 150.0
//                strongSelf.videoLeadingConstraint.constant = 150.0
//                strongSelf.videoTrailingConstraint.constant = 150.0
//                strongSelf.view.layoutIfNeeded()
//                }, completion: { (finished) in
//                    UIView.animate(withDuration: 0.3, delay: 1.0, options: .curveEaseIn, animations: {
//
//                        strongSelf.videoTopConstraint.constant = 0.0
//                        strongSelf.videoBottomConstraint.constant = 0.0
//                        strongSelf.videoLeadingConstraint.constant = 0.0
//                        strongSelf.videoTrailingConstraint.constant = 0.0
//
//                        strongSelf.view.layoutIfNeeded()
//                        }, completion: { (finished) in
//
//                    })
            })
        }
        
        video.playingVideo = { (progress) -> Void in
            let progressString = String.localizedStringWithFormat("%.2f", progress)
            print("progress: \(progressString) % complete.")
        }
        
        video.pausedVideo = {
            print("paused")
        }
        
        video.stoppedVideo = {
            print("stopped")
        }
        
        video.error = { (error) -> Void in
            print("Error: \(error.localizedDescription)")
        }
    }
}



