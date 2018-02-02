import UIKit

class UserInstructionLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10 )
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        setupBackground()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setCorners()
        setupBackground()
    }

    func updateText(_ instructions: UserInstructions) {
        DispatchQueue.main.async {
            self.text = instructions.rawValue
            if instructions != .none {
                self.isHidden = false
            } else {
                self.isHidden = true
            }
        }
    }

    // MARK: - Setup
    private func setupBackground() {
        let blur        = UIBlurEffect(style: .dark)
        let blurView    = UIVisualEffectView(effect: blur)
        blurView.frame  = bounds
        self.layer.insertSublayer(blurView.layer, below: layer)
    }
    

    private func setCorners() {
        clipsToBounds = true
        layer.cornerRadius = frame.height / 3
    }
}
