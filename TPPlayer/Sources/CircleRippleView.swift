//
//  RippleView.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit
class Triangle : CALayer {
    enum TriangleType {
        case left, right
    }
    var type : TriangleType = .left
    override func draw(in ctx: CGContext) {
        ctx.setFillColor(UIColor.white.cgColor)
        let width = self.bounds.width
        switch self.type {
        case .left:
            let startPoint : CGPoint = .init(x: 0, y: self.bounds.height / 2)
            triangleLeft(ctx: ctx, startPoint: startPoint, width: width)
        case .right:
            let startPoint : CGPoint = .init(x: 0, y: 0)
            triangleRight(ctx: ctx, startPoint: startPoint, width: width)
        }
        
        super.draw(in: ctx)
    }
    
    func triangleLeft(ctx: CGContext, startPoint: CGPoint, width: CGFloat) {
        ctx.move(to: startPoint)
        ctx.addLine(to: .init(x: startPoint.x + width, y: self.bounds.height))
        ctx.addLine(to: .init(x: startPoint.x + width, y: 0))
        ctx.addLine(to: startPoint)
        ctx.fillPath()
    }
    func triangleRight(ctx: CGContext, startPoint: CGPoint, width: CGFloat) {
        ctx.move(to: startPoint)
        ctx.addLine(to: .init(x: startPoint.x, y: self.bounds.height))
        ctx.addLine(to: .init(x: startPoint.x + width, y: self.bounds.height / 2))
        ctx.addLine(to: startPoint)
        ctx.fillPath()
    }
    
}

class SkipImageView : UIView {
    var triangleType : Triangle.TriangleType = .left {
        didSet {
            switch triangleType {
            case .left:
                self.triangleLayer3.opacity = 0
                self.triangleLayer1.opacity = 1
            case .right:
                self.triangleLayer3.opacity = 1
                self.triangleLayer1.opacity = 0
            }
            triangleLayer1.type = triangleType
            triangleLayer1.setNeedsDisplay()
            triangleLayer2.type = triangleType
            triangleLayer2.setNeedsDisplay()
            triangleLayer3.type = triangleType
            triangleLayer3.setNeedsDisplay()
        }
    }
    private lazy var triangleLayer1 : Triangle = {
        let v = Triangle()
        v.type = triangleType
        v.opacity = self.triangleType == .right ? 0 : 1
        return v
    }()
    private lazy var triangleLayer2 : Triangle = {
        let v = Triangle()
        v.type = triangleType
        return v
    }()
    private lazy var triangleLayer3 : Triangle = {
        let v = Triangle()
        v.type = triangleType
        v.opacity = self.triangleType == .left ? 0 : 1
        return v
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.addSublayer(triangleLayer1)
        self.layer.addSublayer(triangleLayer2)
        self.layer.addSublayer(triangleLayer3)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.bounds.width / 3
        triangleLayer1.frame = .init(origin: .zero, size: .init(width: width, height: self.bounds.height))
        triangleLayer1.setNeedsDisplay()
        
        triangleLayer2.frame = .init(origin: .init(x: width, y: 0), size: .init(width: width, height: self.bounds.height))
        triangleLayer2.setNeedsDisplay()
        
        triangleLayer3.frame = .init(origin: .init(x: 2*width, y:0), size: .init(width: width, height: self.bounds.height))
        triangleLayer3.setNeedsDisplay()
    }
    
    func startRewind(){
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        let width = self.bounds.width / 3
        triangleLayer1.opacity = 0
        triangleLayer1.frame.origin.x = -width
        triangleLayer1.setNeedsDisplay()
        
        triangleLayer2.frame.origin.x = 0
        triangleLayer2.setNeedsDisplay()
        
        triangleLayer3.opacity = 1
        triangleLayer3.frame.origin.x = width
        triangleLayer3.setNeedsDisplay()
        
        CATransaction.setCompletionBlock({
            CATransaction.setDisableActions(true)
            self.triangleLayer1.removeAllAnimations()
            self.triangleLayer1.opacity = 1
            self.triangleLayer1.frame.origin.x = 0
            self.triangleLayer1.setNeedsDisplay()
            
            self.triangleLayer2.removeAllAnimations()
            self.triangleLayer2.frame.origin.x = self.triangleLayer1.bounds.width
            self.triangleLayer2.setNeedsDisplay()
            
            self.triangleLayer3.removeAllAnimations()
            self.triangleLayer3.opacity = 0
            self.triangleLayer3.frame.origin.x = self.triangleLayer1.bounds.width + self.triangleLayer2.bounds.width
            self.triangleLayer3.setNeedsDisplay()
            CATransaction.setDisableActions(false)
        })
        CATransaction.commit()
    }
    
