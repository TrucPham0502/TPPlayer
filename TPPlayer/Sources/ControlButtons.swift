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
 class PlayPauseButton: UIButton {
    enum ButtonState {
        case play
        case pause
    }

     var buttonState: ButtonState {
        set {
            switch newValue {
            case .play:
                isSelected = false
            default:
                isSelected = true
            }
        }
        get {
            return isSelected == true ? .pause : .play
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

    @objc fileprivate func changeState() {
        isSelected = !isSelected
    }

    private func commonInit() {
        if #available(iOS 15, *) {
            
        }
        else {
            self.contentEdgeInsets = .zero
        }
        self.setImage(UIImage(named: "ic_play"), for: .normal)
        self.setImage(UIImage(named: "ic_pause"), for: .selected)
        addTarget(self, action: #selector(changeState), for: .touchUpInside)
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
                isSelected = false
            default:
                isSelected = true
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

   @objc fileprivate func changeState() {
       isSelected = !isSelected
   }

   private func commonInit() {
       if #available(iOS 15, *) {
           
       }
       else {
           self.contentEdgeInsets = .zero
       }
       self.setImage(UIImage(named: "ic_resize_small"), for: .normal)
       self.setImage(UIImage(named: "ic_resize_large"), for: .selected)
       addTarget(self, action: #selector(changeState), for: .touchUpInside)
   }
}

