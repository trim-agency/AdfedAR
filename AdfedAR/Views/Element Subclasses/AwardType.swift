import UIKit

class AwardType: UIImageView {
    let judgesChoice = #imageLiteral(resourceName: "judges'-choice")
    let bestOfShow = #imageLiteral(resourceName: "best-of-show")
    
    func showLabel(_ page: Page) {
        DispatchQueue.main.async {
            self.image = page == .judgesChoice ? self.judgesChoice : self.bestOfShow
            self.isHidden = false
        }
    }
    
    func hide() {
        self.isHidden = true
    }
}
