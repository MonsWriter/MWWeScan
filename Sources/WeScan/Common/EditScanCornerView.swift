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

        image?.draw(in: rect)
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
