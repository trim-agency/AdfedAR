import UIKit

class UserInstructionLabel: UILabel {
    

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10 )
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
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
    
    func updateState(_ state: State) {
        switch state {
        case .appLoading:
            updateText(.lookingForRune)
        case .detectingRune:
            updateText(.lookingForRune)
        case .runeDetected:
            updateText(.none)
        case .rectangleDetectionPause:
            print("pause")
        case .detectingRectangle:
            log.debug("detecting Rect")
            updateText(.lookingForRectangle)
        case .rectangleDetected:
            updateText(.none)
        case .waitingOnPlane:
            print("waiting on plane")
            updateText(.lookingForPlane)
        case .planeDetected:
            updateText(.none)
        case .loadingAnimation:
            updateText(.none)
        case .playingAnimation:
            updateText(.tapForVideo)
        case .reset:
            updateText(.none)
        }
    }
}
