//
//  SingleTextShimmerView.swift
//  ShimmerLabel
//
//  Created by 程维 on 2023/6/25.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SingleTextShimmerView: UIView {
    
    private let textLabel: UILabel = UILabel()
    private let container: UIView = UIView()
    private let trackImageView: UIImageView = UIImageView()
    private let maskTextLabel: UILabel = UILabel()
    
    var text: String {
        set {
            textLabel.text = newValue
            maskTextLabel.text = newValue
        }
        get { textLabel.text ?? "" }
    }
    var font: UIFont {
        set {
            textLabel.font = newValue
            maskTextLabel.font = newValue
        }
        get { textLabel.font ?? UIFont.systemFont(ofSize: 17) }
    }
    var textColor: UIColor {
        set {
            textLabel.textColor = newValue
        }
        get { textLabel.textColor ?? .black }
    }
    var config: ShimmerConfig = .none
    private var animate: CAAnimation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = false
        
        addSubview(textLabel)
        addSubview(container)
        container.addSubview(trackImageView)
        container.mask = maskTextLabel
        
        textLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        NotificationCenter.default
            .rx.notification(UIApplication.willEnterForegroundNotification)
            .observe(on: ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.resumeShimmer()
            })
            .disposed(by: rx.disposeBag)
        NotificationCenter.default
            .rx.notification(UIApplication.didEnterBackgroundNotification)
            .observe(on: ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.pauseShimmer()
            })
            .disposed(by: rx.disposeBag)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard bounds.width > 0 else { return pauseShimmer() }
        makeShimmer()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            pauseShimmer()
        }
    }
    
    private func resumeShimmer() {
        guard let ani = animate else { return }
        
        trackImageView.layer.add(ani, forKey: "shimmer")
    }
    
    private func pauseShimmer() {
        guard animate != nil else { return }
        
        trackImageView.layer.removeAllAnimations()
    }
    
    private func makeShimmer() {
        maskTextLabel.frame = textLabel.frame
        
        switch config.style {
        case .indicator(let color):
            makeIndicator(color)
            container.isHidden = false
        case .colorsFlow(let colors):
            makeColorsFlow(colors)
            container.isHidden = false
        case .imageFlow(let image):
            makeImageFlow(image)
            container.isHidden = false
        case .none:
            container.isHidden = true
            trackImageView.layer.removeAllAnimations()
            animate = nil
        }
    }
    
    private func makeIndicator(_ color: UIColor) {
        let _w: CGFloat = config.width
        let _h: CGFloat = font.lineHeight
        let _s1: CGSize = CGSize(width: _w, height: _h)
        let _s2: CGSize = CGSize(width: _w + _h, height: _h)
        trackImageView.frame = CGRect(origin: CGPoint(x: maskTextLabel.frame.origin.x - _w, y: maskTextLabel.frame.origin.y), size: _s1)
        trackImageView.image = UIGraphicsImageRenderer(size: _s2).image(actions: { t in
            let layer = CALayer()
            layer.frame = CGRect(origin: .zero, size: _s2)
            
            let colors: [UIColor] = [.clear, color.withAlphaComponent(0.9), color.withAlphaComponent(0.9), .clear]
            let ll = CAGradientLayer()
            ll.colors = colors.map(\.cgColor)
            ll.startPoint = CGPoint(x: 0, y: 0.5)
            ll.endPoint = CGPoint(x: 1, y: 0.5)
            ll.type = .axial
            ll.frame = CGRect(origin: .zero, size: _s1)
            layer.addSublayer(ll)
            ll.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1, b: 0, c: (-30 / 180) * .pi, d: 1, tx: 0, ty: 0))
            
            layer.render(in: t.cgContext)
        })
        let ani = CABasicAnimation(keyPath: "transform.translation.x")
        ani.duration = self.textLabel.width / config.speed
        ani.repeatCount = .infinity
        ani.fromValue = 0
        ani.toValue = self.textLabel.width + _w
        animate = ani
        trackImageView.layer.add(ani, forKey: "shimmer")
    }
    
    private func makeColorsFlow(_ colors: [UIColor]) {
        let rawColors: [UIColor]
        if let f = colors.first, let l = colors.last, f != l {
            rawColors = colors + [f]
        } else {
            rawColors = colors
        }
        let cw: CGFloat = CGFloat(rawColors.count) * config.width
        let cc: CGFloat = ceil(self.textLabel.width / cw)
        let ww: CGFloat = cc * cw
        let _h: CGFloat = font.lineHeight
        let _s1: CGSize = CGSize(width: ww * 2 - _h, height: _h)
        trackImageView.frame = CGRect(origin: CGPoint(x: maskTextLabel.frame.origin.x - ww - _h, y: maskTextLabel.frame.origin.y), size: _s1)
        trackImageView.image = UIGraphicsImageRenderer(size: _s1).image(actions: { t in
            let layer = CALayer()
            layer.frame = CGRect(origin: .zero, size: _s1)
            
            let dl = CALayer()
            for i in 0..<Int(cc * 2) {
                let ll = CAGradientLayer()
                ll.colors = rawColors.map(\.cgColor)
                ll.startPoint = CGPoint(x: 0, y: 0.5)
                ll.endPoint = CGPoint(x: 1, y: 0.5)
                ll.type = .axial
                ll.frame = CGRect(x: cw * CGFloat(i), y: 0, width: cw, height: _h)
                dl.addSublayer(ll)
            }
            dl.frame = CGRect(x: -_h, y: 0, width: _s1.width, height: _h)
            layer.addSublayer(dl)
            dl.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1, b: 0, c: (-45 / 180) * .pi, d: 1, tx: 0, ty: 0))
            
            layer.render(in: t.cgContext)
        })
        
        let ani = CABasicAnimation(keyPath: "transform.translation.x")
        ani.duration = ww / config.speed
        ani.repeatCount = .infinity
        ani.fromValue = 0
        ani.toValue = ww
        animate = ani
        trackImageView.layer.add(ani, forKey: "shimmer")
    }
    
    private func makeImageFlow(_ image: UIImage) {
        let _h: CGFloat = font.lineHeight
        let _w: CGFloat = floor(image.size.width * (_h / image.size.height))
        let cc: CGFloat = ceil(self.textLabel.width / _w)
        let ww: CGFloat = cc * _w
        let _s1: CGSize = CGSize(width: ww * 2, height: _h)
        
        trackImageView.frame = CGRect(origin: CGPoint(x: maskTextLabel.frame.origin.x - ww, y: maskTextLabel.frame.origin.y), size: _s1)
        trackImageView.image = UIGraphicsImageRenderer(size: _s1).image(actions: { t in
            let layer = CALayer()
            layer.frame = CGRect(origin: .zero, size: _s1)
            
            for i in 0..<Int(cc * 2) {
                let ll = CALayer()
                ll.contents = image.cgImage
                ll.frame = CGRect(x: _w * CGFloat(i), y: 0, width: _w, height: _h)
                layer.addSublayer(ll)
            }
            
            layer.render(in: t.cgContext)
        })
        
        let ani = CABasicAnimation(keyPath: "transform.translation.x")
        ani.duration = ww / config.speed
        ani.repeatCount = .infinity
        ani.fromValue = 0
        ani.toValue = ww
        animate = ani
        trackImageView.layer.add(ani, forKey: "shimmer")
    }
    
}

extension SingleTextShimmerView {
    
    enum ShimmerStyle {
        case indicator(UIColor)
        case colorsFlow([UIColor])
        case imageFlow(UIImage)
        case none
    }
    
    struct ShimmerConfig {
        let style: ShimmerStyle
        let speed: CGFloat
        let width: CGFloat
        
        static let none = ShimmerConfig(style: .none, speed: 0, width: 0)
    }
    
}
