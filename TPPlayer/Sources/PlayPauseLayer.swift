//
//  PlayPauseLayer.swift
//  TPPlayer
//
//  Created by Truc Pham on 01/10/2021.
//

import Foundation
import UIKit
class PlayPauseLayer: AnimatableLayer {
    open override func draw(in context: CGContext) {
        super.draw(in: context)

        let insetBounds = bounds.insetBy(dx: 4.0, dy: 4.0)

        let height: CGFloat = insetBounds.height
        let itemWidth: CGFloat = insetBounds.width * 0.35
        let targetWidth: CGFloat = ((insetBounds.width / 2.0) - itemWidth) * animationDirection
        let width = itemWidth + targetWidth

        let firstItemHeight = height / 4.0 * animationDirection
        let secondItemHeight = height / 2.0 * animationDirection

        context.move(to: CGPoint(x: insetBounds.origin.x, y: insetBounds.origin.y))
        context.addLine(to: CGPoint(x: insetBounds.origin.x + width, y: insetBounds.origin.y + firstItemHeight))
        context.addLine(to: CGPoint(x: insetBounds.origin.x + width, y: insetBounds.origin.y + height - firstItemHeight))
        context.addLine(to: CGPoint(x: insetBounds.origin.x, y: insetBounds.origin.y + height))

        context.move(to: CGPoint(x: insetBounds.origin.x + insetBounds.width - width, y: insetBounds.origin.y + firstItemHeight))
        context.addLine(to: CGPoint(x: insetBounds.origin.x + insetBounds.width, y: insetBounds.origin.y + secondItemHeight))
        context.addLine(to: CGPoint(x: insetBounds.origin.x + insetBounds.width, y: insetBounds.origin.y + height - secondItemHeight))
        context.addLine(to: CGPoint(x: insetBounds.origin.x + insetBounds.width - width, y: insetBounds.origin.y + height - firstItemHeight))

        context.setShadow(offset: CGSize(width: 0.5, height: 0.5), blur: 3.0)
        context.setFillColor(color.cgColor)
        context.fillPath()
    }
}

class AnimatableLayer: CALayer {
    @NSManaged  var animationDirection: CGFloat
    @NSManaged  var color: UIColor

     override init() {
        super.init()
        contentsScale = UIScreen.main.scale

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        animationDirection = 1.0
        CATransaction.commit()
    }

     override init(layer: Any) {
        super.init(layer: layer)

        if let layer = layer as? AnimatableLayer {
            animationDirection = layer.animationDirection
            color = layer.color
        }
    }

    required  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func action(forKey event: String) -> CAAction? {
        if event == "animationDirection" {
            let basicAnimation = CABasicAnimation(keyPath: event)
            basicAnimation.fromValue = animationDirection
            basicAnimation.toValue = 1.0 - animationDirection
            basicAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            basicAnimation.duration = 0.25

            return basicAnimation
        }

        return super.action(forKey: event)
    }

    open override class func needsDisplay(forKey key: String) -> Bool {
        if key == "animationDirection" || key == "color" {
            return true
        }

        return super.needsDisplay(forKey: key)
    }
}
