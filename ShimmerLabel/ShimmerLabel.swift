//
//  TCShimmerLabel.swift
//  game_werewolf
//
//  Created by doudianyu on 2021/8/8.
//  Copyright © 2021 orangelab. All rights reserved.
//

import UIKit

/// 辉光效果文本
final class ShimmerLabel: UILabel {
    /// 配置
    struct Config: Equatable {
        /// 动画样式[默认 indicatorMove]
        var shimmerStyle: ShimmerStyle = .none
        /// 是否重复[默认true]
        var shimmerRepeat: Bool = true
        /// 闪烁主体宽度[默认20]
        var shimmerWidth: CGFloat = 20
        /// 闪烁半径[默认5]
        var shimmerRadius: CGFloat = 5
        /// 闪烁颜色[默认red]
        var shimmerColor: UIColor = UIColor.red
        /// 炫彩字
        var shimmerColorArray: [UIColor] = []
        /// 周期[默认2s, 周期和速度同时设定则优先速度]
        var shimmerDuration: TimeInterval = 2
        /// 速度[周期和速度同时设定则优先速度]
        var shimmerSpeed: CGFloat? = 30
        /// 是否需要渐隐
        var blink: Bool = false
        
        static func == (lhs: ShimmerLabel.Config, rhs: ShimmerLabel.Config) -> Bool {
            guard lhs.shimmerStyle == rhs.shimmerStyle else { return false }
            guard lhs.shimmerRepeat == rhs.shimmerRepeat else { return false }
            guard lhs.shimmerWidth == rhs.shimmerWidth else { return false }
            guard lhs.shimmerRadius == rhs.shimmerRadius else { return false }
            guard lhs.shimmerColor == rhs.shimmerColor else { return false }
            guard lhs.shimmerColorArray.count == rhs.shimmerColorArray.count else { return false }
            guard lhs.shimmerDuration == rhs.shimmerDuration else { return false }
            guard lhs.shimmerSpeed == rhs.shimmerSpeed else { return false }
            guard lhs.blink == rhs.blink else { return false }
            return zip(lhs.shimmerColorArray, rhs.shimmerColorArray).first(where: { $0 != $1 }) == nil
        }
    }
    enum ShimmerStyle {
        /// 指示器移动效果
        case indicatorMove
        /// 指示器反复移动效果
        case indicatorMoveReverse
        /// 文本颜色流动效果
        case colorsFlow
        /// 文本颜色变换效果
        case colorsChange
        /// 无效果
        case none
    }
    
    /// 是否正在执行
    private var shimmerIsPlaying: Bool = false
    /// 配置
    private lazy var shimmerConfig: ShimmerLabel.Config = ShimmerLabel.Config()
    /// 遮罩label
    private lazy var shimmerLabel: UILabel = UILabel()
    /// 变化layer
    private lazy var shimmerLayer: CAGradientLayer = CAGradientLayer()
    /// 上一次的size
    private lazy var shimmerLastSize: CGSize = CGSize.zero
    
    private var _text: String?
    private var _textColor: UIColor = .black
    private var _attributedText: NSAttributedString?
    
