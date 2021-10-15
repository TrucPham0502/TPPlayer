//
//  ControlButtons.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit

/*
 Play and pause button.
 */
class PlayPauseButton: UIImageView {
    enum ButtonState {
        case play
        case pause
    }
    var tap : (PlayPauseButton) -> () = {_ in }
    var buttonState: ButtonState = .play {
        didSet {
            if oldValue != buttonState {
                let setImage = {
                    switch self.buttonState {
                    case .pause:
                        self.image = UIImage(named: "ic_pause")
                    default:
                        self.image = UIImage(named: "ic_play")
                    }
                }
                if self.alpha != 0 {
                    UIView.animate(withDuration: 0.2, animations: {
                        let extendedFrame = self.frame.insetBy(dx: -10, dy: -10)
                        self.frame = extendedFrame
                        self.alpha = 0
                    }, completion:{(finished) in
                        setImage()
                        UIView.animate(withDuration: 0.2,animations:{
                            let extendedFrame = self.frame.insetBy(dx: 10, dy: 10)
                            self.frame = extendedFrame
                            self.alpha = 1
                        },completion:nil)
                    })
                }
                else {
                    setImage()
                }
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @objc fileprivate func changeState() {
        buttonState = buttonState == .pause ? .play : .pause
        tap(self)
    }
    
    private func commonInit() {
        self.image = UIImage(named: "ic_play")
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(changeState)))
    }
}

class ResizeButton: UIButton {
    public enum ButtonState {
        case large
        case small
    }
    
    var buttonState: ButtonState {
        set {
            switch newValue {
            case .large:
                self.isSelected = false
            default:
                self.isSelected = true
            }
        }
        get {
            return isSelected == true ? .small : .large
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
    private func commonInit() {
        if #available(iOS 15, *) {
            
        }
        else {
            self.contentEdgeInsets = .zero
        }
        
        self.setImage(UIImage(named: "ic_resize_large"), for: .normal)
        self.setImage(UIImage(named: "ic_resize_small"), for: .selected)
    }
}

