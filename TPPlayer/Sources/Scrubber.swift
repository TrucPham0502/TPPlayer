//
//  Scrubber.swift
//  TPPlayer
//
//  Created by Truc Pham on 01/10/2021.
//

import Foundation
import UIKit

internal class ScrubberThumb: CALayer {
    var highlighted = false
    weak var scrubber: Scrubber?
}

class Scrubber: UIControl {
    
    // MARK: - Private Variables and Constants -
    private lazy var valueDisplayLayer : TextLayer = {
        let v = TextLayer()
        v.contentsScale = UIScreen.main.scale
        v.opacity = 0
        return v
    }()
    private var previousLocation = CGPoint()
    private lazy var trackLayer : CALayer = {
        let v = CALayer()
        v.backgroundColor = trackColor
        return v
    }()
    private lazy var trackFillLayer : CALayer = {
        let v = CALayer()
        v.backgroundColor = trackFillColor
        return v
    }()
    private lazy var thumbLayer : ScrubberThumb = {
        let v = ScrubberThumb()
        v.backgroundColor = thumbColor
        v.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        v.borderWidth = 0.5
        v.shadowColor = UIColor.black.cgColor
        v.shadowOffset = CGSize(width: 1.5, height: 1.5)
        v.shadowOpacity = 0.35
        v.shadowRadius = 2.0
        v.scrubber = self
        return v
    }()
    
    private var isEndTracking : Bool = false
    private var trackingValue : CGFloat = 0.0
    var continueTracking : (CGFloat) -> () = {_ in }
    var beginTracking : (CGFloat) -> () = {_ in }
    var endTracking : (CGFloat) -> () = {_ in }
    var thumbScale : CGFloat = 2
    
    var formatValueDisplay : (CGFloat) -> String = { v in
        return "\(v)"
    }
    
