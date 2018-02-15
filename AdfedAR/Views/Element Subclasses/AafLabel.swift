import UIKit

class AafLabel: UILabel {
    convenience init() {
        self.init()
        let underlinedText = NSAttributedString(string: "AAF/AAA", attributes: [NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue])
        attributedText = underlinedText
    }
}
