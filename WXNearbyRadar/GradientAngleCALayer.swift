//
//  GradientAngleCALayer.swift
//  WXNearbyRadar
//
//  Created by Xin Wu on 2/23/16.
//  Copyright © 2016 Xin Wu. All rights reserved.
//

import UIKit

class GradientAngleCALayer: CALayer {
    
    private struct Constants {
        static let MaxAngle = 2 * M_PI
        static let MaxHue = 255.0
    }
    
    private struct Transition {
        let fromLocation: Double
        let toLocation: Double
        let fromColor: UIColor
        let toColor: UIColor
        
        func colorForPercent(percent: Double) -> UIColor {
            let normalizedPercent = percent.convertFromRange(min: fromLocation, max: toLocation, toRangeMin: 0.0, max: 1.0)
            return UIColor.lerp(from: fromColor.rgba, to: toColor.rgba, percent: CGFloat(normalizedPercent))
        }
    }
    
    // MARK: - Properties
    
    /// The array of UIColor objects defining the color of each gradient stop.
    /// Defaults to empty array. Animatable.
    
    internal var colors = [UIColor]() { didSet { setNeedsDisplay() } }
    
    /// The array of Double values defining the location of each
    /// gradient stop as a value in the range [0,1]. The values must be
    /// monotonically increasing. If empty array is given, the stops are
    /// assumed to spread uniformly across the [0,1] range.
    /// Defaults to nil. Animatable.
    
    internal var locations = [Double]() { didSet { setNeedsDisplay() } }
    
    private var transitions = [Transition]()
    
    internal override func drawInContext(ctx: CGContext) {
        UIGraphicsPushContext(ctx)
        drawRect(CGContextGetClipBoundingBox(ctx))
        UIGraphicsPopContext()
    }
    
    private func drawRect(rect: CGRect) {
        loadTransitions()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let longerSide = max(rect.width, rect.height)
        let radius = Double(longerSide) * M_SQRT2
        var angle = 0.0
        let step = M_PI_2 / radius
        
        while angle <= Constants.MaxAngle {
            let pointX = radius * cos(angle) + Double(center.x)
            let pointY = radius * sin(angle) + Double(center.y)
            let startPoint = CGPoint(x: pointX, y: pointY)
            
            let line = UIBezierPath()
            line.moveToPoint(startPoint)
            line.addLineToPoint(center)
            
            colorForAngle(angle).setStroke()
            line.stroke()
            
            angle += step
        }
    }
    
    private func colorForAngle(angle: Double) -> UIColor {
        let percent = angle.convertFromRangeZeroToMax(Constants.MaxAngle, toRangeZeroToMax: 1.0)
        guard let transition = transitionForPercent(percent) else { return spectrumColorForAngle(angle) }
        return transition.colorForPercent(percent)
    }
    
    private func spectrumColorForAngle(angle: Double) -> UIColor {
        let hue = angle.convertFromRangeZeroToMax(Constants.MaxAngle, toRangeZeroToMax: Constants.MaxHue)
        return UIColor(hue: CGFloat(hue / Constants.MaxHue), saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }
    
    private func loadTransitions() {
        transitions.removeAll()
        
        if colors.count > 1 {
            let transitionsCount = colors.count - 1
            let locationStep = 1.0 / Double(transitionsCount)
            
            for i in 0 ..< transitionsCount {
                let fromLocation, toLocation: Double
                let fromColor, toColor: UIColor
                
                if locations.count == colors.count {
                    fromLocation = locations[i]
                    toLocation = locations[i + 1]
                } else {
                    fromLocation = locationStep * Double(i)
                    toLocation = locationStep * Double(i + 1)
                }
                
                fromColor = colors[i]
                toColor = colors[i + 1]
                
                let transition = Transition(fromLocation: fromLocation, toLocation: toLocation, fromColor: fromColor, toColor: toColor)
                transitions.append(transition)
            }
        }
    }
    
    private func transitionForPercent(percent: Double) -> Transition? {
        let filtered = transitions.filter { percent >= $0.fromLocation && percent < $0.toLocation }
        let defaultTransition = percent <= 0.5 ? transitions.first : transitions.last
        return filtered.first ?? defaultTransition
    }
    
}

// MARK: - Extensions

private extension Double {
    
    func convertFromRange(min oldMin: Double, max oldMax: Double, toRangeMin newMin: Double, max newMax: Double) -> Double {
        let oldRange, newRange, newValue: Double
        oldRange = (oldMax - oldMin)
        if (oldRange == 0.0) {
            newValue = newMin
        } else {
            newRange = (newMax - newMin)
            newValue = (((self - oldMin) * newRange) / oldRange) + newMin
        }
        return newValue
    }
    
    func convertFromRangeZeroToMax(currentMaxValue: Double, toRangeZeroToMax newMaxValue: Double) -> Double {
        return ((self * newMaxValue) / currentMaxValue)
    }
    
}

private extension UIColor {
    
    struct RGBA {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        init(color: UIColor) {
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        }
    }
    
    var rgba: RGBA {
        return RGBA(color: self)
    }
    
    class func lerp(from from: UIColor.RGBA, to: UIColor.RGBA, percent: CGFloat) -> UIColor {
        let red = from.red + percent * (to.red - from.red)
        let green = from.green + percent * (to.green - from.green)
        let blue = from.blue + percent * (to.blue - from.blue)
        let alpha = from.alpha + percent * (to.alpha - from.alpha)
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
}
