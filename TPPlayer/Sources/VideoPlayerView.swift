//
//  VideoPlayerView.swift
//  SwiftMVVMTP
//
//  Created by Truc Pham on 07/10/2021.
//

import Foundation
import AVKit
import UIKit
typealias VideoPlayerType = VideoPlayerDataSource & UIView
protocol VideoPlayerDataSource {
    var delegate : VideoPlayerDelegate? {get set}
    var currentTime: Double { get }
    var videoLength : Double { get }
    var autoPlay : Bool { get }
    var shouldLoop: Bool { get }
    func setVideo(url : String)
    func setVideo(url : URL)
    func playVideo()
    func stopVideo()
    func pauseVideo()
    func seek(to second: Double)
    func setRate(_ rate : Float)
}
extension VideoPlayerDataSource {
    var autoPlay : Bool {
        return false
    }
}


protocol VideoPlayerDelegate : AnyObject {
    func readyToPlayVideo(_ videoLength: Double, currentTime: Double)
    func error(_ error : Error)
    func playing(_ time : Double)
    func seekStarted()
    func seekEnded()
    func didFinishPlaying(_ shouldLoop: Bool)
}
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
public enum PlayerRotation {
    case none
    case left
    case right
    case upsideDown
    
    func radians() -> CGFloat {
        switch self {
        case .none:
            return 0.0
        case .left:
            return .pi / 2.0
        case .right:
            return -.pi / 2.0
        case .upsideDown:
            return .pi
        }
    }
}
class VideoPlayerView : UIView {
    private enum DraggingState{
        case up, down, idle
    }
    var lastY : CGFloat = 0
    var viewInfoHeight : CGFloat = UIScreen.main.bounds.height / 2 {
        didSet {
            self.viewInfo.frame.size.height = viewInfoHeight
        }
    }
    private lazy var viewInfo : UIView = {
        let v = UIView()
        v.alpha = 0
        v.backgroundColor = .yellow
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var _player : VideoPlayerType!
    private lazy var videoPlayerLayer : VideoPlayerType = {
        guard var _player = _player else { fatalError("can't get video player") }
        _player.delegate = self
        return _player
    }()
    
    private lazy var videoPlayerContainer : UIScrollView = {
        let v = UIScrollView()
        v.delegate = self
        if #available(iOS 11.0, *) {
            v.contentInsetAdjustmentBehavior = .never
        }
        v.minimumZoomScale = 1
        v.maximumZoomScale = 10
        v.showsHorizontalScrollIndicator = false
        v.showsVerticalScrollIndicator = false
        v.backgroundColor = .black
        v.addSubview(videoPlayerLayer)
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
            setVideoURL(url: url)
        }
    }
    var videoUrlString: String? = nil {
        didSet {
            guard let url = videoUrlString else {
                status = .error
                let userInfo = [NSLocalizedDescriptionKey: "Video URL is invalid."]
                let videoError = NSError(domain: "videoplayer", code: 99, userInfo: userInfo)
                videoControl.error(videoError)
                return
            }
            setVideoURL(url: url)
        }
    }
    
    var currentTime: Double {
        videoPlayerLayer.currentTime
    }
    var videoLength: Double {
        videoPlayerLayer.videoLength
    }
    
    var animationViewtype : AnimationViewInfo = .move(100)
    
    init(player : VideoPlayerType = AppAVPlayer(), frame : CGRect = .zero) {
        self._player = player
        self.defaulFrame = frame
        super.init(frame: frame)
        prepareUI()
    }
    
    private override init(frame: CGRect) {
        self._player = AppAVPlayer()
        self.defaulFrame = frame
        super.init(frame: frame)
        prepareUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareUI()
    }
    
    private var defaulControltFrame : CGRect = .zero
    private var defaulFrame : CGRect = .zero
    private var smallRect : CGRect = .zero
    
    func setControlFrame(_ rect : CGRect) {
        self.smallRect = rect
        self.updateFrame(rect)
    }
    
    func setFrame(frame : CGRect){
        self.defaulFrame = frame
        self.frame = frame
    }
    
    private func updateFrame(_ rect : CGRect){
        defaulControltFrame = rect
        videoControl.frame = rect
        videoPlayerContainer.frame = videoControl.frame
        resetLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPlayerLayer.frame = videoPlayerContainer.bounds
    }
    
    private func prepareUI(){
        self.addSubview(videoPlayerContainer)
        self.addSubview(videoControl)
        self.addSubview(viewInfo)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(tapGestureRecognizer)
        
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapControl))
        //        doubleTapGestureRecognizer.delegate = self
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTapGestureRecognizer)
        tapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
            videoPlayerContainer.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        
        
        doubleTapGestureRecognizer.require(toFail: panGesture)
        
        
        
    }
    
    
    
    
    
    @objc func draggedView(_ recognizer : UIPanGestureRecognizer){
        guard videoPlayerContainer.zoomScale == videoPlayerContainer.minimumZoomScale, !videoControl.isTrackingSlider else { return }
        let dy = recognizer.translation(in: recognizer.view).y
        let vel = recognizer.velocity(in: recognizer.view)
        switch recognizer.state {
        case .began:
            lastY = 0
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
            case .up where self.viewInfo.frame.minY > self.defaulControltFrame.maxY - self.viewInfoHeight:
                self.viewInfo.frame.origin.y = self.viewInfo.frame.origin.y - d
                
                self.videoControl.frame.size.height = self.videoControl.bounds.height - d
                
                self.viewInfo.alpha = 1
            case .down where self.viewInfo.frame.minY < self.defaulControltFrame.maxY:
                
                self.viewInfo.frame.origin.y = self.viewInfo.frame.origin.y + d
                
                self.videoControl.frame.size.height = self.videoControl.bounds.height + d
                
                self.viewInfo.alpha = 1
            default:
                break
            }
            self.videoPlayerContainer.frame = self.videoControl.frame
        case .move(let topOffset):
            let maxDY = self.defaulControltFrame.minY - topOffset
            let d = min(abs(dy - self.lastY), maxDY)
            switch self.dragDirection(velocity) {
            case .up where self.videoControl.frame.minY > topOffset:
                self.viewInfo.alpha = min(1,self.viewInfo.alpha + (d/maxDY))
                
                self.viewInfo.frame.origin.y = self.viewInfo.frame.minY - d
                
                self.videoControl.frame.origin.y =  self.videoControl.frame.minY - d
                
            case .down where self.videoControl.frame.minY < self.defaulControltFrame.minY:
                self.viewInfo.alpha = max(0,self.viewInfo.alpha - (d/maxDY))
                
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
                    self.viewInfo.frame.origin.y = self.defaulControltFrame.maxY - self.viewInfoHeight
                    self.videoControl.frame.size.height = self.defaulControltFrame.height - self.viewInfoHeight
                case .down:
                    self.resetLayout()
                default:
                    break
                }
                self.videoPlayerContainer.frame = self.videoControl.frame
            } completion: { _ in
                self.videoPlayerContainer.minimumZoomScale = 1
                self.videoPlayerContainer.zoomScale = 1
            }
        case .move(let topOffset):
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                switch self.dragDirection(velocity) {
                case .up:
                    let d = self.defaulControltFrame.minY - topOffset
                    self.viewInfo.alpha = 1
                    self.videoControl.frame.origin.y = self.defaulControltFrame.minY - d
                    self.viewInfo.frame.origin.y = self.defaulControltFrame.maxY - d
                    
                case .down:
                    self.resetLayout()
                default:
                    break
                }
                self.videoPlayerContainer.frame = self.videoControl.frame
            } completion: { _ in
                self.videoPlayerContainer.minimumZoomScale = 1
                self.videoPlayerContainer.zoomScale = 1
            }
        }
        
    }
    private func resetLayout(){
        self.viewInfo.alpha = 0
        self.viewInfo.frame  = .init(origin: .init(x: defaulControltFrame.origin.x, y: defaulControltFrame.maxY), size: .init(width: defaulControltFrame.width, height: viewInfoHeight))
        self.videoControl.frame = self.defaulControltFrame
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
    
    func playVideo() {
        if progress >= 1.0 {
            seekToZero()
        }
        videoPlayerLayer.playVideo()
    }
    
    func stopVideo() {
        videoPlayerLayer.stopVideo()
        seekToZero()
        status = .stopped
        videoControl.stoppedVideo()
    }
    private func seekToZero() {
        progress = 0.0
        videoPlayerLayer.seek(to: 0.0)
        videoControl.seek(to: 0.0)
    }
    func pauseVideo() {
        videoPlayerLayer.pauseVideo()
        status = .paused
        videoControl.pausedVideo()
    }
    func seek(_ second: Double) {
        if second == 0.0 {
            seekToZero()
        } else {
            videoPlayerLayer.seek(to: second)
        }
    }
    
    private func setVideoURL(url: URL) {
        videoPlayerLayer.setVideo(url: url)
        videoControl.newVideo()
        status = .new
    }
    private func setVideoURL(url: String) {
        videoPlayerLayer.setVideo(url: url)
        videoControl.newVideo()
        status = .new
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
        self.videoPlayerContainer.minimumZoomScale = 1
        self.videoPlayerContainer.zoomScale = 1
        UIView.animate(withDuration: 0.3) {
            self.resetLayout()
            switch button.buttonState {
            case .large:
                self.transform = CGAffineTransform(rotationAngle: PlayerRotation.left.radians())
                self.frame = .init(origin: .zero, size: .init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
                self.updateFrame(self.bounds)
                self.animationViewtype = .scale
                self.viewInfoHeight = UIScreen.main.bounds.width / 2
            case .small:
                self.transform = CGAffineTransform(rotationAngle: PlayerRotation.none.radians())
                self.frame = self.defaulFrame
                self.updateFrame(self.smallRect)
                self.animationViewtype = .move(100)
                self.viewInfoHeight = UIScreen.main.bounds.height / 2
                
            }
        }
        
    }
    
    func videoPlayerControls(_ view: VideoPlayerControls, rate button: UIButton) {
        videoPlayerLayer.setRate(2.0)
    }
    
}
extension VideoPlayerView : VideoPlayerDelegate {
    func readyToPlayVideo(_ videoLength: Double, currentTime: Double) {
        if status == .new {
            status = .readyToPlay
        }
        videoControl.readyToPlayVideo(videoLength, currentTime: 0)
        if videoPlayerLayer.autoPlay {
            self.playVideo()
        }
    }
    
    func error(_ error: Error) {
        status = .error
        videoControl.error(error)
    }
    
    func playing(_ time: Double) {
        self.videoControl.seek(to: time)
    }
    
    func seekStarted() {
        self.videoControl.seekStarted()
    }
    
    func seekEnded() {
        self.videoControl.seekEnded()
    }
    
    func didFinishPlaying(_ shouldLoop: Bool) {
        if shouldLoop == true {
            status = .playing
            seekToZero()
        } else {
            stopVideo()
        }
    }
    
    
}

extension VideoPlayerView : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            if videoPlayerContainer.zoomScale == videoPlayerContainer.minimumZoomScale {
                let velocity = panGesture.velocity(in: panGesture.view)
                return abs(velocity.y) >= abs(velocity.x)
            }
            return false
        }
        
        if let ges = gestureRecognizer as? UITapGestureRecognizer, ges.numberOfTapsRequired == 2 {
            return videoControl.isRippleView(touch)
        }
        
        return (videoControl.isHiddenControl || !videoControl.isInteracting(touch.location(in: self.videoControl))) && self.videoPlayerContainer.frame.contains(touch.location(in: self))
    }
}
extension VideoPlayerView : UIScrollViewDelegate {

    private func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - videoPlayerLayer.frame.height) / 2)
        let xOffset = max(0, (size.width - videoPlayerLayer.frame.width) / 2)
        videoPlayerLayer.frame.origin = CGPoint(x: xOffset, y: yOffset)
        self.layoutIfNeeded()
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return videoPlayerLayer
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(size: self.videoPlayerLayer.bounds.size)
    }
}

