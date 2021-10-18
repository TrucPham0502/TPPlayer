//
//  AppAVPlayer.swift
//  Player
//
//  Created by TrucPham on 15/10/2021.
//

import Foundation
import UIKit
import AVKit


class AppAVPlayer : VideoPlayerType {
   
    weak var delegate : VideoPlayerDelegate?
    var timeObserver: AnyObject?
    var preferredRate: Float = 1.0
    var shouldLoop: Bool = false
    func setVideo(url : String) {
        guard let _url = URL(string: url) else {
            let userInfo = [NSLocalizedDescriptionKey: "url not found."]
            let videoError = NSError(domain: "videoplayer", code: 99, userInfo: userInfo)
            delegate?.error(videoError)
            return
        }
        setVideo(url: _url)
    }
    func setVideo(url : URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["duration", "tracks"])
        
        deinitObservers()
        player.replaceCurrentItem(with: playerItem)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)
    }
    func playVideo() {
        guard let playerItem = player.currentItem else { return }
        player.rate = preferredRate
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)) , name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    func stopVideo() {
        player.rate = 0.0
    }
    
    func pauseVideo(){
        player.rate = 0.0
    }
    
    func seek(to second: Double) {
        guard let currentItem = player.currentItem else { return }
        let time = CMTime(seconds: second, preferredTimescale: currentItem.asset.duration.timescale)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { [weak self] (finished) in
            guard let strongSelf = self else { return }
            if finished == false {
                strongSelf.delegate?.seekStarted()
            } else {
                strongSelf.delegate?.seekEnded()
            }
        })
    }
    func setRate(_ rate : Float) {
        self.preferredRate = rate
        player.rate = rate
    }
    var videoLength: Double {
        if let duration = player.currentItem?.asset.duration {
            return duration.seconds
        }
        return 0.0
    }
    
    var currentTime: Double {
        if let time = player.currentItem?.currentTime() {
            return time.seconds
        }
        return 0.0
    }
    
    private lazy var videoPlayerLayer : AVPlayerLayer = {
        let v = AVPlayerLayer()
        v.videoGravity = AVLayerVideoGravity.resizeAspect
        v.player = player
        v.contentsScale = UIScreen.main.scale
        return v
    }()
    private lazy var player : AVPlayer = {
        let v = AVPlayer()
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepareUI(){
        self.layer.addSublayer(videoPlayerLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.videoPlayerLayer.frame = self.bounds
    }
    
    private func deinitObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        if let video = player.currentItem, video.observationInfo != nil {
            video.removeObserver(self, forKeyPath: "status")
        }
        
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let asset = object as? AVPlayerItem, let keyPath = keyPath else { return }
        
        if asset == player.currentItem && keyPath == "status" {
            if asset.status == .readyToPlay {
                addTimeObserver()
                delegate?.readyToPlayVideo(videoLength, currentTime: 0)
            } else if asset.status == .failed {
                let userInfo = [NSLocalizedDescriptionKey: "Error loading video."]
                let videoError = NSError(domain: "videoplayer", code: 99, userInfo: userInfo)
                delegate?.error(videoError)
                
            }
        }
    }
    private func addTimeObserver() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            let currentTime = time.seconds
            strongSelf.delegate?.playing(currentTime)
            
        }) as AnyObject?
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        let currentItem = player.currentItem
        let notificationObject = notification.object as? AVPlayerItem
        self.delegate?.didFinishPlaying(currentItem == notificationObject && shouldLoop == true)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        deinitObservers()
    }
}

