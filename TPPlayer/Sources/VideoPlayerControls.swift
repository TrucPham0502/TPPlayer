//
//  VideoPlayerControls.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit
import AVFoundation

class VideoPlayerControls : UIView {
    
    // MARK: Properties
    private lazy var rippleLeft : CircleRippleView = {
        let v =  CircleRippleView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        v.type = .left
        v.backgroundColor = .red
        return v
    }()
    private lazy var rippleRight : CircleRippleView = {
        let v =  CircleRippleView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        v.type = .right
        return v
    }()
    
    private lazy var playPauseButton : PlayPauseButton = {
        let v = PlayPauseButton()
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
        v.displayValueBackgroudColor = .black.withAlphaComponent(0.7)
        v.formatValueDisplay = { value in
            return "\(value)"
        }
        v.addTarget(self, action: #selector(progressSliderChanged(slider:)), for: [.touchUpInside])
        v.addTarget(self, action: #selector(progressSliderBeginTouch), for: [.touchDown])
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var nextButton : UIButton = {
        let v = UIButton()
        v.setImage(UIImage(named: "ic_next"), for: .normal)
        v.addTarget(self, action: #selector(nextButtonPressed), for: .touchUpInside)
        if #available(iOS 15, *) {
           
        }
        else {
            v.contentEdgeInsets = .zero
        }
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var previousButton : UIButton = {
        let v = UIButton()
        v.setImage(UIImage(named: "ic_prev"), for: .normal)
        v.addTarget(self, action: #selector(previousButtonPressed), for: .touchUpInside)
        if #available(iOS 15, *) {
            
        }
        else {
            v.contentEdgeInsets = .zero
        }
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
        v.backgroundColor = .clear
        v.addTarget(self, action: #selector(resizeButtonPressed), for: .touchUpInside)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var currentTimeLabel : UILabel = {
        let v = UILabel()
        v.numberOfLines = 1
        v.font = .systemFont(ofSize: 12) //medium
        v.textAlignment = .center
        v.textColor  = .white
        v.text = "0:00 / 0:00"
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var speedButton : UIButton = {
        let v = UIButton()
        if #available(iOS 15, *) {
            
        }
        else {
            v.contentEdgeInsets = .zero
        }
        v.setImage(UIImage(named: "ic_speed"), for: .normal)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    
    
    // MARK: Variables
    private var controlsToggleWorkItem: DispatchWorkItem?
    var playPauseButtonConstant : AppConstants = .init()
    var nextButtonConstant : AppConstants = .init()
    var previousButtonConstant : AppConstants = .init()
    var progressLoaderConstant : AppConstants = .init()
    var currentTimeLabelConstant : AppConstants = .init()
    var resizeButtonConstant : AppConstants = .init()
    var speedButtonConstant : AppConstants = .init()
    var progressSliderConstant : AppConstants = .init()
    // indicate current device is in the LandScape orientation
    var isLandscape: Bool {
        get {
            return UIDevice.current.orientation.isValidInterfaceOrientation
                ? UIDevice.current.orientation.isLandscape
                : UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    // indicate current device is in the Portrait orientation
    var isPortrait: Bool {
        get {
            return UIDevice.current.orientation.isValidInterfaceOrientation
                ? UIDevice.current.orientation.isPortrait
                : UIApplication.shared.statusBarOrientation.isPortrait
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
        
        self.progressLoader.startAnimating()
        self.playPauseButton.isHidden = true
    }
    
    func readyToPlayVideo(_ videoLength: Int, currentTime: Int) {
        self.configureInitialControlState(videoLength,currentTime: currentTime)
    }
    
    func playingVideo(_ videoLength: Int, currentTime: Int){
        let progress : CGFloat = CGFloat(currentTime) / (videoLength != 0 ? CGFloat(videoLength) : 1.0)
        if self.isInteracting == false {
            self.progressSlider.value = progress
        }
        self.currentTimeLabel.text = String(format: "%@ / %@",self.timeFormatted(totalSeconds: currentTime), self.timeFormatted(totalSeconds: videoLength))
    }
    
    func startedVideo(_ videoLength: Int, currentTime: Int) {
        self.playPauseButton.buttonState = .pause
        self.configureInitialControlState(videoLength, currentTime: currentTime)
        isInteracting = true
    }
    
    func stoppedVideo() {
        self.playPauseButton.buttonState = .play
        self.progressSlider.value = 0.0
    }
    
    func finishedVideo(){
        
    }
    func error(_ error : Error) {
        print(error.localizedDescription)
    }
    
    func seekStarted(){
        self.progressLoader.startAnimating()
        self.playPauseButton.isHidden = true
    }
    
    func seekEnded() {
        self.progressLoader.stopAnimating()
        self.playPauseButton.isHidden = false
    }
    
    func pausedVideo(){
        self.playPauseButton.buttonState = .play
        isInteracting = false
    }
    
    func hideControls(_ complete : ((Bool) -> ())? = nil){
        UIView.animate(withDuration: 0.3, animations: {
            self.subviews.forEach({
                if !($0 is CircleRippleView) {
                    $0.layer.opacity = 0.0
                }
            })
        }, completion: { finished in
            complete?(finished)
        })
    }
    func showControls(_ complete : ((Bool) -> ())? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.subviews.forEach({
                $0.layer.opacity = 1
            })
        }, completion: { finished in
            complete?(finished)
        })
    }
    
    // MARK: - Private methods -
    
    
    private func playButtonPressed() {
        
    }
    @objc private func nextButtonPressed() {
        isInteracting = false
    }
    @objc private func previousButtonPressed() {
        isInteracting = false
    }
    
    @objc private func progressSliderBeginTouch() {
        isInteracting = true
    }
    
    @objc private func resizeButtonPressed() {
        isInteracting = false
    }
    
    @objc private func progressSliderChanged(slider: Scrubber) {
        seek(value: Double(slider.value))
        perform(#selector(setter: isInteracting), with: false, afterDelay: 0.1)
    }
    
    func seek(min: Double = 0.0, max: Double = 1.0, value: Double) {
        let value = rangeMap(value, min: min, max: max, newMin: 0.0, newMax: 1.0)
        // seek video player with value
    }
    
    private func timeFormatted(totalSeconds: Int) -> String {
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
//        let hours = totalSeconds / 3600
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    private func configureInitialControlState(_ videoLength: Int, currentTime: Int) {
        
        progressSlider.isUserInteractionEnabled = true
        
        currentTimeLabel.text = String(format: "%@ / %@", timeFormatted(totalSeconds: currentTime), timeFormatted(totalSeconds: videoLength))
        
        progressLoader.stopAnimating()
        self.playPauseButton.isHidden = false
    }
    
    @objc private func doubleTapControl(_ sender : UITapGestureRecognizer){
        if self.rippleLeft.frame.contains(sender.location(in: self)) {
            rippleLeft.beginRippleTouchDown(at: sender.location(in: rippleLeft), animated: true)
        }
        else if self.rippleRight.frame.contains(sender.location(in: self)) {
            rippleRight.beginRippleTouchDown(at: sender.location(in: rippleRight), animated: true)
        }
    }
    @objc private func rotated(_ sender : Any?){
        self.playPauseButtonConstant.height?.constant = getSize(78)
        self.nextButtonConstant.left?.constant = getSize(28)
        self.nextButtonConstant.height?.constant = getSize(32)
        self.previousButtonConstant.height?.constant = getSize(32)
        self.progressLoaderConstant.height?.constant = getSize(45)
        self.currentTimeLabelConstant.left?.constant = getSize(32)
        self.currentTimeLabelConstant.bottom?.constant = getSize(-19)
        self.resizeButtonConstant.right?.constant = getSize(-32)
        self.resizeButtonConstant.height?.constant = getSize(24)
        self.speedButtonConstant.right?.constant = getSize(-24)
        self.speedButtonConstant.height?.constant = getSize(24)
        self.progressSliderConstant.left?.constant = getSize(23)
        self.progressSliderConstant.right?.constant = getSize(-23)
        self.progressSliderConstant.height?.constant = getSize(24)
        
    }
    @objc private func toggleControls(_ sender : Any?){
        if self.alpha == 1.0  { //&& videoPlayerView.status == .playing
            hideControls()
        } else {
            controlsToggleWorkItem?.cancel()
            controlsToggleWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.hideControls()
            })

            showControls()

            if true { //videoPlayerView.status == .playing
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: controlsToggleWorkItem!)
            }
        }
    }
  
    private func commonInit() {
        [rippleLeft, rippleRight, progressLoader, progressSlider, nextButton, previousButton, currentTimeLabel, resizeButton, speedButton, playPauseButton].forEach({addSubview($0)})
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        self.interacting = { [weak self] (isInteracting) in
            guard let strongSelf = self else { return }

            strongSelf.controlsToggleWorkItem?.cancel()
            strongSelf.controlsToggleWorkItem = DispatchWorkItem(block: {
                strongSelf.hideControls()
            })

            if isInteracting == true {
                strongSelf.showControls()
            } else {
                if true { //strongSelf.videoPlayerView.status == .playing
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: strongSelf.controlsToggleWorkItem!)
                }
            }
        }
        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
//        tapGestureRecognizer.delegate = self
//        addGestureRecognizer(tapGestureRecognizer)
        
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapControl))
        doubleTapGestureRecognizer.delegate = self
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGestureRecognizer)
        setupLayout()
    }
    private func getSize(_ value : CGFloat) -> CGFloat {
        return UIScreen.main.bounds.width * value / 375
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
            left: self.currentTimeLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: getSize(32)),
            bottom: self.currentTimeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: getSize(-19)),
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
            left: self.progressSlider.leadingAnchor.constraint(equalTo: self.currentTimeLabel.trailingAnchor, constant: getSize(23)),
            right:  self.progressSlider.trailingAnchor.constraint(equalTo: self.speedButton.leadingAnchor, constant: getSize(-23)),
            bottom: self.progressSlider.bottomAnchor.constraint(equalTo: self.currentTimeLabel.bottomAnchor),
            height:  self.progressSlider.heightAnchor.constraint(equalToConstant: getSize(24)))
   
        [playPauseButtonConstant, nextButtonConstant, previousButtonConstant, progressLoaderConstant, currentTimeLabelConstant, resizeButtonConstant, speedButtonConstant, progressSliderConstant].forEach({$0.active()})
        
        NSLayoutConstraint.activate([
            self.rippleLeft.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.rippleLeft.topAnchor.constraint(equalTo: self.topAnchor),
            self.rippleLeft.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.rippleLeft.trailingAnchor.constraint(equalTo: self.rippleRight.leadingAnchor),
            self.rippleLeft.widthAnchor.constraint(equalTo: self.rippleRight.widthAnchor),
            
            self.rippleRight.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.rippleRight.topAnchor.constraint(equalTo: self.topAnchor),
            self.rippleRight.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.rippleRight.leadingAnchor.constraint(equalTo: self.rippleLeft.trailingAnchor),
            self.rippleRight.widthAnchor.constraint(equalTo: self.rippleLeft.widthAnchor),
        ])
        
    }
    
    
}
extension VideoPlayerControls : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view, view.isDescendant(of: self) == true, view != rippleLeft,
            view != rippleRight {
            return false
        } else {
            return true
        }
    }
}
