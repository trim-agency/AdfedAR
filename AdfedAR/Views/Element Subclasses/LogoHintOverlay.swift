import UIKit
import SnapKit

class LogoHintOverlay: UIView {
    let hintWindow = UIView()
    let hintWindowBorder = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        defineMaskConstraints(add: hintWindow, to: superview!)
        defineMaskConstraints(add: hintWindowBorder, to: hintWindow)
        setupHintWindow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setMask(with: hintWindow.frame, in: self)
        setupBorder()
        fadeIn()
    }

   
    // MARK: - Layout
    private func setupHintWindow() {
        alpha = 0.0
        hintWindow.layer.cornerRadius = bounds.size.width / 2
        hintWindow.backgroundColor = UIColor.clear
        hintWindow.frame = CGRect(x: 0, y: 0, width: bounds.width * 0.75, height: bounds.width * 0.75)
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    private func setSuccessBorder() {
        DispatchQueue.main.async {
            self.hintWindowBorder.layer.borderColor = UIColor.green.cgColor
        }
    }
    
    private func setInitialBorder() {
        DispatchQueue.main.async {
            self.hintWindowBorder.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    private func setupBorder() {
        hintWindowBorder.layer.cornerRadius = hintWindow.bounds.height / 2
        hintWindowBorder.layer.borderWidth = 3.0
        hintWindowBorder.layer.borderColor = UIColor.red.cgColor
    }

    private func defineMaskConstraints(add view: UIView, to parentView: UIView ) {
        parentView.addSubview(view)
        view.snp.makeConstraints{ make -> Void in
            make.width.height.equalTo((superview?.snp.width)!).multipliedBy(0.75)
            make.center.equalTo((superview?.snp.center)!)
        }
    }
    
    func setMask(with hole: CGRect, in view: UIView){
        
        // Create a mutable path and add a rectangle that will be h
        let mutablePath = CGMutablePath()
        mutablePath.addRect(view.bounds)
        mutablePath.addEllipse(in: hole)

        // Create a shape layer and cut out the intersection
        let mask = CAShapeLayer()
        mask.path = mutablePath
        mask.fillRule = kCAFillRuleEvenOdd
        
        // Add the mask to the view
        view.layer.mask = mask
    }
    
    // MARK: - Actions
    public func fadeOut() {
        setSuccessBorder()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            UIView.animate(withDuration: 1.0) {
                self.hintWindowBorder.alpha = 0.0
                self.alpha = 0.0
            }
        })
    }
    
    public func fadeIn() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0) {
                self.setInitialBorder()
                self.hintWindowBorder.alpha = 1.0
                self.alpha = 1.0
            }
        }
    }
}
