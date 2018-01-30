import Foundation

protocol CoreMLServiceDelegate {
    func didRecognizePage(sender: CoreMLService, page: Page)
    func didReceiveRecognitionError(sender: CoreMLService, error: CoreMLError)
}
