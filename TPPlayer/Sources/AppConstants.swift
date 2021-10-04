//
//  AppConstants.swift
//  TPPlayer
//
//  Created by TrucPham on 04/10/2021.
//

import Foundation
import UIKit
class AppConstants {
    internal init(left: NSLayoutConstraint? = nil, right: NSLayoutConstraint? = nil, bottom: NSLayoutConstraint? = nil, top: NSLayoutConstraint? = nil, width: NSLayoutConstraint? = nil, height: NSLayoutConstraint? = nil, centerX : NSLayoutConstraint? = nil, centerY : NSLayoutConstraint? = nil) {
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.width = width
        self.height = height
        self.centerX = centerX
        self.centerY = centerY
    }
    let left : NSLayoutConstraint?
    let right : NSLayoutConstraint?
    let bottom : NSLayoutConstraint?
    let top : NSLayoutConstraint?
    let width : NSLayoutConstraint?
    let height : NSLayoutConstraint?
    let centerX : NSLayoutConstraint?
    let centerY : NSLayoutConstraint?
    
    func active(){
        [self.left, self.right, self.bottom, self.top, self.width, self.height, self.centerX, self.centerY].forEach({ $0?.isActive = true})
    }
}
