//
//  ScrollingPageControl.swift
//  ScrollingPageControl
//
//  Created by Emilio Peláez on 3/10/18.
//

import UIKit

public protocol ScrollingPageControlDelegate: AnyObject {
    //    If delegate is nil or the implementation returns nil for a given dot, the default
    //    circle will be used. Returned views should react to having their tint color changed
    func viewForDot(at index: Int) -> UIView?
}

open class ScrollingPageControl: UIView {
    open weak var delegate: ScrollingPageControlDelegate? {
        didSet {
            createViews()
        }
    }

    open var pages: Int = 0 {
        didSet {
            guard pages != oldValue else { return }
            pages = max(0, pages)
            invalidateIntrinsicContentSize()
            createViews()
        }
    }
    private func createViews() {
        dotViews = (0..<pages).map { index in
            delegate?.viewForDot(at: index) ?? CircularView(frame: CGRect(origin: .zero, size: CGSize(width: dotSize, height: dotSize)))
        }
    }
    open var selectedPage: Int = 0 {
        didSet {
            guard selectedPage != oldValue else { return }
            selectedPage = max(0, min (selectedPage, pages - 1))
            updateColors()
            if (0..<centerDots).contains(selectedPage - pageOffset) {
                centerOffset = selectedPage - pageOffset
            } else {
                pageOffset = selectedPage - centerOffset
            }
        }
    }
    open var maxDots = 7 {
        didSet {
            maxDots = max(3, maxDots)
            if maxDots % 2 == 0 {
                maxDots += 1
                print("maxPages has to be an odd number")
            }
            invalidateIntrinsicContentSize()
            updatePositions()
        }
    }
    open var centerDots = 3 {
        didSet {
            centerDots = max(1, centerDots)
            if centerDots % 2 == 0 {
                centerDots += 1
                print("centerDots has to be an odd number")
            }
            updatePositions()
        }
    }
    open var slideDuration: TimeInterval = 0.15
    private var centerOffset = 0
    private var pageOffset = 0 {
        didSet {
            UIView.animate(withDuration: slideDuration, delay: 0.15, options: [], animations: self.updatePositions, completion: nil)
        }
    }

    private var dotViews: [UIView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            dotViews.forEach(addSubview)
            updateColors()
            updatePositions()
        }
    }

    open var dotColor = UIColor.lightGray { didSet { updateColors() } }
    open var selectedColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1) { didSet { updateColors() } }
    open var dotSize: CGFloat = 6 {
        didSet {
            dotSize = max(1, dotSize)
            dotViews.forEach { $0.frame = CGRect(origin: .zero, size: CGSize(width: dotSize, height: dotSize)) }
            updatePositions()
        }
    }

    open var selectedDotSize: CGFloat = 10 {
        didSet {
            selectedDotSize = max(1, selectedDotSize)
            updatePositions()
        }
    }

    open var spacing: CGFloat = 4 {
        didSet {
            spacing = max(1, spacing)
            updatePositions()
        }
    }

    public init() {
        super.init(frame: .zero)
        isOpaque = false
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }

    private var lastSize = CGSize.zero
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastSize else { return }
        lastSize = bounds.size
        updatePositions()
    }

    private func updateColors() {
        dotViews.enumerated().forEach { page, dot in
            dot.tintColor = page == selectedPage ? selectedColor : dotColor
        }
    }

    private func updatePositions() {
        let sidePages = (maxDots - centerDots) / 2
        let centerPage = centerDots / 2 + pageOffset
        let dotScales: [CGFloat] = (0..<dotViews.count).map { page in
            let distance = abs(page - centerPage)
            if distance > (maxDots / 2) { return 0 }
            let index = max(0, min(3, distance - centerDots / 2))
            return [1, 0.66, 0.33, 0.16][index]
        }
        let dotWidths: [CGFloat] = dotScales.enumerated().map { (i, scale) in
            let base = i == selectedPage ? selectedDotSize : dotSize
            return base * scale
        }
        let totalWidth = dotWidths.reduce(0, +) + spacing * CGFloat(dotWidths.count - 1)
        let horizontalOffset = (bounds.width - totalWidth) / 2

        var x: CGFloat = horizontalOffset
        dotViews.enumerated().forEach { index, dot in
            let scale = dotScales[index]
            let width = dotWidths[index]
            let height = dotSize * scale
            dot.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
            dot.center = CGPoint(x: x + width / 2, y: bounds.midY)
            x += width + spacing
        }
    }

    open override var intrinsicContentSize: CGSize {
        let visiblePages = min(maxDots, pages)
        let totalSpacing = CGFloat(visiblePages - 1) * spacing
        let totalDots = (0..<visiblePages).map { index -> CGFloat in
            index == selectedPage ? selectedDotSize : dotSize
        }.reduce(0, +)
        return CGSize(width: totalDots + totalSpacing, height: dotSize)
    }
}
