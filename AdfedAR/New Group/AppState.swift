import Foundation

class AppState {
    static let instance = AppState()
    var hasReset = false
    var current: State!{
        didSet {
            switch current {
            case .appLoading :
                log.debug(current)
            case .detectingRune:
                log.debug(current)
            case .runeDetected:
                log.debug(current)
            case .detectingRectangle:
                log.debug(current)
            case .rectangleDetected:
                log.debug(current)
            case .waitingOnPlane:
                log.debug(current)
            case .loadingAnimation:
                log.debug(current)
            case .playingAnimation:
                log.debug(current)
            case .reset:
                log.debug(current)
                hasReset = true
            case .none:
                print("none")
            case .some(_):
                print("some")
            }
        }
    }
}


enum State {
    case appLoading
    case detectingRune
    case runeDetected
    case waitingOnPlane
    case detectingRectangle
    case rectangleDetected
    case loadingAnimation
    case playingAnimation
    case reset
}
