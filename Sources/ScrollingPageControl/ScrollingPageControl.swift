//
//  ScrollingPageControl.swift
//  ScrollingPageControl
//
//  Created by Emilio Peláez on 3/10/18.
//

import UIKit

public protocol ScrollingPageControlDelegate: AnyObject {
    func viewForDot(at index: Int) -> UIView?
}

open class ScrollingPageControl: UIView {
    open weak var delegate: ScrollingPageControlDelegate? {
        didSet { createViewsIfNeeded() }
    }

    open var pages: Int = 0 {
        didSet {
            guard pages != oldValue else { return }
            pages = max(0, pages)
            createViewsIfNeeded()
            invalidateIntrinsicContentSize()
        }
    }

    open var selectedPage: Int = 0 {
        didSet {
            let clamped = max(0, min(selectedPage, pages - 1))
            guard clamped != oldValue else { return }
            selectedPage = clamped
            let currentRange = pageOffset..<(pageOffset + centerDots)
            let needsScroll = !currentRange.contains(selectedPage)
            if needsScroll {
                let newOffset = max(0, min(selectedPage - centerDots / 2, pages - centerDots))
                if pageOffset != newOffset {
                    pageOffset = newOffset
                    return
                }
            }
            updateColors()
            updateVisibleDots(animated: true)
        }
    }

