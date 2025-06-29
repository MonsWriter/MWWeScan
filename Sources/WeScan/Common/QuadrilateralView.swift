//
//  RectangleView.swift
//  WeScan
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

/// Simple enum to keep track of the position of the corners of a quadrilateral.
enum CornerPosition {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
}

/// The `QuadrilateralView` is a simple `UIView` subclass that can draw a quadrilateral, and optionally edit it.
public final class QuadrilateralView: UIView {

    private let quadLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 1.0
        layer.opacity = 1.0
        layer.isHidden = true

        return layer
    }()

    /// We want the corner views to be displayed under the outline of the quadrilateral.
    /// Because of that, we need the quadrilateral to be drawn on a UIView above them.
    private let quadView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// The quadrilateral drawn on the view.
    private(set) var quad: Quadrilateral?

    public var editable = false {
        didSet {
            cornerViews(hidden: !editable)
            quadLayer.fillColor = editable ? UIColor(white: 0.0, alpha: 0.6).cgColor : UIColor(white: 1.0, alpha: 0.5).cgColor
            guard let quad else {
                return
            }
            drawQuad(quad, animated: false)
            layoutCornerViews(forQuad: quad)
        }
    }

    /// Show screen borders when in editable mode
    public var showScreenBorders: Bool = false {
        didSet {
            if let quad = quad {
                drawQuad(quad, animated: false)
            }
        }
    }

    /// Set corner view stroke width
    public var cornerStrokeWidth: CGFloat = 1.0 {
        didSet {
            updateCornerStrokeWidths()
        }
    }

    /// Set stroke color of image rect and corner.
    public var strokeColor: CGColor? {
        didSet {
            quadLayer.strokeColor = strokeColor
            quadLayer.lineWidth = strokeWidth
            topLeftCornerView.strokeColor = strokeColor
            topRightCornerView.strokeColor = strokeColor
            bottomRightCornerView.strokeColor = strokeColor
            bottomLeftCornerView.strokeColor = strokeColor
            updateCornerStrokeWidths()
            updateCornerMagnificationScales()
        }
    }

    /// Set stroke width of image rect and corner.
    public var strokeWidth: CGFloat = 2.0 {
        didSet {
            quadLayer.lineWidth = strokeWidth
        }
    }

    /// Set corner view size (both normal and highlighted will be proportionally adjusted)
    public var cornerSize: CGFloat = 25.0 {
        didSet {
            updateCornerViewSizes()
            if let quad = quad {
                layoutCornerViews(forQuad: quad)
            }
        }
    }

    /// Set highlighted corner view size
    public var highlightedCornerSize: CGFloat = 85.0 {
        didSet {
            
        }
    }

    /// Set magnification scale for corner views
    public var magnificationScale: CGFloat = 2.0 {
        didSet {
            updateCornerMagnificationScales()
        }
    }

    private var cornerViewSize: CGSize {
        return CGSize(width: cornerSize, height: cornerSize)
    }

    private var highlightedCornerViewSize: CGSize {
        return CGSize(width: highlightedCornerSize, height: highlightedCornerSize)
    }

    private var isHighlighted = false {
        didSet (oldValue) {
            guard oldValue != isHighlighted else {
                return
            }
            quadLayer.fillColor = isHighlighted ? UIColor.clear.cgColor : UIColor(white: 0.0, alpha: 0.6).cgColor
            if isHighlighted {
                bringSubviewToFront(quadView)
            } else {
                sendSubviewToBack(quadView)
            }
        }
    }

    private lazy var topLeftCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: cornerViewSize), position: .topLeft)
    }()

    private lazy var topRightCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: cornerViewSize), position: .topRight)
    }()

    private lazy var bottomRightCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: cornerViewSize), position: .bottomRight)
    }()

    private lazy var bottomLeftCornerView: EditScanCornerView = {
        return EditScanCornerView(frame: CGRect(origin: .zero, size: cornerViewSize), position: .bottomLeft)
    }()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        addSubview(quadView)
        setupCornerViews()
        setupConstraints()
        quadView.layer.addSublayer(quadLayer)
        quadLayer.lineWidth = strokeWidth
    }

    private func setupConstraints() {
        let quadViewConstraints = [
            quadView.topAnchor.constraint(equalTo: topAnchor),
            quadView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomAnchor.constraint(equalTo: quadView.bottomAnchor),
            trailingAnchor.constraint(equalTo: quadView.trailingAnchor)
        ]

        NSLayoutConstraint.activate(quadViewConstraints)
    }

    private func setupCornerViews() {
        addSubview(topLeftCornerView)
        addSubview(topRightCornerView)
        addSubview(bottomRightCornerView)
        addSubview(bottomLeftCornerView)
        updateCornerStrokeWidths()
        updateCornerMagnificationScales()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard quadLayer.frame != bounds else {
            return
        }

        quadLayer.frame = bounds
        if let quad {
            drawQuadrilateral(quad: quad, animated: false)
        }
    }

    // MARK: - Drawings

    /// Draws the passed in quadrilateral.
    ///
    /// - Parameters:
    ///   - quad: The quadrilateral to draw on the view. It should be in the coordinates of the current `QuadrilateralView` instance.
    func drawQuadrilateral(quad: Quadrilateral, animated: Bool) {
        self.quad = quad
        drawQuad(quad, animated: animated)
        if editable {
            cornerViews(hidden: false)
            layoutCornerViews(forQuad: quad)
        }
    }

    private func drawQuad(_ quad: Quadrilateral, animated: Bool) {
        var path = quad.path

        if editable && showScreenBorders {
            path = path.reversing()
            let rectPath = UIBezierPath(rect: bounds)
            path.append(rectPath)
        } else if editable {
            quadLayer.fillColor = UIColor(white: 0.0, alpha: 0.6).cgColor
        }

        if animated == true {
            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.duration = 0.2
            quadLayer.add(pathAnimation, forKey: "path")
        }

        quadLayer.path = path.cgPath
        quadLayer.isHidden = false
    }

    private func layoutCornerViews(forQuad quad: Quadrilateral) {
        topLeftCornerView.center = quad.topLeft
        topRightCornerView.center = quad.topRight
        bottomLeftCornerView.center = quad.bottomLeft
        bottomRightCornerView.center = quad.bottomRight
    }

    func removeQuadrilateral() {
        quadLayer.path = nil
        quadLayer.isHidden = true
    }

    /// Updates the size of all corner views to match the current cornerSize setting
    private func updateCornerViewSizes() {
        let newSize = cornerViewSize
    
        topLeftCornerView.frame.size = newSize
        topRightCornerView.frame.size = newSize
        bottomRightCornerView.frame.size = newSize
        bottomLeftCornerView.frame.size = newSize
    
        topLeftCornerView.setNeedsDisplay()
        topRightCornerView.setNeedsDisplay()
        bottomRightCornerView.setNeedsDisplay()
        bottomLeftCornerView.setNeedsDisplay()
    }

    /// Updates the stroke width of all corner views
    private func updateCornerStrokeWidths() {
        topLeftCornerView.strokeWidth = cornerStrokeWidth
        topRightCornerView.strokeWidth = cornerStrokeWidth
        bottomRightCornerView.strokeWidth = cornerStrokeWidth
        bottomLeftCornerView.strokeWidth = cornerStrokeWidth
    }

    // MARK: - Actions

    func moveCorner(cornerView: EditScanCornerView, atPoint point: CGPoint) {
        guard let quad else {
            return
        }

        let validPoint = self.validPoint(point, forCornerViewOfSize: cornerView.bounds.size, inView: self)

        cornerView.center = validPoint
        let updatedQuad = update(quad, withPosition: validPoint, forCorner: cornerView.position)

        self.quad = updatedQuad
        drawQuad(updatedQuad, animated: false)
    }

    func highlightCornerAtPosition(position: CornerPosition, with image: UIImage) {
        guard editable else {
            return
        }
        isHighlighted = true

        let cornerView = cornerViewForCornerPosition(position: position)
        guard cornerView.isHighlighted == false else {
            cornerView.highlightWithImage(image)
            return
        }

        let origin = CGPoint(x: cornerView.frame.origin.x - (highlightedCornerViewSize.width - cornerViewSize.width) / 2.0,
                             y: cornerView.frame.origin.y - (highlightedCornerViewSize.height - cornerViewSize.height) / 2.0)
        cornerView.frame = CGRect(origin: origin, size: highlightedCornerViewSize)
        cornerView.highlightWithImage(image)
    }

    func resetHighlightedCornerViews() {
        isHighlighted = false
        resetHighlightedCornerViews(cornerViews: [topLeftCornerView, topRightCornerView, bottomLeftCornerView, bottomRightCornerView])
    }

    private func resetHighlightedCornerViews(cornerViews: [EditScanCornerView]) {
        cornerViews.forEach { cornerView in
            resetHighlightedCornerView(cornerView: cornerView)
        }
    }

    private func resetHighlightedCornerView(cornerView: EditScanCornerView) {
        cornerView.reset()
        let origin = CGPoint(x: cornerView.frame.origin.x + (cornerView.frame.size.width - cornerViewSize.width) / 2.0,
                             y: cornerView.frame.origin.y + (cornerView.frame.size.height - cornerViewSize.width) / 2.0)
        cornerView.frame = CGRect(origin: origin, size: cornerViewSize)
        cornerView.setNeedsDisplay()
    }

    // MARK: Validation

    /// Ensures that the given point is valid - meaning that it is within the bounds of the passed in `UIView`.
    ///
    /// - Parameters:
    ///   - point: The point that needs to be validated.
    ///   - cornerViewSize: The size of the corner view representing the given point.
    ///   - view: The view which should include the point.
    /// - Returns: A new point which is within the passed in view.
    private func validPoint(_ point: CGPoint, forCornerViewOfSize cornerViewSize: CGSize, inView view: UIView) -> CGPoint {
        var validPoint = point

        if point.x > view.bounds.width {
            validPoint.x = view.bounds.width
        } else if point.x < 0.0 {
            validPoint.x = 0.0
        }

        if point.y > view.bounds.height {
            validPoint.y = view.bounds.height
        } else if point.y < 0.0 {
            validPoint.y = 0.0
        }

        return validPoint
    }

    // MARK: - Convenience

    private func cornerViews(hidden: Bool) {
        topLeftCornerView.isHidden = hidden
        topRightCornerView.isHidden = hidden
        bottomRightCornerView.isHidden = hidden
        bottomLeftCornerView.isHidden = hidden
    }

    private func update(_ quad: Quadrilateral, withPosition position: CGPoint, forCorner corner: CornerPosition) -> Quadrilateral {
        var quad = quad

        switch corner {
        case .topLeft:
            quad.topLeft = position
        case .topRight:
            quad.topRight = position
        case .bottomRight:
            quad.bottomRight = position
        case .bottomLeft:
            quad.bottomLeft = position
        }

        return quad
    }

    /// Updates the magnification scale of all corner views
    private func updateCornerMagnificationScales() {
        topLeftCornerView.magnificationScale = magnificationScale
        topRightCornerView.magnificationScale = magnificationScale
        bottomRightCornerView.magnificationScale = magnificationScale
        bottomLeftCornerView.magnificationScale = magnificationScale
    }

    func cornerViewForCornerPosition(position: CornerPosition) -> EditScanCornerView {
        switch position {
        case .topLeft:
            return topLeftCornerView
        case .topRight:
            return topRightCornerView
        case .bottomLeft:
            return bottomLeftCornerView
        case .bottomRight:
            return bottomRightCornerView
        }
    }
}