    // MARK: - 一些必要属性保持一致性
    @objc public override var text: String? {
        get { super.text }
        set {
            guard _text != newValue else { return }
            _text = newValue
            
            if shimmerIsPlaying {
                stopShimmer()
            }
            super.text = newValue
            shimmerLabel.text = newValue
            delayRefresh()
        }
    }
    @objc public override var font: UIFont! {
        get { super.font }
        set { shimmerLabel.font = newValue; super.font = newValue; delayRefresh() }
    }
    @objc public override var textAlignment: NSTextAlignment {
        get { super.textAlignment }
        set { shimmerLabel.textAlignment = newValue; super.textAlignment = newValue; delayRefresh() }
    }
    @objc public override var lineBreakMode: NSLineBreakMode {
        get { super.lineBreakMode }
        set { shimmerLabel.lineBreakMode = newValue; super.lineBreakMode = newValue; delayRefresh() }
    }
    @objc public override var attributedText: NSAttributedString? {
        get { _attributedText }
        set {
            guard _attributedText != newValue else { return }
            _attributedText = newValue
            
            if shimmerIsPlaying {
               stopShimmer()
            }
            super.attributedText = newValue
            shimmerLabel.attributedText = newValue
            delayRefresh()
        }
    }
    @objc public override var numberOfLines: Int {
        get { super.numberOfLines }
        set { shimmerLabel.numberOfLines = newValue; super.numberOfLines = newValue; delayRefresh() }
    }
    @objc public override var adjustsFontSizeToFitWidth: Bool {
        get { super.adjustsFontSizeToFitWidth }
        set { shimmerLabel.adjustsFontSizeToFitWidth = newValue; super.adjustsFontSizeToFitWidth = newValue; delayRefresh() }
    }
    @objc public override var baselineAdjustment: UIBaselineAdjustment {
        get { super.baselineAdjustment }
        set { shimmerLabel.baselineAdjustment = newValue; super.baselineAdjustment = newValue; delayRefresh() }
    }
    @objc public override var minimumScaleFactor: CGFloat {
        get { super.minimumScaleFactor }
        set { shimmerLabel.minimumScaleFactor = newValue; super.minimumScaleFactor = newValue; delayRefresh() }
    }
    @objc public override var allowsDefaultTighteningForTruncation: Bool {
        get { super.allowsDefaultTighteningForTruncation }
        set { shimmerLabel.allowsDefaultTighteningForTruncation = newValue; super.allowsDefaultTighteningForTruncation = newValue; delayRefresh() }
    }
    @available(iOS 14.0, *)
    @objc public override var lineBreakStrategy: NSParagraphStyle.LineBreakStrategy {
        get { super.lineBreakStrategy }
        set { shimmerLabel.lineBreakStrategy = newValue; super.lineBreakStrategy = newValue; delayRefresh() }
    }
    @objc public override var preferredMaxLayoutWidth: CGFloat {
        get { super.preferredMaxLayoutWidth }
        set { shimmerLabel.preferredMaxLayoutWidth = newValue; super.preferredMaxLayoutWidth = newValue; delayRefresh() }
    }
    @objc public override var textColor: UIColor! {
        get { _textColor }
        set {
            _textColor = newValue
            guard !shimmerIsPlaying else { return }
            super.textColor = newValue
        }
    }
    
    private var shimmerAnimateIsAdded: Bool {
        self.layer.animation(forKey: "blink.animate") != nil ||
        self.shimmerLayer.animation(forKey: "shimmer.animate") != nil
    }
    
    /// 开始 Shimmer 动画
    func startShimmer(config: ShimmerLabel.Config) {
        if self.shimmerConfig != config {
            self.stopShimmer()
        }
        self.shimmerConfig = config
        if bounds.width > 0 {
            startShimmer()
        } else {
            self.setNeedsDisplay()
        }
    }
    /// 开始
    private func startShimmer(force: Bool = false) {
        guard !self.shimmerIsPlaying || force else { return }
        self.shimmerIsPlaying = true
        
        switch self.shimmerConfig.shimmerStyle {
        case .indicatorMove:
            self.makeLayerAsMask()
            self.configIndicatorMoveLayer()
            self.shimmerLayer.add(self.animateIndicatorMove(reverse: false), forKey: "shimmer.animate")
            
        case .indicatorMoveReverse:
            self.makeLayerAsMask()
            self.configIndicatorMoveLayer()
            self.shimmerLayer.add(self.animateIndicatorMove(reverse: true), forKey: "shimmer.animate")
            
        case .colorsFlow:
            self.makeLabelAsMask()
            self.configColorsFlowLayer()
            self.shimmerLayer.add(self.animateColorsFlow(), forKey: "shimmer.animate")
            
        case .colorsChange:
            self.makeLabelAsMask()
            self.configColorsChangeLayer()
            self.shimmerLayer.add(self.animateColorsChange(), forKey: "shimmer.animate")
            
        case .none:
            self.stopShimmer()
        }
        if self.shimmerConfig.blink {
            self.layer.add(animateWithBelink(), forKey: "blink.animate")
        }
    }
    /// 停止 Shimmer 动画
    func stopShimmer() {
        guard shimmerIsPlaying else { return }
        
        self.shimmerLayer.removeAllAnimations()
        self.layer.removeAllAnimations()
        if self.shimmerLayer.superlayer != nil {
            self.shimmerLayer.removeFromSuperlayer()
        }
        if self.shimmerLabel.superview != nil {
            self.shimmerLabel.removeFromSuperview()
        }
        if self.mask != nil {
            self.mask = nil
        }
        if self.shimmerLabel.layer.mask != nil {
            self.shimmerLabel.layer.mask = nil
        }
        self.shimmerIsPlaying = false
    }
    
