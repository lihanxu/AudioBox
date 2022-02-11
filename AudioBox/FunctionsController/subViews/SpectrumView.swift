//
//  SpectrumView.swift
//  AudioBox
//
//  Created by anker on 2022/2/11.
//

import UIKit

class SpectrumView: UIView {
    private var leftGradientLayer = CAGradientLayer()
    private var rightGradientLayer = CAGradientLayer()
    
    var barWidth: CGFloat = 3.0
    var space: CGFloat = 1.0
    
    private let bottomSpace: CGFloat = 0.0
    private let topSpace: CGFloat = 0.0
    
    var spectra:[[Float]]? {
        didSet {
            drawBezierPath()
        }
    }

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        rightGradientLayer.colors = [UIColor.init(red: 52/255, green: 232/255, blue: 158/255, alpha: 1.0).cgColor,
                                     UIColor.init(red: 15/255, green: 52/255, blue: 67/255, alpha: 1.0).cgColor]
        rightGradientLayer.locations = [0.6, 1.0]
        self.layer.addSublayer(rightGradientLayer)
        
        leftGradientLayer.colors = [UIColor.init(red: 194/255, green: 21/255, blue: 0/255, alpha: 1.0).cgColor,
                                    UIColor.init(red: 255/255, green: 197/255, blue: 0/255, alpha: 1.0).cgColor]
        leftGradientLayer.locations = [0.6, 1.0]
        self.layer.addSublayer(leftGradientLayer)
    }

    private func drawBezierPath() {
        if let spectra = spectra {
            // left channel
            let leftPath = UIBezierPath()
            for (i, amplitude) in spectra[0].enumerated() {
                let x = CGFloat(i) * (barWidth + space) + space
                let y = translateAmplitudeToYPosition(amplitude: amplitude)
                let bar = UIBezierPath(rect: CGRect(x: x, y: y, width: barWidth, height: bounds.height - bottomSpace - y))
                leftPath.append(bar)
            }
            let leftMaskLayer = CAShapeLayer()
            leftMaskLayer.path = leftPath.cgPath
            leftGradientLayer.frame = CGRect(x: 0, y: topSpace, width: bounds.width, height: bounds.height - topSpace - bottomSpace)
            leftGradientLayer.mask = leftMaskLayer
    
            // right channel
            if spectra.count >= 2 {
                let rightPath = UIBezierPath()
                for (i, amplitude) in spectra[1].enumerated() {
                    let x = CGFloat(spectra[1].count - 1 - i) * (barWidth + space) + space
                    let y = translateAmplitudeToYPosition(amplitude: amplitude)
                    let bar = UIBezierPath(rect: CGRect(x: x, y: y, width: barWidth, height: bounds.height - bottomSpace - y))
                    rightPath.append(bar)
                }
                let rightMaskLayer = CAShapeLayer()
                rightMaskLayer.path = rightPath.cgPath
                rightGradientLayer.frame = CGRect(x: 0, y: topSpace, width: bounds.width, height: bounds.height - topSpace - bottomSpace)
                rightGradientLayer.mask = rightMaskLayer
            }
        }
    }
    
    private func translateAmplitudeToYPosition(amplitude: Float) -> CGFloat {
        let barHeight: CGFloat = CGFloat(amplitude) * (bounds.height - bottomSpace - topSpace)
        return bounds.height - bottomSpace - barHeight
    }

}
