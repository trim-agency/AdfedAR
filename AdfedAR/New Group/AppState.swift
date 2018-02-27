import Foundation

class AppState {
    static let instance = AppState()
    var current: State!
}


enum State {
    case appLoading
    case detectingRune
    case runeDetected
    case detectingRectangle
    case rectangleDetected
    case loadingAnimation
    case playingAnimation
    case reset
}