    func startForward(){
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        let width = self.bounds.width / 3
        triangleLayer3.opacity = 0
        triangleLayer3.frame.origin.x = 3*width
        triangleLayer3.setNeedsDisplay()
        
        triangleLayer2.frame.origin.x = 2*width
        triangleLayer2.setNeedsDisplay()
        
        triangleLayer1.opacity = 1
        triangleLayer1.frame.origin.x = width
        triangleLayer1.setNeedsDisplay()
        
        CATransaction.setCompletionBlock({
            CATransaction.setDisableActions(true)
            self.triangleLayer1.removeAllAnimations()
            self.triangleLayer1.opacity = 0
            self.triangleLayer1.frame.origin.x = 0
            self.triangleLayer1.setNeedsDisplay()
            
            self.triangleLayer2.removeAllAnimations()
            self.triangleLayer2.frame.origin.x = self.triangleLayer1.bounds.width
            self.triangleLayer2.setNeedsDisplay()
            
            self.triangleLayer3.removeAllAnimations()
            self.triangleLayer3.opacity = 1
            self.triangleLayer3.frame.origin.x = self.triangleLayer1.bounds.width + self.triangleLayer2.bounds.width
            self.triangleLayer3.setNeedsDisplay()
            CATransaction.setDisableActions(false)
        })
        CATransaction.commit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class CircleRippleView : UIView {
    private lazy var skipImageView : SkipImageView = {
        let v = SkipImageView()
        v.triangleType = self.position == .left ? .left  : .right
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    var skipImageViewConstants : AppConstants = .init()
    var lblViewConstants : AppConstants = .init()
    enum Position {
        case left, right
    }
    private lazy var lblView : UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 15)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.numberOfLines = 1
        v.textColor = .white
        return v
    }()
    var position : Position = .left {
        didSet {
            skipImageView.triangleType =  self.position == .left ? .left  : .right
            lblViewConstants.centerX?.constant = self.position == .left ? -7 : 7
        }
    }
    private var extendRadius : CGFloat = 50
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // cricle
        let raidus = self.bounds.height + extendRadius
        var center : CGPoint = .zero
        switch position {
        case .left:
            center = .init(x: -(raidus - self.bounds.width), y: self.bounds.height / 2)
        case .right:
            center = .init(x: raidus, y: self.bounds.height / 2)
           
        }
        let myBez = UIBezierPath()
        myBez.addArc(withCenter: center, radius: raidus, startAngle: 0, endAngle: 360, clockwise: true)
        myBez.close()
        let l = CAShapeLayer()
        l.path = myBez.cgPath
        layer.mask = l
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }

    func setText(_ number: Int){
        self.lblView.text = "\(number) giây"
    }
    func beginRippleTouchUp(animated: Bool){
        self.rippleStop()
    }
    
    func beginRippleTouchDown(at: CGPoint, animated: Bool){
        switch position {
        case .left:
            self.skipImageView.startRewind()
        case .right:
            self.skipImageView.startForward()
        }
        self.rippleFill(location: at, color: .lightGray, scale: 2*(self.bounds.height + extendRadius))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func prepareUI(){
        self.clipsToBounds = true
        self.addSubview(self.lblView)
        self.addSubview(skipImageView)
        skipImageViewConstants = .init(
            width: self.skipImageView.widthAnchor.constraint(equalToConstant: 45),
            height: self.skipImageView.heightAnchor.constraint(equalToConstant: 20),
            centerX: self.skipImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            centerY: self.skipImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -10))
        lblViewConstants = .init(
            top: self.lblView.topAnchor.constraint(equalTo: self.skipImageView.bottomAnchor, constant: 30),
            centerX: self.lblView.centerXAnchor.constraint(equalTo: self.skipImageView.centerXAnchor, constant: self.position == .left ? -7 : 7))
        
        skipImageViewConstants.active()
        lblViewConstants.active()
    }
}