    open var maxDots = 7 {
        didSet {
            let fixed = max(3, maxDots | 1)
            guard fixed != maxDots else { return }
            maxDots = fixed
            centerDots = min(centerDots, maxDots)
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    open var centerDots = 3 {
        didSet {
            let fixed = max(1, min(centerDots | 1, maxDots))
            guard fixed != centerDots else { return }
            centerDots = fixed
            setNeedsLayout()
        }
    }

    open var dotsScale: [CGFloat] = [1, 0.66, 0.33, 0.16]
    open var hiddenDotScale: CGFloat = .zero
    open var slideDuration: TimeInterval = 0.15
    open var dotColor = UIColor.lightGray { didSet { updateColors() } }
    open var selectedColor = UIColor.systemBlue { didSet { updateColors() } }
    open var dotSize: CGFloat = 6 { didSet { let s = max(1, dotSize); if dotSize != s { dotSize = s }; setNeedsLayout() } }
    open var selectedDotSize: CGFloat = 10 { didSet { let s = max(1, selectedDotSize); if selectedDotSize != s { selectedDotSize = s }; setNeedsLayout() } }
    open var spacing: CGFloat = 4 { didSet { let s = max(1, spacing); if spacing != s { spacing = s }; setNeedsLayout() } }
    open var contentBackgroundColor: UIColor = .clear { didSet { contentView.backgroundColor = contentBackgroundColor } }
    open var horizontalPadding: CGFloat = 0 { didSet { setNeedsLayout() } }

    private let contentView = UIView()
    private var dotPool: [UIView] = []
    private var dotViews: [UIView?] = []

    private var pageOffset = 0 {
        didSet {
            guard oldValue != pageOffset else { return }
            updateVisibleDots(animated: true)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.clipsToBounds = true
        contentView.backgroundColor = contentBackgroundColor
        addSubview(contentView)
    }

    private func createViewsIfNeeded() {
        guard dotViews.count != pages else { return }

        for view in dotViews.compactMap({ $0 }) {
            view.removeFromSuperview()
            dotPool.append(view)
        }

        dotViews = (0..<pages).map { index in dequeueDot(for: index) }
        updateColors()
        setNeedsLayout()
    }

    private func dequeueDot(for index: Int) -> UIView {
        let view = delegate?.viewForDot(at: index) ?? dotPool.popLast() ?? CircularView()
        view.isHidden = true
        contentView.addSubview(view)
        return view
    }

    private func updateColors() {
        for (index, dot) in dotViews.enumerated() {
            dot?.tintColor = (index == selectedPage ? selectedColor : dotColor)
        }
    }

    private func updateVisibleDots(animated: Bool) {
        guard bounds.width > 0 else { return }

        let start = pageOffset
        let end = min(pages, pageOffset + maxDots)
        let range = start..<end

        var dotWidths: [CGFloat] = []
        var scales: [CGFloat] = []

        for i in range {
            let isEdgeDot = (i == range.lowerBound && pageOffset > 0) || (i == range.upperBound - 1 && range.upperBound < pages)
            let scale = isEdgeDot ? (dotsScale[safe: 1] ?? 0.66) : 1.0
            let baseSize = i == selectedPage ? selectedDotSize : dotSize
            scales.append(scale)
            dotWidths.append(baseSize * scale)
        }

        let totalWidth = dotWidths.reduce(0, +) + spacing * CGFloat(dotWidths.count - 1)
        let startX = (contentView.bounds.width - totalWidth) / 2
        let contentWidth = totalWidth + horizontalPadding * 2
        let contentX = (bounds.width - contentWidth) / 2
        contentView.frame = CGRect(x: contentX, y: 0, width: contentWidth, height: bounds.height)
        contentView.layer.cornerRadius = bounds.height / 2

        var x = startX
        for (offset, i) in range.enumerated() {
            guard let dot = dotViews[i] else { continue }
            let width = dotWidths[offset]
            let height = dotSize * scales[offset]
            let center = CGPoint(x: x + width / 2, y: contentView.bounds.height / 2)

            dot.isHidden = false

            let frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))

            if animated {
                UIView.animate(withDuration: slideDuration, delay: 0, options: [.curveEaseInOut], animations: {
                    dot.frame = frame
                    dot.center = center
                })
            } else {
                dot.frame = frame
                dot.center = center
            }

            x += width + spacing
        }

        for i in 0..<pages where !range.contains(i) {
            dotViews[i]?.isHidden = true
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        updateVisibleDots(animated: false)
        updateVisibleDots(animated: false)
    }
    
    override open var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: max(dotSize, selectedDotSize))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// - backup _ 1
//public protocol ScrollingPageControlDelegate: AnyObject {
//    func viewForDot(at index: Int) -> UIView?
//}
//
//
//open class ScrollingPageControl: UIView {
//    open weak var delegate: ScrollingPageControlDelegate? {
//        didSet { createViewsIfNeeded() }
//    }
//
//    open var pages: Int = 0 {
//        didSet {
//            guard pages != oldValue else { return }
//            pages = max(0, pages)
//            createViewsIfNeeded()
//            invalidateIntrinsicContentSize()
//        }
//    }
//
//    open var selectedPage: Int = 0 {
//        didSet {
//            let clamped = max(0, min(selectedPage, pages - 1))
//            guard clamped != oldValue else { return }
//            selectedPage = clamped
//
//            let currentRange = pageOffset..<(pageOffset + centerDots)
//            let needsScroll = !currentRange.contains(selectedPage)
//
//            if needsScroll {
//                let newOffset = max(0, min(selectedPage - centerDots / 2, pages - centerDots))
//                if pageOffset != newOffset {
//                    pageOffset = newOffset
//                } else {
//                    updateColors()
//                    updateVisibleDots(animated: true)
//                }
//            } else {
//                updateColors()
//                updateVisibleDots(animated: true)
//            }
//        }
//    }
//
//    open var maxDots = 7 {
//        didSet {
//            maxDots = max(3, maxDots | 1)
//            centerDots = min(centerDots, maxDots)
//            invalidateIntrinsicContentSize()
//            layoutIfNeeded(); updateVisibleDots(animated: false)
//        }
//    }
//
//    open var centerDots = 3 {
//        didSet {
//            centerDots = max(1, min(centerDots | 1, maxDots))
//            updateVisibleDots(animated: false)
//        }
//    }
//
//    open var dotsScale: [CGFloat] = [1, 0.66, 0.33, 0.16]
//    open var hiddenDotScale: CGFloat = .zero
//    open var slideDuration: TimeInterval = 0.15
//    open var dotColor = UIColor.lightGray { didSet { updateColors() } }
//    open var selectedColor = UIColor.systemBlue { didSet { updateColors() } }
//    open var dotSize: CGFloat = 6 { didSet { dotSize = max(1, dotSize); updateVisibleDots(animated: false) } }
//    open var selectedDotSize: CGFloat = 10 { didSet { selectedDotSize = max(1, selectedDotSize); updateVisibleDots(animated: false) } }
//    open var spacing: CGFloat = 4 { didSet { spacing = max(1, spacing); updateVisibleDots(animated: false) } }
//    open var contentBackgroundColor: UIColor = .clear { didSet { contentView.backgroundColor = contentBackgroundColor } }
//    open var horizontalPadding: CGFloat = 0 { didSet { layoutIfNeeded() } }
//
//    private let contentView = UIView()
//    private var dotPool: [UIView] = []
//    private var dotViews: [UIView?] = []
//
//    private var pageOffset = 0 {
//        didSet { updateVisibleDots(animated: true) }
//    }
//
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        setup()
//        setNeedsLayout()
//
//    }
//
//    public required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setup()
//        setNeedsLayout()
//
//    }
//
//    private func setup() {
//        contentView.clipsToBounds = true
//        contentView.backgroundColor = contentBackgroundColor
//        addSubview(contentView)
//    }
//
//    private func createViewsIfNeeded() {
//        if dotViews.count == pages { return }
//
//        for view in dotViews.compactMap({ $0 }) {
//            view.removeFromSuperview()
//            dotPool.append(view)
//        }
//
//        dotViews = (0..<pages).map { index in
//            let dot = dequeueDot(for: index)
//            return dot
//        }
//
//        updateColors()
//        updateVisibleDots(animated: false)
//    }
//
//    private func dequeueDot(for index: Int) -> UIView {
//        let view: UIView = delegate?.viewForDot(at: index) ?? dotPool.popLast() ?? CircularView()
//        view.isHidden = true
//        contentView.addSubview(view)
//        return view
//    }
//
//    private func updateColors() {
//        for (index, dot) in dotViews.enumerated() where dot != nil {
//            dot?.tintColor = index == selectedPage ? selectedColor : dotColor
//        }
//    }
//
//    private func updateVisibleDots(animated: Bool) {
//        guard bounds.width > 0 else { return }
//
//        let sidePages = (maxDots - centerDots) / 2
//
//        let start = pageOffset
//        let end = min(pages, pageOffset + maxDots)
//        let range = start..<end
//
//        var dotWidths: [CGFloat] = []
//        var scales: [CGFloat] = []
//
//        for i in range {
//            let isFirstVisible = i == range.lowerBound
//            let isLastVisible = i == range.upperBound - 1
//            let hasDotsBefore = range.lowerBound > 0
//            let hasDotsAfter = range.upperBound < pages
//
//            var scale: CGFloat = 1.0
//            if isFirstVisible && hasDotsBefore {
//                scale = dotsScale.count > 1 ? dotsScale[1] : 0.66
//            } else if isLastVisible && hasDotsAfter {
//                scale = dotsScale.count > 1 ? dotsScale[1] : 0.66
//            }
//
//            let baseSize: CGFloat = i == selectedPage ? selectedDotSize : dotSize
//            scales.append(scale)
//            dotWidths.append(baseSize * scale)
//        }
//
//        let totalWidth = dotWidths.reduce(0, +) + CGFloat(dotWidths.count - 1) * spacing
//        let startX = (contentView.bounds.width - totalWidth) / 2
//
//        let contentWidth = totalWidth + horizontalPadding * 2
//        let contentX = (bounds.width - contentWidth) / 2
//        contentView.frame = CGRect(x: contentX, y: 0, width: contentWidth, height: bounds.height)
//        contentView.layer.cornerRadius = bounds.height / 2
//
//        var x = startX
//        for (offset, i) in range.enumerated() {
//            guard let dot = dotViews[i] else { continue }
//            let width = dotWidths[offset]
//            let scale = scales[offset]
//            let height = dotSize * scale
//            let frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
//            let center = CGPoint(x: x + width / 2, y: contentView.bounds.height / 2)
//
//            dot.isHidden = false
//
//            if animated {
//                UIView.animate(withDuration: slideDuration, delay: 0, options: [.curveEaseInOut], animations: {
//                    dot.frame = frame
//                    dot.center = center
//                })
//            } else {
//                dot.frame = frame
//                dot.center = center
//            }
//
//            x += width + spacing
//        }
//
//        for i in 0..<pages where !range.contains(i) {
//            dotViews[i]?.isHidden = true
//        }
//    }
//
//    override open func layoutSubviews() {
//        super.layoutSubviews()
//        updateVisibleDots(animated: false)
//        updateVisibleDots(animated: false)
//    }
//
//    override open var intrinsicContentSize: CGSize {
//        return CGSize(width: UIView.noIntrinsicMetric, height: max(dotSize, selectedDotSize))
//    }
//}





// - backup _ 22
//public protocol ScrollingPageControlDelegate: AnyObject {
//    //    If delegate is nil or the implementation returns nil for a given dot, the default
//    //    circle will be used. Returned views should react to having their tint color changed
//    func viewForDot(at index: Int) -> UIView?
//}
//
//open class ScrollingPageControl: UIView {
//    open weak var delegate: ScrollingPageControlDelegate? {
//        didSet { createViews() }
//    }
//
//    open var pages: Int = 0 {
//        didSet {
//            guard pages != oldValue else { return }
//            pages = max(0, pages)
//            invalidateIntrinsicContentSize()
//            createViews()
//        }
//    }
//
//    open var selectedPage: Int = 0 {
//        didSet {
//            guard selectedPage != oldValue else { return }
//            selectedPage = max(0, min(selectedPage, pages - 1))
//            updateColors()
//
//            // Fix jump logic: if jump too far, adjust offset to center selected page
//            let sidePages = (maxDots - centerDots) / 2
//            let centerPagesRange = pageOffset...(pageOffset + centerDots - 1)
//
//            if !centerPagesRange.contains(selectedPage) {
//                pageOffset = max(0, selectedPage - centerDots / 2)
//                if pageOffset + centerDots > pages {
//                    pageOffset = max(0, pages - centerDots)
//                }
//            }
//        }
//    }
//
//    open var maxDots = 7 {
//        didSet {
//            maxDots = max(3, maxDots)
//            if maxDots % 2 == 0 {
//                maxDots += 1
//            }
//            invalidateIntrinsicContentSize()
//            updatePositions()
//        }
//    }
//
//    open var centerDots = 3 {
//        didSet {
//            centerDots = max(1, centerDots)
//            if centerDots % 2 == 0 {
//                centerDots += 1
//            }
//            updatePositions()
//        }
//    }
//
//    open var dotsScale: [CGFloat] = [1, 0.66, 0.33, 0.16]
//    open var hiddenDotScale: CGFloat = .zero
//    
//    open var slideDuration: TimeInterval = 0.15
//    open var dotColor = UIColor.lightGray { didSet { updateColors() } }
//    open var selectedColor = UIColor.systemBlue { didSet { updateColors() } }
//    open var dotSize: CGFloat = 6 {
//        didSet {
//            dotSize = max(1, dotSize)
//            dotViews.forEach { $0.frame = CGRect(origin: .zero, size: CGSize(width: dotSize, height: dotSize)) }
//            updatePositions()
//        }
//    }
//    open var selectedDotSize: CGFloat = 10 {
//        didSet {
//            selectedDotSize = max(1, selectedDotSize)
//            updatePositions()
//        }
//    }
//    open var spacing: CGFloat = 4 {
//        didSet {
//            spacing = max(1, spacing)
//            updatePositions()
//        }
//    }
//
//    open var contentBackgroundColor: UIColor = .clear {
//        didSet { contentView.backgroundColor = contentBackgroundColor }
//    }
//
//    open var horizontalPadding: CGFloat = 0 {
//        didSet { setNeedsLayout() }
//    }
//
//    private let contentView = UIView()
//
//    private var dotViews: [UIView] = [] {
//        didSet {
//            oldValue.forEach { $0.removeFromSuperview() }
//            dotViews.forEach { contentView.addSubview($0) }
//            updateColors()
//            updatePositions()
//        }
//    }
//
//    private var centerOffset = 0
//    private var pageOffset = 0 {
//        didSet {
//            UIView.animate(withDuration: slideDuration, delay: 0.15, options: [], animations: self.updatePositions, completion: nil)
//        }
//    }
//
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupContentView()
//    }
//
//    public required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupContentView()
//    }
//
//    private func setupContentView() {
//        contentView.backgroundColor = contentBackgroundColor
//        contentView.layer.masksToBounds = true
//        addSubview(contentView)
//    }
//
//    private func createViews() {
//        dotViews = (0..<pages).map { index in
//            delegate?.viewForDot(at: index) ?? CircularView(frame: CGRect(origin: .zero, size: CGSize(width: dotSize, height: dotSize)))
//        }
//    }
//
//    private var lastSize = CGSize.zero
//    open override func layoutSubviews() {
//        super.layoutSubviews()
//        guard bounds.size != lastSize else { return }
//        lastSize = bounds.size
//        updatePositions()
//    }
//
//    private func updateColors() {
//        dotViews.enumerated().forEach { page, dot in
//            dot.tintColor = page == selectedPage ? selectedColor : dotColor
//        }
//    }
//
//    private func updatePositions() {
//        let sidePages = (maxDots - centerDots) / 2
//        let centerPage = centerDots / 2 + pageOffset
//        let dotScales: [CGFloat] = (0..<dotViews.count).map { page in
//            let distance = abs(page - centerPage)
//            if distance > (maxDots / 2) { return hiddenDotScale }
//            let index = max(0, min(3, distance - centerDots / 2))
//            return dotsScale[index]
//        }
//        let dotWidths: [CGFloat] = dotScales.enumerated().map { (i, scale) in
//            let base = i == selectedPage ? selectedDotSize : dotSize
//            return base * scale
//        }
//        let totalDotsWidth = dotWidths.reduce(0, +) + spacing * CGFloat(dotWidths.count - 1)
//        let totalContentWidth = totalDotsWidth + 2 * horizontalPadding
//        let horizontalOffset = (bounds.width - totalContentWidth) / 2
//
//        contentView.frame = CGRect(
//            x: horizontalOffset,
//            y: 0,
//            width: totalContentWidth,
//            height: bounds.height
//        )
//        contentView.layer.cornerRadius = bounds.height / 2
//        sendSubviewToBack(contentView)
//
//        var x: CGFloat = horizontalPadding
//        dotViews.enumerated().forEach { index, dot in
//            let scale = dotScales[index]
//            let width = dotWidths[index]
//            let height = dotSize * scale
//            dot.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
//            dot.center = CGPoint(x: x + width / 2, y: contentView.bounds.height / 2)
//            x += width + spacing
//        }
//    }
//
//    open override var intrinsicContentSize: CGSize {
//        let visiblePages = min(maxDots, pages)
//        let totalSpacing = CGFloat(visiblePages - 1) * spacing
//        let totalDots = (0..<visiblePages).map { index -> CGFloat in
//            index == selectedPage ? selectedDotSize : dotSize
//        }.reduce(0, +)
//        return CGSize(width: totalDots + totalSpacing + horizontalPadding * 2, height: dotSize)
//    }
//}

