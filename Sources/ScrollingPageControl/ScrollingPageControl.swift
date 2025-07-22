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
        didSet { createViews() }
    }

    open var pages: Int = 0 {
        didSet {
            guard pages != oldValue else { return }
            pages = max(0, pages)
            invalidateIntrinsicContentSize()
            createViews()
        }
    }

    open var selectedPage: Int = 0 {
        didSet {
            guard selectedPage != oldValue else { return }
            selectedPage = max(0, min(selectedPage, pages - 1))
            updateColors()

            // Fix jump logic: if jump too far, adjust offset to center selected page
            let sidePages = (maxDots - centerDots) / 2
            let centerPagesRange = pageOffset...(pageOffset + centerDots - 1)

            if !centerPagesRange.contains(selectedPage) {
                pageOffset = max(0, selectedPage - centerDots / 2)
                if pageOffset + centerDots > pages {
                    pageOffset = max(0, pages - centerDots)
                }
            }
        }
    }

    open var maxDots = 7 {
        didSet {
            maxDots = max(3, maxDots)
            if maxDots % 2 == 0 {
                maxDots += 1
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
            }
            updatePositions()
        }
    }

    open var dotsScale: [CGFloat] = [1, 0.66, 0.33, 0.16]
    open var hiddenDotScale: CGFloat = .zero
    
    open var slideDuration: TimeInterval = 0.15
    open var dotColor = UIColor.lightGray { didSet { updateColors() } }
    open var selectedColor = UIColor.systemBlue { didSet { updateColors() } }
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

    open var contentBackgroundColor: UIColor = .clear {
        didSet { contentView.backgroundColor = contentBackgroundColor }
    }

    open var horizontalPadding: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    private let contentView = UIView()

    private var dotViews: [UIView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            dotViews.forEach { contentView.addSubview($0) }
            updateColors()
            updatePositions()
        }
    }

    private var centerOffset = 0
    private var pageOffset = 0 {
        didSet {
            UIView.animate(withDuration: slideDuration, delay: 0.15, options: [], animations: self.updatePositions, completion: nil)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupContentView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContentView()
    }

    private func setupContentView() {
        contentView.backgroundColor = contentBackgroundColor
        contentView.layer.masksToBounds = true
        addSubview(contentView)
    }

    private func createViews() {
        dotViews = (0..<pages).map { index in
            delegate?.viewForDot(at: index) ?? CircularView(frame: CGRect(origin: .zero, size: CGSize(width: dotSize, height: dotSize)))
        }
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
            if distance > (maxDots / 2) { return hiddenDotScale }
            let index = max(0, min(3, distance - centerDots / 2))
            return dotsScale[index]
        }
        let dotWidths: [CGFloat] = dotScales.enumerated().map { (i, scale) in
            let base = i == selectedPage ? selectedDotSize : dotSize
            return base * scale
        }
        let totalDotsWidth = dotWidths.reduce(0, +) + spacing * CGFloat(dotWidths.count - 1)
        let totalContentWidth = totalDotsWidth + 2 * horizontalPadding
        let horizontalOffset = (bounds.width - totalContentWidth) / 2

        contentView.frame = CGRect(
            x: horizontalOffset,
            y: 0,
            width: totalContentWidth,
            height: bounds.height
        )
        contentView.layer.cornerRadius = bounds.height / 2
        sendSubviewToBack(contentView)

        var x: CGFloat = horizontalPadding
        dotViews.enumerated().forEach { index, dot in
            let scale = dotScales[index]
            let width = dotWidths[index]
            let height = dotSize * scale
            dot.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
            dot.center = CGPoint(x: x + width / 2, y: contentView.bounds.height / 2)
            x += width + spacing
        }
    }

    open override var intrinsicContentSize: CGSize {
        let visiblePages = min(maxDots, pages)
        let totalSpacing = CGFloat(visiblePages - 1) * spacing
        let totalDots = (0..<visiblePages).map { index -> CGFloat in
            index == selectedPage ? selectedDotSize : dotSize
        }.reduce(0, +)
        return CGSize(width: totalDots + totalSpacing + horizontalPadding * 2, height: dotSize)
    }
}

