import UIKit

protocol RectangleDetectionServiceDelegate {
    func didDetectRectangle(sender: RectangleDetectionService, corners: [CGPoint])
    func rectangleDetectionError(sender: RectangleDetectionService)
}
