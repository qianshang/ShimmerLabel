//
//  ViewController.swift
//  ShimmerLabel
//
//  Created by 程维 on 2023/4/25.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .darkGray
        
        func insert(title: String = "", buildConfig: ((inout ShimmerLabel.Config) -> Void)? = nil) {
            let l_label: UILabel = UILabel()
            l_label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            l_label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            l_label.text = "["
            l_label.textColor = .white
            l_label.textAlignment = .right
            l_label.isHidden = true
            
            let c_label = ShimmerLabel()
            c_label.setContentHuggingPriority(.required, for: .horizontal)
            c_label.setContentCompressionResistancePriority(.required, for: .horizontal)
            c_label.text = "一个测试的标签"
            c_label.textColor = .blue
            if let builder = buildConfig {
                var cfg = ShimmerLabel.Config()
                builder(&cfg)
                c_label.startShimmer(config: cfg)
            }
            
            let r_label: UILabel = UILabel()
            r_label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            r_label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            r_label.text = "]"
            r_label.textColor = .white
            r_label.textAlignment = .left
            r_label.isHidden = true
            
            let s = UIStackView(arrangedSubviews: [l_label, c_label, r_label])
            s.alignment = .fill
            s.axis = .horizontal
            s.spacing = 15
            s.distribution = .fill
            
            stackView.addArrangedSubview(s)
        }
        
        insert(title: "none") { cfg in
            //
        }
        insert(title: "indicatorMove") { cfg in
            cfg.shimmerColor = .red
            cfg.shimmerStyle = .indicatorMove
            cfg.shimmerSpeed = 30
        }
        insert(title: "colorsFlow") { cfg in
            cfg.shimmerColorArray = [
                UIColor(0x8845EB),
                UIColor(0x78ACFF),
                UIColor(0x6BDEB0),
                UIColor(0xECDC65),
                UIColor(0xE84DCC),
                UIColor(0x4B94FF)
            ]
            cfg.shimmerStyle = .colorsFlow
            cfg.shimmerSpeed = 30
        }
        insert(title: "colorsFlow+fade") { cfg in
            cfg.shimmerColorArray = [
                UIColor(0x8845EB),
                UIColor(0x78ACFF),
                UIColor(0x6BDEB0),
                UIColor(0xECDC65),
                UIColor(0xE84DCC),
                UIColor(0x4B94FF)
            ]
            cfg.shimmerStyle = .colorsFlow
            cfg.shimmerSpeed = 30
            cfg.shimmerWidth = 20
            cfg.blink = true
        }
        insert(title: "colorsChange") { cfg in
            cfg.shimmerColorArray = [
                UIColor(0x8845EB),
                UIColor(0x78ACFF),
                UIColor(0x6BDEB0),
                UIColor(0xECDC65),
                UIColor(0xE84DCC),
                UIColor(0x4B94FF)
            ]
            cfg.shimmerStyle = .colorsChange
            cfg.shimmerSpeed = 30
        }
    }

}

extension UIColor {
    public convenience init(_ hex: UInt32, alpha: CGFloat = 1) {
        let r: UInt32 = hex >> 16 & 0xFF
        let g: UInt32 = hex >> 8 & 0xFF
        let b: UInt32 = hex & 0xFF
        
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }
}
