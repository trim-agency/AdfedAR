import UIKit
import Vision

extension VNRectangleObservation {
    
    func corners() -> [CGPoint] {
        return [self.topLeft,
                self.topRight,
                self.bottomRight,
                self.bottomLeft ]
    }
}
