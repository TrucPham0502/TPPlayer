//
//  VideoPlayerControls.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit
class VideoPlayerControls : UIView {
    
    
    // MARK: Properties
    private lazy var rippleLeft : RippleView = {
        let v =  RippleView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        v.type = .left
        return v
    }()
    private lazy var rippleRight : RippleView = {
        let v =  RippleView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        v.type = .right
        return v
    }()
    
    private lazy var playPauseButton : PlayPauseButton = {
       let v = PlayPauseButton()
        v.backgroundColor = .clear
        v.tintColor = tintColor
        v.addTarget(self, action: #selector(playButtonPressed), for: .touchUpInside)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var  progressSlider : Scrubber = {
        let v = Scrubber()
        v.tintColor = tintColor
        v.addTarget(self, action: #selector(progressSliderChanged(slider:)), for: [.touchUpInside])
        v.addTarget(self, action: #selector(progressSliderBeginTouch), for: [.touchDown])
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var nextButton : UIButton = {
        let v = UIButton()
        v.tintColor = tintColor
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
        v.tintColor = tintColor
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
        v.tintColor = tintColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var resizeButton : ResizeButton = {
        let v = ResizeButton()
        v.backgroundColor = .clear
        v.tintColor = tintColor
        v.addTarget(self, action: #selector(resizeButtonPressed), for: .touchUpInside)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var currentTimeLabel : UILabel = {
        let v = UILabel()
        v.numberOfLines = 1
        v.font = .systemFont(ofSize: 12) //medium
        v.textAlignment = .center
        v.textColor = tintColor
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
    
    override var tintColor: UIColor! {
        didSet {
            playPauseButton.tintColor = tintColor
            nextButton.tintColor = tintColor
            previousButton.tintColor = tintColor
            progressLoader.tintColor = tintColor
            progressSlider.tintColor = tintColor
            currentTimeLabel.textColor = tintColor
            
            resizeButton.tintColor = tintColor
        }
    }
    var interacting: ((Bool) -> Void)?
    @objc var isInteracting: Bool = false {
        didSet {
            interacting?(isInteracting)
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
        
        self.progressLoader.startAnimating()
        self.progressSlider.value = 0.0
        
        
        self.currentTimeLabel.text = String(format: "%d / %d",self.timeFormatted(totalSeconds: 0), self.timeFormatted(totalSeconds: 0))
        
        self.progressLoader.startAnimating()
    }
    
    func readyToPlayVideo(_ videoLength: Int, currentTime: Int) {
        self.configureInitialControlState(videoLength,currentTime: currentTime)
    }
    
    func playingVideo(_ progress: CGFloat, currentTime: Int){
        if self.isInteracting == false {
            self.progressSlider.value = progress
        }
        self.currentTimeLabel.text = self.timeFormatted(totalSeconds: currentTime)
    }
    
    func startedVideo(_ videoLength: Int, currentTime: Int) {
        self.playPauseButton.buttonState = .pause
        self.configureInitialControlState(videoLength, currentTime: currentTime)
        isInteracting = true
    }
    
    func stoppedVideo() {
        self.playPauseButton.isSelected = false
        self.progressSlider.value = 0.0
    }
    
    func finishedVideo(){
        
    }
    func error(_ error : Error) {
        print(error.localizedDescription)
    }
    
    func seekStarted(){
        self.progressLoader.startAnimating()
    }
    
    func seekEnded() {
        self.progressLoader.stopAnimating()
    }
    
    func pausedVideo(){
        self.playPauseButton.buttonState = .play
        isInteracting = false
    }
    
    // MARK: - Private methods -
    
    
    @objc private func playButtonPressed() {
        
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
        let hours = totalSeconds / 3600
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    private func configureInitialControlState(_ videoLength: Int, currentTime: Int) {
        
        progressSlider.isUserInteractionEnabled = true
        
        currentTimeLabel.text = String(format: "%d / %d", timeFormatted(totalSeconds: currentTime), timeFormatted(totalSeconds: videoLength))
        
        progressLoader.stopAnimating()
    }
    
    @objc private func doubleTapControl(_ sender : UITapGestureRecognizer){
        if self.rippleLeft.frame.contains(sender.location(in: self)) {
            rippleLeft.beginRippleTouchDown(at: sender.location(in: rippleLeft), animated: true)
        }
        else if self.rippleRight.frame.contains(sender.location(in: self)) {
            rippleRight.beginRippleTouchDown(at: sender.location(in: rippleRight), animated: true)
        }
    }
    
    private func commonInit() {
        addSubview(rippleLeft)
        addSubview(rippleRight)
        
        addSubview(progressLoader)
        addSubview(playPauseButton)
        addSubview(progressSlider)
        addSubview(nextButton)
        addSubview(previousButton)
        addSubview(currentTimeLabel)
        addSubview(resizeButton)
        
       let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapControl))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        
        setupLayout()
    }
   
    private func setupLayout() {
        
        NSLayoutConstraint.activate([
            self.playPauseButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.playPauseButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.playPauseButton.widthAnchor.constraint(equalTo: self.playPauseButton.heightAnchor),
            self.playPauseButton.heightAnchor.constraint(equalToConstant: 78),
            
            self.nextButton.centerYAnchor.constraint(equalTo: self.playPauseButton.centerYAnchor),
            self.nextButton.leadingAnchor.constraint(equalTo: self.playPauseButton.leadingAnchor, constant: 28),
            self.nextButton.widthAnchor.constraint(equalTo: self.nextButton.heightAnchor),
            self.nextButton.heightAnchor.constraint(equalToConstant: 32),
            
            self.previousButton.centerYAnchor.constraint(equalTo: self.playPauseButton.centerYAnchor),
            self.previousButton.trailingAnchor.constraint(equalTo: self.playPauseButton.leadingAnchor, constant: -28),
            self.previousButton.widthAnchor.constraint(equalTo: self.previousButton.heightAnchor),
            self.previousButton.heightAnchor.constraint(equalToConstant: 32),
            
            
            self.progressLoader.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.progressLoader.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.progressLoader.widthAnchor.constraint(equalTo: self.progressLoader.heightAnchor),
            self.progressLoader.heightAnchor.constraint(equalToConstant: 80),
            
            self.currentTimeLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 32),
            self.currentTimeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -19),
            
            
            self.resizeButton.widthAnchor.constraint(equalTo: self.resizeButton.heightAnchor),
            self.resizeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -32),
            self.resizeButton.heightAnchor.constraint(equalToConstant: 24),
            self.resizeButton.bottomAnchor.constraint(equalTo: self.currentTimeLabel.bottomAnchor),
            
            
            self.speedButton.trailingAnchor.constraint(equalTo: self.resizeButton.leadingAnchor, constant: -24),
            self.speedButton.widthAnchor.constraint(equalTo: self.speedButton.heightAnchor),
            self.speedButton.heightAnchor.constraint(equalToConstant: 24),
            self.speedButton.bottomAnchor.constraint(equalTo: self.currentTimeLabel.bottomAnchor),
            
            self.progressSlider.leadingAnchor.constraint(equalTo: self.currentTimeLabel.trailingAnchor, constant: 23),
            self.progressSlider.heightAnchor.constraint(equalToConstant: 24),
            self.progressSlider.trailingAnchor.constraint(equalTo: self.speedButton.leadingAnchor, constant: 23),
            self.progressSlider.bottomAnchor.constraint(equalTo: self.currentTimeLabel.bottomAnchor),
        ])
        
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
