//
//  EditScanCornerView.swift
//  WeScan
//
//  Created by Boris Emorine on 3/5/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import CoreImage
import UIKit

/// A UIView used by corners of a quadrilateral that is aware of its position.
final class EditScanCornerView: UIView {

    let position: CornerPosition

    /// The image to display when the corner view is highlighted.
    private var image: UIImage?
    private(set) var isHighlighted = false

    private lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 1.0
        return layer
    }()

    /// Set stroke color of corner layer
    public var strokeColor: CGColor? {
        didSet {
            circleLayer.strokeColor = strokeColor
        }
    }

    /// Set stroke width of corner layer
    public var strokeWidth: CGFloat = 1.0 {
        didSet {
            circleLayer.lineWidth = strokeWidth
            setNeedsDisplay()
        }
    }

    /// Magnification scale for the image inside the corner view
    /// 1.0 = no magnification, 2.0 = 2x zoom, etc.
    public var magnificationScale: CGFloat = 2.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    init(frame: CGRect, position: CornerPosition) {
        self.position = position
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        clipsToBounds = true
        layer.addSublayer(circleLayer)
        circleLayer.lineWidth = strokeWidth
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2.0
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let bezierPath = UIBezierPath(ovalIn: rect.insetBy(dx: strokeWidth, dy: strokeWidth))
        circleLayer.frame = rect
        circleLayer.path = bezierPath.cgPath

        if let image = image {
            drawMagnifiedImage(image, in: rect)
        }
    }

    private func drawMagnifiedImage(_ image: UIImage, in rect: CGRect) {
        guard let cgImage = image.cgImage else {
            image.draw(in: rect)
            return
        }
        
        let imageSize = image.size
        let cornerSize = rect.size
        
        let sourceWidth = cornerSize.width / magnificationScale
        let sourceHeight = cornerSize.height / magnificationScale
        
        let centerX = imageSize.width / 2.0  
        let centerY = imageSize.height / 2.0
        
        let sourceRect = CGRect(
            x: max(0, centerX - sourceWidth / 2),
            y: max(0, centerY - sourceHeight / 2),
            width: min(sourceWidth, imageSize.width),
            height: min(sourceHeight, imageSize.height)
        )
        
        if let croppedCGImage = cgImage.cropping(to: sourceRect) {
            let croppedImage = UIImage(cgImage: croppedCGImage)
            croppedImage.draw(in: rect)
        } else {
            // Fallback
            image.draw(in: rect)
        }
    }

    func highlightWithImage(_ image: UIImage) {
        isHighlighted = true
        self.image = image
        self.setNeedsDisplay()
    }

    func reset() {
        isHighlighted = false
        image = nil
        setNeedsDisplay()
    }

}
