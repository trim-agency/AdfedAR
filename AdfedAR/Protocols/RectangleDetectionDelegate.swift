import UIKit

protocol RectangleDetectionDelegate {
    func didDetectRectangle(sender: RectangleDetectionService, point: CGPoint)
}
