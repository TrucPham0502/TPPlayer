//
//  VideoPlayerControls.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit
import AVFoundation
protocol VideoPlayerControlsDelegate : AnyObject {
    func videoPlayerControls(_ view : VideoPlayerControls, play button : PlayPauseButton)
    func videoPlayerControls(_ view : VideoPlayerControls, seek second : Double)
    func videoPlayerControls(next view : VideoPlayerControls)
    func videoPlayerControls(prev view : VideoPlayerControls)
    func videoPlayerControls(_ view : VideoPlayerControls, resize button : ResizeButton)
    func videoPlayerControls(_ view : VideoPlayerControls, rate button : UIButton)
}



class VideoPlayerControls : UIView {
    // MARK: Properties
    private lazy var rippleRewind : CircleRippleView = {
        let v =  CircleRippleView()
        v.alpha = 0
        v.tag = -1
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        v.position = .left
        v.backgroundColor = .black.withAlphaComponent(0.1)
        return v
    }()
    private lazy var rippleFastForward : CircleRippleView = {
        let v =  CircleRippleView()
        v.alpha = 0
        v.tag = -1
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        v.backgroundColor = .black.withAlphaComponent(0.1)
        v.position = .right
        return v
    }()
    
    private lazy var playPauseButton : PlayPauseButton = {
        let v = PlayPauseButton()
        v.tag = 2
        v.backgroundColor = .clear
        v.tap = { button in
            self.playButtonPressed()
        }
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var  progressSlider : Scrubber = {
        let v = Scrubber()
        v.trackHeight = 2
        v.trackColor = UIColor.white.cgColor
        v.thumbColor = UIColor.white.cgColor
        v.trackFillColor = UIColor.orange.cgColor
        v.thumbScale = 1.5
        v.continueTracking = {_ in
            self.isInteracting = false
        }
        v.tag = 1
        v.displayValueBackgroudColor = .black.withAlphaComponent(0.7)
        v.formatValueDisplay = { value in
            let second = value * CGFloat(self.videoLength)
            return self.timeFormatted(totalSeconds: Double(second))
        }
        v.isUserInteractionEnabled = false
        v.addTarget(self, action: #selector(progressSliderTouchEnd(slider:)), for: [.touchUpInside])
        v.addTarget(self, action: #selector(progressSliderChanged(slider:)), for: [.valueChanged])
        v.addTarget(self, action: #selector(progressSliderBeginTouch), for: [.touchDown])
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var nextButton : UIButton = {
        let v = UIButton()
        v.tag = 2
        v.setImage(UIImage(named: "ic_next"), for: .normal)
        v.addTarget(self, action: #selector(nextButtonPressed), for: .touchUpInside)
        if #available(iOS 15, *) {}
        else { v.contentEdgeInsets = .zero }
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var previousButton : UIButton = {
        let v = UIButton()
        v.tag = 2
        v.setImage(UIImage(named: "ic_prev"), for: .normal)
        v.addTarget(self, action: #selector(previousButtonPressed), for: .touchUpInside)
        if #available(iOS 15, *) {}
        else { v.contentEdgeInsets = .zero }
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var progressLoader : Loader = {
        let v = Loader()
        v.tintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var resizeButton : ResizeButton = {
        let v = ResizeButton()
        v.tag = 1
        v.backgroundColor = .clear
        v.addTarget(self, action: #selector(resizeButtonPressed), for: .touchUpInside)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var currentTimeLabel : UILabel = {
        let v = UILabel()
        v.numberOfLines = 1
        v.tag = 1
        v.font = .systemFont(ofSize: 12) //medium
        v.textAlignment = .left
        v.textColor  = .white
        v.text = "0:00 / 0:00"
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var speedButton : UIButton = {
        let v = UIButton()
        v.tag = 1
        if #available(iOS 15, *) {}
        else { v.contentEdgeInsets = .zero }
        v.setImage(UIImage(named: "ic_speed"), for: .normal)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.addTarget(self, action: #selector(speedButtonPressed), for: .touchUpInside)
        return v
    }()
    
    
    
    // MARK: Variables
    var backgroundControlColor : UIColor = .black.withAlphaComponent(0.5)
    var isHiddenControl : Bool = false {
        didSet {
            if isHiddenControl { self.hideAllControls() }
            else { self.showAllControls() }
        }
    }
    var isTrackingSlider : Bool {
        return self.progressSlider.isTracking
    }

    private var videoLength : Double = 0
    private let timeFastForward : Double = 5
    weak var delegate : VideoPlayerControlsDelegate?
    private var forwardToggleWorkItem: DispatchWorkItem?
    private var rewindToggleWorkItem: DispatchWorkItem?
    var playPauseButtonConstant : AppConstants = .init()
    var nextButtonConstant : AppConstants = .init()
    var previousButtonConstant : AppConstants = .init()
    var progressLoaderConstant : AppConstants = .init()
    var currentTimeLabelConstant : AppConstants = .init()
    var resizeButtonConstant : AppConstants = .init()
    var speedButtonConstant : AppConstants = .init()
    var progressSliderConstant : AppConstants = .init()
    
    private var timeForward : Double = 0 {
        didSet {
            if timeForward > 0 {
                hideAllControls(animated: false)
                showBottomControl(animated: false)
                setRewindAlpha(0)
                setForwardAlpha(1)
                if oldValue != timeForward {
                    let time = getCurrentTime() + abs(oldValue - timeForward)
                    seek(to: time)
                    self.rippleFastForward.setText(timeForward)
                    delegate?.videoPlayerControls(self, seek: time)
                }
            }
            else if timeRewind == 0 {
                isHiddenControl = false
                setForwardAlpha(0)
            }
           isInteracting = false
        }
    }
    
    private var timeRewind: Double = 0 {
        didSet {
            if timeRewind > 0 {
                hideAllControls(animated: false)
                showBottomControl(animated: false)
                setRewindAlpha(1)
                setForwardAlpha(0)
                if oldValue != timeRewind {
                    let time = getCurrentTime() - abs(oldValue - timeRewind)
                    seek(to: time)
                    self.rippleRewind.setText(timeRewind)
                    delegate?.videoPlayerControls(self, seek: time)
                }
            }
            else if timeForward == 0 {
                isHiddenControl = false
                setRewindAlpha(0)
            }
            isInteracting = false
        }
    }
    
    var nextButtonHidden: Bool {
        set {
            nextButton.isHidden = newValue
        }
        get {
            return nextButton.isHidden
        }
    }
    
    var previousButtonHidden: Bool {
        set {
            previousButton.isHidden = newValue
        }
        get {
            return previousButton.isHidden
        }
    }
    
    var interacting: ((Bool) -> Void) = {_ in }
    @objc private var isInteracting: Bool = false {
        didSet {
            interacting(isInteracting)
        }
    }
    // MARK: - Superclass methods -
    
    override init(frame: CGRect) {
       super.init(frame: frame)
       
       commonInit()
   }
   
   public required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
       
       commonInit()
   }
    
    func newVideo(){
        self.progressSlider.isUserInteractionEnabled = false
        self.progressSlider.value = 0.0
        self.currentTimeLabel.text = String(format: "%@ / %@",self.timeFormatted(totalSeconds: 0), self.timeFormatted(totalSeconds: 0))
        self.startLoading()
    }
    
    func readyToPlayVideo(_ videoLength: Double, currentTime: Double) {
        self.configureInitialControlState(videoLength,currentTime: currentTime)
    }
    
    func playingVideo(currentTime: Double){
        let progress : CGFloat = CGFloat(currentTime) / (videoLength != 0 ? CGFloat(videoLength) : 1.0)
        self.progressSlider.value = progress
        self.currentTimeLabel.text = String(format: "%@ / %@",self.timeFormatted(totalSeconds: currentTime), self.timeFormatted(totalSeconds: videoLength))
    }
    
    func startedVideo(currentTime: Double) {
        self.playPauseButton.buttonState = .pause
        self.configureInitialControlState(videoLength, currentTime: currentTime)
       
    }
    
    func stoppedVideo() {
        self.playPauseButton.buttonState = .play
        self.progressSlider.value = 0.0
    }
    
    func finishedVideo(){
        
    }
    func error(_ error : Error) {
        isHiddenControl = true
        print(error.localizedDescription)
    }
    
    func seekStarted(){
        self.startLoading()
    }
    
    func seekEnded() {
        self.stopLoading()
    }
    
    func pausedVideo(){
        self.playPauseButton.buttonState = .play
    }
    
    func hideAllControls(animated: Bool = true, complete : ((Bool) -> ())? = nil){
        let action = {
            self.subviews.forEach({ if $0.tag > 0 { $0.alpha = 0.0 } })
            self.backgroundColor = .clear
            self.nextButton.isHidden = self.nextButtonHidden
            self.previousButton.isHidden = self.previousButtonHidden
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: { action() }, completion: { finished in
                complete?(finished)
            })
        }
        else{
            action()
            complete?(true)
        }
    }
    func showAllControls(animated: Bool = true, complete : ((Bool) -> ())? = nil) {
        let action = {
            self.subviews.forEach({ if ($0.tag > 0) {  $0.alpha = 1 } })
            self.backgroundColor = self.backgroundControlColor
            self.nextButton.isHidden = self.nextButtonHidden
            self.previousButton.isHidden = self.previousButtonHidden
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: { action() }, completion: { finished in
                complete?(finished)
            })
        }
        else{
            action()
            complete?(true)
        }
    }
    
    func showBottomControl(animated: Bool = true, complete : ((Bool) -> ())? = nil){
        let action = {
            self.subviews.forEach({ if $0.tag == 1 { $0.alpha = 1 } })
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: { action() }, completion: { finished in
                complete?(finished)
            })
        }
        else{
            action()
            complete?(true)
        }
        
    }
    
    func hideBottomControl(animated: Bool = true, complete : ((Bool) -> ())? = nil){
        let action = {
            self.subviews.forEach({ if $0.tag == 1 { $0.alpha = 0 } })
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: { action() }, completion: { finished in
                complete?(finished)
            })
        }
        else{
            action()
            complete?(true)
        }
    }
    
    func hideCenterControl(animated: Bool = true, complete : ((Bool) -> ())? = nil){
        let action = {
            self.subviews.forEach({ if $0.tag == 2 { $0.alpha = 0 } })
            self.nextButton.isHidden = self.nextButtonHidden
            self.previousButton.isHidden = self.previousButtonHidden
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: { action() }, completion: { finished in
                complete?(finished)
            })
        }
        else{
            action()
            complete?(true)
        }
    }
    
    func showCenterControl(animated: Bool = true, complete : ((Bool) -> ())? = nil){
        let action = {
            self.subviews.forEach({ if $0.tag == 2 { $0.alpha = 1 } })
            self.nextButton.isHidden = self.nextButtonHidden
            self.previousButton.isHidden = self.previousButtonHidden
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: { action() }, completion: { finished in
                complete?(finished)
            })
        }
        else{
            action()
            complete?(true)
        }
    }
    
    func seek(to second : Double){
        let value : CGFloat = CGFloat(second) / CGFloat(videoLength)
        self.progressSlider.value = value
    }
    
    func resizeScreen(_ state : ResizeButton.ButtonState){
        self.resizeButton.buttonState = state
    }
    
    
    // MARK: - Private methods -
    private func setRewindAlpha(_ alpha : CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.rippleRewind.alpha = alpha
        }
    }
    private func setForwardAlpha(_ alpha : CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.rippleFastForward.alpha = alpha
        }
    }
    private func startLoading(){
        self.progressLoader.startAnimating()
        self.playPauseButton.isHidden = true
        self.rippleFastForward.isHidden = true
        self.rippleRewind.isHidden = true
    }
    
    private func stopLoading(){
        self.progressLoader.stopAnimating()
        self.playPauseButton.isHidden = false
        self.rippleFastForward.isHidden = false
        self.rippleRewind.isHidden = false
    }
    
    private func getCurrentTime() -> Double {
        let value = self.progressSlider.value
        let time = value * CGFloat(videoLength)
        return min(videoLength , Double(time))
    }
    
    private func playButtonPressed() {
        isInteracting = false
        self.delegate?.videoPlayerControls(self, play: self.playPauseButton)
       
    }
    @objc private func nextButtonPressed() {
        isInteracting = false
        self.delegate?.videoPlayerControls(next: self)
    }
    @objc private func previousButtonPressed() {
        isInteracting = false
        self.delegate?.videoPlayerControls(prev: self)
    }
    
    @objc private func progressSliderBeginTouch() {
        isInteracting = false
    }
    
    @objc private func resizeButtonPressed() {
        isInteracting = false
        self.delegate?.videoPlayerControls(self, resize: self.resizeButton)
    }
    @objc private func speedButtonPressed() {
        isInteracting = false
        delegate?.videoPlayerControls(self, rate: speedButton)
    }
    
    @objc private func progressSliderChanged(slider: Scrubber) {
        let second = Double(slider.value) * Double(videoLength)
        self.playingVideo(currentTime: second)
    }
    
    @objc private func progressSliderTouchEnd(slider: Scrubber) {
        let second = Double(slider.value) * videoLength
        self.delegate?.videoPlayerControls(self, seek: second)
        isInteracting = false
    }
    
    
    private func timeFormatted(totalSeconds: Double) -> String {
        let seconds = Int(totalSeconds) % 60
        let minutes = (Int(totalSeconds) / 60) % 60
//        let hours = totalSeconds / 3600
        
        return String(format: "%01d:%02d", minutes, seconds)
    }
    private func configureInitialControlState(_ videoLength: Double, currentTime: Double) {
        self.videoLength = videoLength
        progressSlider.isUserInteractionEnabled = true
        
        currentTimeLabel.text = String(format: "%@ / %@", timeFormatted(totalSeconds: currentTime), timeFormatted(totalSeconds: videoLength))
        self.stopLoading()
    }
    
     func doubleTapControl(_ sender : UITapGestureRecognizer){
        let time = getCurrentTime()
        if self.rippleRewind.frame.contains(sender.location(in: self)) {
            rewindToggleWorkItem?.cancel()
            let runDispatchWork = {
                self.rewindToggleWorkItem = DispatchWorkItem(block: { [weak self] in
                    self?.timeRewind = 0
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: self.rewindToggleWorkItem!)
            }
            guard time > 0 else {
                runDispatchWork()
                return
            }
            rippleRewind.beginRippleTouchDown(at: sender.location(in: rippleRewind), animated: true)
            let step = min(time,timeFastForward)
            self.timeRewind += step
            runDispatchWork()
        }
        else if self.rippleFastForward.frame.contains(sender.location(in: self)) {
            forwardToggleWorkItem?.cancel()
            let runDispatchWork = {
                self.forwardToggleWorkItem = DispatchWorkItem(block: { [weak self] in
                    self?.timeForward = 0
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: self.forwardToggleWorkItem!)
            }
            guard time < videoLength else {
                runDispatchWork()
                return
            }
            rippleFastForward.beginRippleTouchDown(at: sender.location(in: rippleFastForward), animated: true)
            let step = min(videoLength - time,timeFastForward)
            self.timeForward += step
            runDispatchWork()
        }
        
    }
    @objc private func rotated(_ sender : Any?){
        isHiddenControl = false
    }

  
    private func commonInit() {
        [rippleRewind, rippleFastForward, progressLoader, progressSlider, nextButton, previousButton, currentTimeLabel, resizeButton, speedButton, playPauseButton].forEach({addSubview($0)})
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        
        
        setupLayout()
    }
    private func getSize(_ value : CGFloat) -> CGFloat {
        return value
    }
  
    
    private func setupLayout() {
        playPauseButtonConstant = .init(
            width: self.playPauseButton.widthAnchor.constraint(equalTo: self.playPauseButton.heightAnchor),
            height: self.playPauseButton.heightAnchor.constraint(equalToConstant: getSize(78)),
            centerX: self.playPauseButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            centerY: self.playPauseButton.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        
        
        nextButtonConstant = .init(
            left: self.nextButton.leadingAnchor.constraint(equalTo: self.playPauseButton.trailingAnchor, constant: getSize(28)),
            width: self.nextButton.widthAnchor.constraint(equalTo: self.nextButton.heightAnchor),
            height:  self.nextButton.heightAnchor.constraint(equalToConstant: getSize(32)),
            centerY: self.nextButton.centerYAnchor.constraint(equalTo: self.playPauseButton.centerYAnchor))
        
        
        previousButtonConstant = .init(
            right: self.previousButton.trailingAnchor.constraint(equalTo: self.playPauseButton.leadingAnchor, constant: -28),
            width: self.previousButton.widthAnchor.constraint(equalTo: self.previousButton.heightAnchor),
            height: self.previousButton.heightAnchor.constraint(equalToConstant: getSize(32)),
            centerY: self.previousButton.centerYAnchor.constraint(equalTo: self.playPauseButton.centerYAnchor))
        
        
        progressLoaderConstant = .init(
            width: self.progressLoader.widthAnchor.constraint(equalTo: self.progressLoader.heightAnchor),
            height: self.progressLoader.heightAnchor.constraint(equalToConstant: getSize(45)),
            centerX:  self.progressLoader.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            centerY: self.progressLoader.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        
        
        currentTimeLabelConstant = .init(
            left: self.currentTimeLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: getSize(32)), bottom: self.currentTimeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: getSize(-16)), width: self.currentTimeLabel.widthAnchor.constraint(equalToConstant: 90),
            height:  self.currentTimeLabel.heightAnchor.constraint(equalTo: self.progressSlider.heightAnchor))
        
        
        resizeButtonConstant = .init(
            right: self.resizeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: getSize(-32)),
            bottom: self.resizeButton.bottomAnchor.constraint(equalTo: self.currentTimeLabel.bottomAnchor),
            width: self.resizeButton.widthAnchor.constraint(equalTo: self.resizeButton.heightAnchor),
            height:   self.resizeButton.heightAnchor.constraint(equalToConstant: getSize(24)))
        
        speedButtonConstant = .init(
            right:  self.speedButton.trailingAnchor.constraint(equalTo: self.resizeButton.leadingAnchor, constant: getSize(-24)),
            bottom:  self.speedButton.bottomAnchor.constraint(equalTo: self.currentTimeLabel.bottomAnchor),
            width: self.speedButton.widthAnchor.constraint(equalTo: self.speedButton.heightAnchor),
            height: self.speedButton.heightAnchor.constraint(equalToConstant: getSize(24)))
        
        
        progressSliderConstant = .init(
            left: self.progressSlider.leadingAnchor.constraint(equalTo: self.currentTimeLabel.trailingAnchor, constant: getSize(0)),
            right:  self.progressSlider.trailingAnchor.constraint(equalTo: self.speedButton.leadingAnchor, constant: getSize(-23)),
            bottom: self.progressSlider.bottomAnchor.constraint(equalTo: self.currentTimeLabel.bottomAnchor),
            height:  self.progressSlider.heightAnchor.constraint(equalToConstant: getSize(24)))
   
        [playPauseButtonConstant, nextButtonConstant, previousButtonConstant, progressLoaderConstant, currentTimeLabelConstant, resizeButtonConstant, speedButtonConstant, progressSliderConstant].forEach({$0.active()})
        
        NSLayoutConstraint.activate([
            self.rippleRewind.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.rippleRewind.topAnchor.constraint(equalTo: self.topAnchor),
            self.rippleRewind.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.rippleRewind.trailingAnchor.constraint(equalTo: self.rippleFastForward.leadingAnchor),
            self.rippleRewind.widthAnchor.constraint(equalTo: self.rippleFastForward.widthAnchor),
            
            self.rippleFastForward.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.rippleFastForward.topAnchor.constraint(equalTo: self.topAnchor),
            self.rippleFastForward.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.rippleFastForward.leadingAnchor.constraint(equalTo: self.rippleRewind.trailingAnchor),
            self.rippleFastForward.widthAnchor.constraint(equalTo: self.rippleRewind.widthAnchor),
        ])
        
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if isInteracting(point) { return hitView }
        return nil
    }

    func isInteracting(_ point : CGPoint) -> Bool{
        return self.subviews.first(where: {
            return ($0.tag > 0) && $0.alpha > 0 && !$0.isHidden && $0.frame.contains(point)
        }) != nil
    }
            
    func isRippleView(_ touch : UITouch) -> Bool {
        return self.rippleRewind.frame.contains(touch.location(in: self)) || self.rippleFastForward.frame.contains(touch.location(in: self))
    }
}
extension VideoPlayerControls : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if  touch.view?.tag ?? 0 == -1 {
            return true
        }
        return false
    }
}
