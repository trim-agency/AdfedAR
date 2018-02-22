import UIKit

class UserInstructionLabel: UILabel {

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10 )
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func updateText(_ instructions: UserInstructions) {
        if Thread.isMainThread {
            self.text = instructions.rawValue.uppercased()
        } else {
            DispatchQueue.main.async {
                self.text = instructions.rawValue.uppercased()
            }
        }
    }
}
