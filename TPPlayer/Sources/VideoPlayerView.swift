//
//  VideoPlayerView.swift
//  SwiftMVVMTP
//
//  Created by Truc Pham on 07/10/2021.
//

import Foundation
import AVKit
import UIKit

public enum PlayerStatus {
    case new
    case readyToPlay
    case playing
    case paused
    case stopped
    case error
}
public enum AnimationViewInfo {
    case move(CGFloat), scale
}
class VideoPlayerView : UIView {
    private enum DraggingState{
        case up, down, idle
    }
    var lastY : CGFloat = 0
    var videoConstaints : AppConstants = .init()
    var viewInfoHeight : CGFloat = UIScreen.main.bounds.height / 2 {
        didSet {
            self.viewInfo.frame.size.height = viewInfoHeight
            self.viewInfoFrame.size.height = viewInfoHeight
        }
    }
//    var videoInfoViewConstaints : AppConstants = .init()
    private lazy var viewInfo : UIView = {
        let v = UIView()
        v.alpha = 0
        v.backgroundColor = .yellow
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
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
    private lazy var videoPlayerContainer : UIView = {
        let v = UIView()
        v.layer.addSublayer(videoPlayerLayer)
        return v
    }()
    private lazy var videoControl : VideoPlayerControls = {
        let v = VideoPlayerControls()
        v.delegate = self
        v.isHiddenControl = true
        v.clipsToBounds = true
        v.previousButtonHidden = true
        v.nextButtonHidden = true
        v.interacting = { [weak self] (isInteracting) in
            guard let strongSelf = self else { return }
            strongSelf.controlsToggleWorkItem?.cancel()
            strongSelf.controlsToggleWorkItem = DispatchWorkItem(block: {
                v.isHiddenControl = true
            })
            if isInteracting == true {
                v.isHiddenControl = false
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: strongSelf.controlsToggleWorkItem!)
            }
        }
        return v
    }()
    
    private var controlsToggleWorkItem : DispatchWorkItem?
    private(set) var status: PlayerStatus = .new
    private(set) var progress: Double = 0.0
    var shouldLoop: Bool = false
    var timeObserver: AnyObject?
    var preferredRate: Float = 1.0
    var videoURL: URL? = nil {
        didSet {
            guard let url = videoURL else {
                status = .error
                let userInfo = [NSLocalizedDescriptionKey: "Video URL is invalid."]
                let videoError = NSError(domain: "videoplayer", code: 99, userInfo: userInfo)
                videoControl.error(videoError)
                return
            }
            
            let asset = AVAsset(url: url)
            setVideoAsset(asset: asset)
        }
    }
    var videoAsset: AVAsset? = nil {
        didSet {
            guard let asset = videoAsset else {
                status = .error
                
                let userInfo = [NSLocalizedDescriptionKey: "Video asset is invalid."]
                let videoError = NSError(domain: "videoplayer", code: 99, userInfo: userInfo)
                videoControl.error(videoError)
                return
            }
            
            setVideoAsset(asset: asset)
        }
    }
    var currentTime: Double {
        if let time = player.currentItem?.currentTime() {
            return time.seconds
        }
        
        return 0.0
    }
    var videoLength: Double {
        if let duration = player.currentItem?.asset.duration {
            return duration.seconds
        }
        
        return 0.0
    }
    
    var animationViewtype : AnimationViewInfo = .move(100)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareUI()
    }
    
    var videoControlFrame : CGRect = .zero {
        didSet {
            videoControl.frame = videoControlFrame
        }
    }
    var videoPlayerLayerFrame : CGRect = .zero {
        didSet {
            videoPlayerContainer.frame = videoPlayerLayerFrame
            
        }
    }
    var viewInfoFrame : CGRect = .zero {
        didSet {
            viewInfo.frame = viewInfoFrame
        }
    }
    func setFrame(_ rect : CGRect) {
        self.frame = rect
        videoControlFrame = rect
        videoPlayerLayerFrame = videoControl.frame
        viewInfoFrame = .init(origin: .init(x: rect.origin.x, y: rect.maxY), size: .init(width: self.bounds.width, height: viewInfoHeight))
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPlayerLayer.frame = videoPlayerContainer.bounds
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let asset = object as? AVPlayerItem, let keyPath = keyPath else { return }
        
        if asset == player.currentItem && keyPath == "status" {
            if asset.status == .readyToPlay {
                if status == .new {
                    status = .readyToPlay
                }
                addTimeObserver()
                videoControl.readyToPlayVideo(videoLength, currentTime: 0)
            } else if asset.status == .failed {
                status = .error
                
                let userInfo = [NSLocalizedDescriptionKey: "Error loading video."]
                let videoError = NSError(domain: "videoplayer", code: 99, userInfo: userInfo)
                videoControl.error(videoError)
                
            }
        }
    }
    private func prepareUI(){
        self.addSubview(videoPlayerContainer)
        self.addSubview(videoControl)
        self.addSubview(viewInfo)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)
        
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapControl))
//        doubleTapGestureRecognizer.delegate = self
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGestureRecognizer)
        
        tapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        self.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        doubleTapGestureRecognizer.require(toFail: panGesture)
        
