//
//  RippleView.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit
class RippleView : UIView {
    enum ViewType {
        case left, right
    }
    var type : ViewType = .left
    override func layoutSubviews() {
        super.layoutSubviews()
        switch type {
        case .left:
            let x = bounds.size.width - 80
            
            let p1 = CGPoint(x: x, y: 0)
            let p2 = CGPoint(x: x , y: bounds.size.height)
            
            let cp1 = CGPoint(x: self.bounds.width, y: p1.y)
            let cp2 = CGPoint(x: bounds.size.width, y: bounds.size.height)
            
            let myBez = UIBezierPath()
            
            myBez.move(to: p1)
            
            myBez.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
            
            myBez.addLine(to: CGPoint(x: 0, y: bounds.size.height))
            myBez.addLine(to: CGPoint.zero)
            
            myBez.close()
            
            let l = CAShapeLayer()
            l.path = myBez.cgPath
            layer.mask = l
        case .right:
            let x : CGFloat = 80
            let p1 = CGPoint(x: x, y: 0)
            let p2 = CGPoint(x: x , y: bounds.size.height)
            
            let cp1 = CGPoint(x: 0, y: p1.y)
            let cp2 = CGPoint(x: 0, y: bounds.size.height)
            
            let myBez = UIBezierPath()
            
            myBez.move(to: p1)
            
            myBez.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
            
            myBez.addLine(to: CGPoint(x: bounds.size.width, y: bounds.size.height))
            myBez.addLine(to: CGPoint(x: bounds.size.width, y: 0))
            
            myBez.close()
            
            let l = CAShapeLayer()
            l.path = myBez.cgPath
            layer.mask = l
        }
        
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
    }
    
    func beginRippleTouchUp(animated: Bool){
        self.rippleStop()
    }
    
    func beginRippleTouchDown(at: CGPoint, animated: Bool){
        self.rippleFill(location: at, color: .lightGray)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