    private func makeLayerAsMask() {
        super.textColor = _textColor
        self.shimmerLabel.textColor = self.shimmerConfig.shimmerColor
        if let att = attributedText {
            let range = NSRange(location: 0, length: att.length)
            super.attributedText = att
            
            self.shimmerLabel.attributedText = {
                let mAtt = NSMutableAttributedString(attributedString: att)
                mAtt.addAttribute(.foregroundColor, value: self.shimmerConfig.shimmerColor, range: range)
                return mAtt
            }()
        }
        
        if shimmerLabel.superview != self {
            self.addSubview(shimmerLabel)
        }
        self.shimmerLabel.layer.mask = shimmerLayer
    }
    
    private func makeLabelAsMask() {
        super.textColor = .clear
        self.shimmerLabel.textColor = .black
        
        if let att = attributedText {
            let range = NSRange(location: 0, length: att.length)
            super.attributedText = {
                let mAtt = NSMutableAttributedString(attributedString: att)
                mAtt.addAttribute(.foregroundColor, value: UIColor.clear, range: range)
                return mAtt
            }()
            
            self.shimmerLabel.attributedText = {
                let mAtt = NSMutableAttributedString(attributedString: att)
                mAtt.addAttribute(.foregroundColor, value: UIColor.black, range: range)
                return mAtt
            }()
        }
        
        if shimmerLabel.superview != self {
            self.addSubview(shimmerLabel)
        }
        if shimmerLayer.superlayer != self.layer {
            self.layer.addSublayer(self.shimmerLayer)
        }
        self.shimmerLayer.mask = self.shimmerLabel.layer
    }
    /// 指示器移动效果layer
    private func configIndicatorMoveLayer() {
        resetTransform()
        
        let rw = (self.shimmerConfig.shimmerRadius / self.shimmerConfig.shimmerWidth) * 0.5
        shimmerLayer.backgroundColor = UIColor.clear.cgColor
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.colors = [UIColor.clear, UIColor.white, UIColor.white, UIColor.clear].map({ $0.cgColor })
        shimmerLayer.locations = [0, 0.5 - rw, 0.5 + rw, 1.0].map { NSNumber(value: $0) }
        shimmerLayer.transform = sTransform(angle: -30)
    }
    /// 闪动效果layer
    private func configColorsShimmerLayer() {
        shimmerLayer.backgroundColor = self.shimmerConfig.shimmerColor.cgColor
        shimmerLayer.colors = nil
        shimmerLayer.locations = nil
    }
    /// 背景颜色流动效果layer
    private func configColorsFlowLayer() {
        resetTransform()
        
        shimmerLayer.locations = nil
        shimmerLayer.backgroundColor = UIColor.clear.cgColor
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.type = .axial
        shimmerLayer.colors = rawColors()
        
        setTransform(angle: 45)
    }
    /// 背景颜色变换效果layer
    private func configColorsChangeLayer() {
        resetTransform()
        
        let tempColors = [self.shimmerConfig.shimmerColorArray.first?.cgColor ?? textColor.cgColor]
        shimmerLayer.locations = nil
        shimmerLayer.backgroundColor = UIColor.clear.cgColor
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.type = .axial
        shimmerLayer.colors = tempColors + tempColors
    }
    
