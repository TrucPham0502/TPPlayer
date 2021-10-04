//
//  RippleView.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit
class CircleRippleView : UIView {
    enum ViewType {
        case left, right
    }
    var type : ViewType = .left
    private var extendRadius : CGFloat = 50
    override func layoutSubviews() {
        super.layoutSubviews()
        var center : CGPoint = .zero
        switch type {
        case .left:
            center = .init(x: -extendRadius, y: self.bounds.height / 2)
        case .right:
            center = .init(x: self.bounds.width + extendRadius, y: self.bounds.height / 2)
        }
        
        let myBez = UIBezierPath()
        myBez.addArc(withCenter: center, radius: self.bounds.width + extendRadius, startAngle: 0, endAngle: 360, clockwise: true)
        myBez.close()
        let l = CAShapeLayer()
        l.path = myBez.cgPath
        layer.mask = l
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
    }
    
    func beginRippleTouchUp(animated: Bool){
        self.rippleStop()
    }
    
    func beginRippleTouchDown(at: CGPoint, animated: Bool){
        self.rippleFill(location: at, color: .lightGray, scale: 2*self.bounds.width)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
