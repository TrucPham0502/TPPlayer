//
//  Loader.swift
//  TPPlayer
//
//  Created by Truc Pham on 01/10/2021.
//

import Foundation
import UIKit
class Loader: UIView {

    // MARK: - Private Variables and Constants -

    private let progressLayer = CAShapeLayer()

    // MARK: - Public Variables -

    /*
     The width of the circle.
     */
    var lineWidth: CGFloat = 4.0

    // MARK: - Superclass methods -

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.addSublayer(progressLayer)
        backgroundColor = .clear
        updatePath()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.layer.addSublayer(progressLayer)
        
        backgroundColor = .clear
        updatePath()
    }

    override  func layoutSubviews() {
        super.layoutSubviews()
        progressLayer.frame = bounds
        updatePath()
    }

    // MARK: - Public methods -

    /*
     Starts the loader animation.
     */
    func startAnimating() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.duration = 4.0
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = 2.0 * .pi
        rotationAnimation.repeatCount = .infinity
        progressLayer.add(rotationAnimation, forKey: "rotationAnimation")

        let headAnimation = CABasicAnimation(keyPath: "strokeStart")
        headAnimation.duration = 1.0
        headAnimation.fromValue = 0.0
        headAnimation.toValue = 0.1
        headAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let tailAnimation = CABasicAnimation(keyPath: "strokeEnd")
        tailAnimation.duration = 1.0
        tailAnimation.fromValue = 0.0
        tailAnimation.toValue = 1.0
        tailAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let endHeadAnimation = CABasicAnimation(keyPath: "strokeStart")
        endHeadAnimation.beginTime = 1.0
        endHeadAnimation.duration = 0.5
        endHeadAnimation.fromValue = 0.1
        endHeadAnimation.toValue = 1.0
        endHeadAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let endTailAnimation = CABasicAnimation(keyPath: "strokeEnd")
        endTailAnimation.beginTime = 1.0
        endTailAnimation.duration = 0.5
        endTailAnimation.fromValue = 1.0
        endTailAnimation.toValue = 1.0
        endTailAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let animations = CAAnimationGroup()
        animations.beginTime = CACurrentMediaTime() + 0.25
        animations.duration = 1.5
        animations.animations = [headAnimation, tailAnimation, endHeadAnimation, endTailAnimation]
        animations.repeatCount = .infinity

        progressLayer.add(animations, forKey: "fillAnimations")
    }

    /*
     Stops the loader animation.
     */
    func stopAnimating() {
        progressLayer.removeAllAnimations()
    }

    // MARK: - Private methods -

    private func updatePath() {
        let startAngle: CGFloat = 0.0
        let endAngle: CGFloat = 2.0 * .pi
        let radius: CGFloat = min(bounds.size.width / 2.0, bounds.size.height / 2.0)
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: radius - lineWidth / 2.0, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        progressLayer.contentsScale = UIScreen.main.scale

        progressLayer.path = path.cgPath

       
        progressLayer.fillColor = backgroundColor?.cgColor
        progressLayer.strokeColor = tintColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = 0.0
    }
}