    // MARK: - Public Variables -
    var displayTextFont: UIFont = UIFont.systemFont(ofSize: 18)
    @IBInspectable  var displayTextFontSize: CGFloat = 14.0 {
        didSet {
            if #available(iOS 8.2, *) {
                displayTextFont = UIFont.systemFont(ofSize: displayTextFontSize, weight: .semibold)
            } else {
                displayTextFont = UIFont.systemFont(ofSize: displayTextFontSize)
            }
            updateFrames()
        }
    }
    
    /*
     Sets the minimum value of the scrubber. Defaults to 0.0 .
     */
    var minimumValue: CGFloat = 0.0 {
        didSet {
            updateFrames()
        }
    }
    
    /*
     Sets the maximum value of the scrubber. Defaults to 1.0 .
     */
    var maximumValue: CGFloat = 1.0 {
        didSet {
            updateFrames()
        }
    }
    
    /*
     The current value of the scrubber.
     */
    var _value : CGFloat = 0.0
    var value: CGFloat {
        get {
            return clamp(self._value, lower: minimumValue, upper: maximumValue)
        }
        set {
            if value != newValue {
                if !isEndTracking {
                    let clampedValue = clamp(newValue, lower: minimumValue, upper: maximumValue)
                    let positionX = rangeMap(clampedValue, min: minimumValue, max: maximumValue, newMin: bounds.origin.x, newMax: bounds.size.width)
                    previousLocation = CGPoint(x: positionX, y: 0.0)
                    
                    _value = clampedValue
                    sendActions(for: .valueChanged)
                    updateFrames()
                }
            }
        }
    }
    
    /*
     The height of the track. Defaults to 6.0 .
     */
    var trackHeight: CGFloat = 6.0 {
        didSet {
            updateFrames()
        }
    }
    
    /*
     Sets the color of the unfilled part of the track.
     */
    var trackColor = UIColor.white.withAlphaComponent(0.3).cgColor {
        didSet {
            trackLayer.backgroundColor = trackColor
            trackLayer.setNeedsDisplay()
        }
    }
    
    /*
     Sets the color of the filled part of the track.
     */
    var trackFillColor = UIColor.white.cgColor {
        didSet {
            trackFillLayer.backgroundColor = trackFillColor
            trackFillLayer.setNeedsDisplay()
        }
    }
    
    /*
     Sets the color of thumb.
     */
    var thumbColor = UIColor.white.cgColor {
        didSet {
            thumbLayer.backgroundColor = thumbColor
            thumbLayer.setNeedsDisplay()
        }
    }
    
    /*
     Sets the width of the track.
     */
    var thumbWidth: CGFloat = 12.0 {
        didSet {
            self.valueDisplayLayer.opacity = thumbWidth < oldValue * thumbScale ? 0 : 1
            updateFrames()
        }
    }
    
    /*
     Sets the color of the thumb and track.
     */
    override var tintColor: UIColor! {
        didSet {
            thumbColor = tintColor.cgColor
            trackFillColor = tintColor.cgColor
        }
    }
    
    /*
     Sets the color of the display value view.
     */
    var displayValueBackgroudColor = UIColor.black {
        didSet {
            self.valueDisplayLayer.displayBackgroundColor = displayValueBackgroudColor
            updateFrames()
        }
    }
    var displayValueTextColor = UIColor.white {
        didSet {
            self.valueDisplayLayer.textColor = displayValueTextColor
            updateFrames()
        }
    }
    // MARK: - Superclass methods -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override  var frame: CGRect {
        didSet {
            updateFrames()
        }
    }
    
    override  func layoutSubviews() {
        value += 0.0
        updateFrames()
    }
    
    // MARK: - UIControl methods -
    
    
    override  func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        //        previousLocation = thumbLayer.position
        let extendedFrame = thumbLayer.frame.insetBy(dx: -thumbWidth * 0.5, dy: -thumbWidth *  0.5)
        if extendedFrame.contains(touch.location(in: self)) {
            sendActions(for: .touchDown)
            thumbLayer.highlighted = true
            thumbWidth = thumbWidth * thumbScale
            updateFrameThumb(positionX: previousLocation.x, value: self.value)
            self.beginTracking(self.value)
        }
        else {
            let trackLayerExtendedFrame = trackLayer.frame.insetBy(dx: 0, dy: -trackLayer.frame.height * 1  )
            if trackLayerExtendedFrame.contains(touch.location(in: self)) {
                sendActions(for: .touchDown)
                let deltaValue = getValue(touch)
                value = deltaValue
                sendActions(for: .touchUpInside)
                stopReceiveValue()
            }
        }
        return thumbLayer.highlighted
    }
    
    override  func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if thumbLayer.highlighted {
            self.trackingValue = getValue(touch)
            
            let clampedValue = clamp(self.trackingValue, lower: minimumValue, upper: maximumValue)
            let positionX = rangeMap(clampedValue, min: minimumValue, max: maximumValue, newMin: bounds.origin.x, newMax: bounds.size.width)
            
            self.updateFrameThumb(positionX: positionX, value: self.trackingValue, animated: false)
            self.continueTracking(self.trackingValue)
        }
        return thumbLayer.highlighted
    }
    
    func getValue(_ touch: UITouch) -> CGFloat {
        let location = touch.location(in: self)
        
        let clampedX = clamp(location.x, lower: bounds.origin.x + thumbWidth / 3.5, upper: bounds.size.width - thumbWidth / 3.5)
        let deltaLocation = CGPoint(x: clampedX, y: location.y)
        let deltaValue = rangeMap(deltaLocation.x, min: bounds.origin.x + thumbWidth / 3.5, max: bounds.size.width - thumbWidth / 3.5, newMin: minimumValue, newMax: maximumValue)
        return deltaValue
        
    }
    
    override  func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        print("endTracking")
        thumbLayer.highlighted = false
        thumbWidth = thumbWidth / thumbScale
        value = self.trackingValue
        sendActions(for: .touchUpInside)
        stopReceiveValue()
        self.endTracking(self.value)
        
    }
    
    override func cancelTracking(with event: UIEvent?) {
        print("cancelTracking")
        thumbLayer.highlighted = false
        thumbWidth = thumbWidth / thumbScale
        sendActions(for: .touchCancel)
    }
    
    
    // MARK: - Private Methods -
    
    private func stopReceiveValue() {
        isEndTracking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isEndTracking = false
        }
    }
    
    private func commonInit() {
        
        layer.addSublayer(trackLayer)
        
        layer.addSublayer(trackFillLayer)
        
        layer.addSublayer(thumbLayer)
        
        layer.addSublayer(valueDisplayLayer)
        
        updateFrames()
    }
    
    func updateFrameThumb(positionX: CGFloat, value: CGFloat, animated: Bool = true) {
        let action = {
            let thumbCenter = CGPoint(x: positionX - self.thumbWidth / 2.0, y: self.bounds.midY)
            let thumbSize = self.thumbWidth * 1.0
            let thumbRadius = thumbSize / 2.0
            let rect = CGRect(x: 0.0, y: self.bounds.height / 2.0, width: self.bounds.width, height: self.trackHeight)
            self.thumbLayer.frame = CGRect(x: thumbCenter.x, y: rect.midY - thumbRadius , width: thumbSize, height: thumbSize)
            self.thumbLayer.cornerRadius = thumbRadius
            self.thumbLayer.setNeedsDisplay()
            
            self.valueDisplayLayer.string = self.formatValueDisplay(value)
            let valueSize = (self.valueDisplayLayer.string as! NSString).size(withAttributes: [NSAttributedString.Key.font: self.displayTextFont])
            let valueWidth = max(valueSize.width, 50)
            let valueHeight = valueSize.height + self.valueDisplayLayer.arrowSize.height + 20
            let offsetY = (self.bounds.height - thumbSize) / 2.0 - 5
            self.valueDisplayLayer.frame = CGRect(x: self.thumbLayer.frame.origin.x - valueWidth / 2 + thumbRadius,
                                                  y: offsetY - valueHeight,
                                                  width: valueWidth,
                                                  height: valueHeight)
            self.valueDisplayLayer.setNeedsDisplay()
        }
        if animated { action() }
        else {
            CATransaction.setDisableActions(true)
            action()
            CATransaction.setDisableActions(false)
        }
    }
    
    private func updateFrames() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        self.trackLayer.frame = CGRect(x: 0.0, y: self.bounds.height / 2.0, width: self.bounds.width, height: self.trackHeight)
        self.trackLayer.cornerRadius = self.trackHeight / 2.0
        self.trackLayer.setNeedsDisplay()
        
        if !thumbLayer.highlighted {
            updateFrameThumb(positionX: self.previousLocation.x, value: self.value)
        }
        
        self.trackFillLayer.frame = CGRect(origin: self.trackLayer.frame.origin, size: CGSize(width: self.previousLocation.x, height: self.trackHeight))
        self.trackFillLayer.cornerRadius = self.trackHeight / 2.0
        self.trackFillLayer.setNeedsDisplay()
        CATransaction.commit()
    }
    
}
