import UIKit

class RectangleDetectionGuide: UIView {
    var rectDectectionGuide = UIImageView()
    
    override func layoutSubviews() {
        isHidden    = true
        alpha       = 0
        layoutGuide()
    }
    
    private func layoutGuide() {
        rectDectectionGuide.image = #imageLiteral(resourceName: "rectangle")
        rectDectectionGuide.tintColor = UIColor.white
        self.addSubview(rectDectectionGuide)
        rectDectectionGuide.snp.makeConstraints{ make -> Void in
           make.edges.equalTo(self.snp.edges)
        }
    }
    
    // MARK: - Rectangle Detection
    func displayRectangleGuide() {
        DispatchQueue.main.async {
            self.isHidden = false
            Animator.fade(view: self,
                          to: 1.0,
                          for: 1.0,
                          options: [UIViewAnimationOptions.curveEaseInOut],
                          completion: nil)
        }
    }
    
    func hideRectangleGuide() {
        DispatchQueue.main.async {
            Animator.fade(view: self,
                          to: 0,
                          for: 1.0,
                          options: [UIViewAnimationOptions.curveEaseInOut],
                          completion: {
                            self.isHidden = true
            })
        }
    }
}
