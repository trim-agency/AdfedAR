import Foundation

protocol CoreMLServiceDelegate {
    func didRecognizeRune(sender: CoreMLService, page: Page)
    func didReceiveRuneRecognitionError(sender: CoreMLService, error: CoreMLError)
}