//        videoInfoViewConstaints = .init(
//            left: self.viewInfo.leadingAnchor.constraint(equalTo: self.leadingAnchor),
//            right: self.viewInfo.trailingAnchor.constraint(equalTo: self.trailingAnchor),
//            top:  self.viewInfo.topAnchor.constraint(equalTo: self.bottomAnchor),
//            height: self.viewInfo.heightAnchor.constraint(equalToConstant: 150))
        
//        NSLayoutConstraint.activate([
//            self.videoControl.topAnchor.constraint(equalTo: self.topAnchor),
//            self.videoControl.leadingAnchor.constraint(equalTo: self.leadingAnchor),
//            self.videoControl.trailingAnchor.constraint(equalTo: self.trailingAnchor),
//            self.videoControl.bottomAnchor.constraint(equalTo: self.bottomAnchor)
//        ])
//        videoInfoViewConstaints.active()
    }
    
    @objc func draggedView(_ recognizer : UIPanGestureRecognizer){
        let dy = recognizer.translation(in: recognizer.view).y
        let vel = recognizer.velocity(in: recognizer.view)
        switch recognizer.state {
        case .began:
            lastY = 0
            break
        case .changed:
            translate(with: vel, dy: dy)
        case .ended,
             .cancelled,
             .failed:
            finishDragging(with: vel)
            break
        default:
            break
        }
    }
    
    
    private func translate(with velocity: CGPoint, dy: CGFloat) {
        print("velocity: \(velocity) - dy: \(dy)")
        switch animationViewtype {
        case .scale:
            let d = min(abs(dy - self.lastY), self.viewInfoHeight)
            switch self.dragDirection(velocity) {
            case .up where self.viewInfo.frame.minY > self.videoControlFrame.maxY - self.viewInfoHeight:
                self.viewInfo.frame.origin.y = self.viewInfo.frame.origin.y - d
                
                self.videoControl.frame.size.height = self.videoControl.bounds.height - d
                
                self.viewInfo.alpha = 1
            case .down where self.viewInfo.frame.minY < self.videoControlFrame.maxY:
                
                self.viewInfo.frame.origin.y = self.viewInfo.frame.origin.y + d
                
                self.videoControl.frame.size.height = self.videoControl.bounds.height + d
                
                self.viewInfo.alpha = 1
            default:
                break
            }
            self.videoPlayerLayerFrame = self.videoControl.frame
        case .move(let topOffset):
            let maxDY = self.videoControlFrame.minY - topOffset
            let d = min(abs(dy - self.lastY), maxDY)
            switch self.dragDirection(velocity) {
            case .up where self.videoControl.frame.minY > topOffset:
                self.viewInfo.alpha = min(1,abs(dy)/maxDY)
                
                self.viewInfo.frame.origin.y = self.viewInfo.frame.minY - d
                
                self.videoControl.frame.origin.y =  self.videoControl.frame.minY - d
                
            case .down where self.videoControl.frame.minY < self.videoControlFrame.minY:
                self.viewInfo.alpha = max(0,(maxDY - abs(dy))/maxDY)
                
                self.viewInfo.frame.origin.y = self.viewInfo.frame.origin.y + d
                
                self.videoControl.frame.origin.y =  self.videoControl.frame.origin.y + d
                
            default:
                break
            }
            self.videoPlayerContainer.frame = self.videoControl.frame
        }
        
        lastY = dy
        
    }
    
    
    private func finishDragging(with velocity: CGPoint){
        switch animationViewtype {
        case .scale:
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseInOut]) {
                switch self.dragDirection(velocity) {
                case .up:
                    self.viewInfo.alpha = 1
                    self.viewInfo.frame.origin.y = self.videoControlFrame.maxY - self.viewInfoHeight
                    self.videoControl.frame.size.height = self.videoControlFrame.height - self.viewInfoHeight
                case .down:
                    self.viewInfo.alpha = 0
                    self.viewInfo.frame = self.viewInfoFrame
                    self.videoControl.frame = self.videoControlFrame
                default:
                    break
                }
                self.videoPlayerLayerFrame = self.videoControl.frame
            }
        case .move(let topOffset):
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                switch self.dragDirection(velocity) {
                case .up:
                    let d = self.videoControlFrame.minY - topOffset
                    self.viewInfo.alpha = 1
                    self.viewInfo.frame.origin.y = self.viewInfoFrame.minY - d
                    self.videoControl.frame.origin.y = self.videoControlFrame.minY - d
                case .down:
                    self.viewInfo.alpha = 0
                    self.viewInfo.frame = self.viewInfoFrame
                    self.videoControl.frame = self.videoControlFrame
                default:
                    break
                }
                self.videoPlayerContainer.frame = self.videoControl.frame
            }
        }
        
    }
    private func dragDirection(_ velocity: CGPoint) -> DraggingState{
        if velocity.y < 0 {
            return .up
        }else if velocity.y > 0{
            return .down
        }else{
            return .idle
        }
    }
    @objc func doubleTapControl(_ sender : UITapGestureRecognizer){
        videoControl.doubleTapControl(sender)
    }
    
    @objc func playVideo() {
        guard let playerItem = player.currentItem else { return }
        
        if progress >= 1.0 {
            seekToZero()
        }
        
        status = .playing
        videoControl.startedVideo(currentTime: 0.0)
        player.rate = preferredRate
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)) , name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        let currentItem = player.currentItem
        let notificationObject = notification.object as? AVPlayerItem
        
        if currentItem == notificationObject && shouldLoop == true {
            status = .playing
            seekToZero()
            player.rate = preferredRate
        } else {
            stopVideo()
        }
    }
    func stopVideo() {
        player.rate = 0.0
        seekToZero()
        status = .stopped
        videoControl.stoppedVideo()
    }
    private func seekToZero() {
        progress = 0.0
        let time = CMTime(seconds: 0.0, preferredTimescale: 1)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        videoControl.seek(to: 0.0)
    }
    func pauseVideo() {
        player.rate = 0.0
        status = .paused
        videoControl.pausedVideo()
    }
    func seek(_ second: Double) {
        guard let currentItem = player.currentItem else { return }
        if second == 0.0 {
            seekToZero()
        } else {
            let time = CMTime(seconds: second, preferredTimescale: currentItem.asset.duration.timescale)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { [weak self] (finished) in
                guard let strongSelf = self else { return }
                
                if finished == false {
                    strongSelf.videoControl.seekStarted()
                } else {
                    strongSelf.videoControl.seekEnded()
                }
            })
        }
    }
    func setConstaints(_ constaints: AppConstants){
        constaints.active()
        self.videoConstaints = constaints
    }
    func setBackground(_ image : UIImage){
        self.videoPlayerLayer.contents = image.cgImage
    }
    private func setVideoAsset(asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["duration", "tracks"])
        
        deinitObservers()
        player.replaceCurrentItem(with: playerItem)
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [], context: nil)
        videoControl.newVideo()
        status = .new
    }
    private func addTimeObserver() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil, using: { [weak self] (time) in
            guard let strongSelf = self, strongSelf.status == .playing else { return }
            
            let currentTime = time.seconds
            strongSelf.videoControl.seek(to: currentTime)
            
        }) as AnyObject?
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
    @objc private func toggleControls(_ sender : UITapGestureRecognizer){
        if !videoControl.isHiddenControl {
            videoControl.isHiddenControl = true
        }
        else {
            videoControl.isHiddenControl = false
            controlsToggleWorkItem?.cancel()
            controlsToggleWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.videoControl.isHiddenControl = true
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: controlsToggleWorkItem!)
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        deinitObservers()
    }
}
extension VideoPlayerView : VideoPlayerControlsDelegate {
    
    func videoPlayerControls(_ view: VideoPlayerControls, play button: PlayPauseButton) {
        switch button.buttonState {
        case .play:
            pauseVideo()
        case .pause:
            playVideo()
        }
        
    }
    
    func videoPlayerControls(_ view: VideoPlayerControls, seek second: Double) {
        seek(second)
    }
    
    func videoPlayerControls(next view: VideoPlayerControls) {
        print("Next")
    }
    
    func videoPlayerControls(prev view: VideoPlayerControls) {
        print("prev")
    }
    
    func videoPlayerControls(_ view: VideoPlayerControls, resize button: ResizeButton) {
        print("resize")
        switch button.buttonState {
        case .large:
            self.videoConstaints.height?.constant = UIScreen.main.bounds.height
        case .small:
            self.videoConstaints.width?.constant = 300
        }
    }
    
    
}
extension VideoPlayerView : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let ges = gestureRecognizer as? UITapGestureRecognizer, ges.numberOfTapsRequired == 2 {
            return videoControl.isRippleView(touch)
        }
        return videoControl.isHiddenControl || !videoControl.isInteracting(touch)
    }
}