    private func resetTransform() {
        shimmerLayer.transform = CATransform3DMakeAffineTransform(.identity)
        shimmerLabel.layer.transform = CATransform3DMakeAffineTransform(.identity)
    }
    private func setTransform(angle: CGFloat) {
        shimmerLayer.transform = sTransform(angle: -angle)
        shimmerLabel.layer.transform = sTransform(angle: angle)
    }
    /// 设置形变 -> 平行四边形
    private func sTransform(angle: CGFloat) -> CATransform3D {
        CATransform3DMakeAffineTransform(CGAffineTransform(a: 1, b: 0, c: (angle / 180) * .pi, d: 1, tx: 0, ty: 0))
    }
    
    /// 指示器移动效果动画
    private func animateIndicatorMove(reverse: Bool) -> CAAnimation {
        let animate = CABasicAnimation(keyPath: "transform.translation.x")
        animate.duration = realDuration()
        animate.repeatCount = self.shimmerConfig.shimmerRepeat ? .infinity : 0
        animate.autoreverses = reverse
        animate.beginTime = 0.5
        animate.isRemovedOnCompletion = false
        let tw: CGFloat
        if let t = text {
            let _w = t.boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: font!.lineHeight), options: .usesLineFragmentOrigin, attributes: [.font: font!], context: nil).width
            tw = min(bounds.width, _w)
        } else if let t = attributedText {
            let _w = t.boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: font!.lineHeight), options: .usesLineFragmentOrigin, context: nil).width
            tw = min(bounds.width, _w)
        } else {
            tw = bounds.width
        }
        if textAlignment == .right {
            animate.fromValue = bounds.width - tw - shimmerConfig.shimmerWidth
            animate.toValue = bounds.width
        } else {
            animate.fromValue = -shimmerConfig.shimmerWidth
            animate.toValue = tw
        }
        return animate
    }
    /// 闪动效果动画
    private func animateWithBelink() -> CAAnimation {
        let ani = CAKeyframeAnimation(keyPath: "opacity")
        ani.values = [1, 1, 0.25, 0.25]
        ani.keyTimes = [0, 0.80, 0.95, 1]
        ani.duration = 1
        ani.autoreverses = true
        ani.repeatCount = .infinity
        ani.isRemovedOnCompletion = false
        return ani
    }
    /// 背景颜色流动效果动画
    private func animateColorsFlow() -> CAAnimation {
        var tempValues: [[CGColor]] = []
        var tempColors: [CGColor] = []
        if let cs = shimmerLayer.colors as? [CGColor] {
            tempColors = cs
        } else {
            tempColors = rawColors()
        }
        let colorsCount: Int = tempColors.count
        for _ in 0...tempColors.count {
            tempValues.append(tempColors)
            if let last = tempColors.last {
                tempColors.removeLast()
                tempColors.insert(last, at: 0)
            }
        }
        
        let animate = CAKeyframeAnimation(keyPath: "colors")
        animate.values = tempValues
        animate.duration = realDuration(colorsCount: colorsCount)
        animate.isRemovedOnCompletion = false
        animate.repeatCount = .infinity
        animate.calculationMode = .cubicPaced
        animate.fillMode = .backwards
        animate.timingFunction = CAMediaTimingFunction(name: .linear)
        return animate
    }
    
    /// 背景颜色变换效果动画
    private func animateColorsChange() -> CAAnimation {
        let tempValues: [Array<CGColor>] = self.shimmerConfig.shimmerColorArray.map({ [$0.cgColor, $0.cgColor] })
        let animate = CAKeyframeAnimation(keyPath: "colors")
        animate.values = tempValues
        animate.duration = realDuration()
        animate.isRemovedOnCompletion = false
        animate.repeatCount = .infinity
        animate.calculationMode = .cubicPaced
        return animate
    }
    
    /// 实际周期
    private func realDuration(colorsCount: Int = 0) -> TimeInterval {
        if let speed = self.shimmerConfig.shimmerSpeed {
            if shimmerConfig.shimmerStyle == .colorsFlow {
                let w = max(shimmerLayer.bounds.width, bounds.width)
                if w > 0 {
                    return TimeInterval(w / max(1, speed))
                } else {
                    return TimeInterval(CGFloat(colorsCount) * shimmerConfig.shimmerWidth / max(1, speed))
                }
            } else {
                return TimeInterval(Float(bounds.width / max(1, speed)))
            }
        } else {
            return self.shimmerConfig.shimmerDuration
        }
    }
    
    private func rawColors() -> [CGColor] {
        guard !shimmerConfig.shimmerColorArray.isEmpty else { return [] }
        
        let ww: CGFloat
        if shimmerLayer.bounds.width > 0 {
            ww = shimmerLayer.bounds.width
        } else if bounds.width > 0 {
            ww = bounds.width
        } else {
            ww = UIScreen.main.bounds.width
        }
        
        var cs: [CGColor] = []
        for e in shimmerConfig.shimmerColorArray {
            cs.append(e.cgColor)
        }
        let w = CGFloat(cs.count) * shimmerConfig.shimmerWidth
        var tempColor: [CGColor] = []
        for _ in 0..<Int(ceil(ww / w)) {
            tempColor.append(contentsOf: cs)
        }
        return tempColor
    }
    
    private func rawWidth() -> CGFloat {
        switch shimmerConfig.shimmerStyle {
        case .indicatorMove, .indicatorMoveReverse:
            return shimmerConfig.shimmerWidth
        case .colorsFlow:
            if let e = shimmerLayer.colors?.count {
                return CGFloat(e) * shimmerConfig.shimmerWidth
            } else {
                return bounds.width
            }
        case .colorsChange:
            return bounds.width
        case .none:
            return bounds.width
        }
    }
    
    private func rawMaskWidth() -> CGFloat {
        switch shimmerConfig.shimmerStyle {
        case .colorsFlow:
            return bounds.width + 20
        default:
            return bounds.width
        }
    }
    
    private func delayRefresh() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(checkRefresh), object: nil)
        guard !shimmerIsPlaying else { return }
        perform(#selector(checkRefresh), with: nil, afterDelay: 0.5)
    }
    
    @objc private func checkRefresh() {
        guard superview != nil, bounds.width > 0, window != nil else { return }
        startShimmer()
    }
    
    private func resetToNone() {
        // 还原config并停止播放
        shimmerConfig = ShimmerLabel.Config()
        stopShimmer()
        // 文本还原
        super.attributedText = _attributedText
        super.textColor = _textColor
        super.text = _text
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard bounds.width > 0 else { return }
        let needForceShimmer: Bool = bounds.size != shimmerLastSize
        shimmerLastSize = bounds.size
        
        if shimmerConfig.shimmerStyle == .colorsFlow {
            self.shimmerLayer.frame = CGRect(x: -shimmerConfig.shimmerWidth, y: 0, width: rawWidth() + shimmerConfig.shimmerWidth * 2, height: bounds.height)
            self.shimmerLabel.frame = CGRect(x: shimmerConfig.shimmerWidth, y: 0, width: rawMaskWidth(), height: bounds.height)
        } else {
            self.shimmerLayer.frame = CGRect(x: 0, y: 0, width: rawWidth(), height: bounds.height)
            self.shimmerLabel.frame = CGRect(x: 0, y: 0, width: rawMaskWidth(), height: bounds.height)
        }
        
        guard let _ = window else { return }
        startShimmer(force: needForceShimmer)
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            stopShimmer()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        guard let _ = window, shimmerConfig.shimmerStyle != .none, !shimmerIsPlaying else { return }
        startShimmer()
    }
}
