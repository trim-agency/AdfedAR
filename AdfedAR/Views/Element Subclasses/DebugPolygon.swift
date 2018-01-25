import UIKit

class DebugPolygon: CAShapeLayer {
   
    convenience init( points: [CGPoint], color: UIColor ) {
        self.init(layer: CAShapeLayer())
        self.fillColor     = nil
        self.strokeColor   = color.cgColor
        self.lineWidth     = 2
        let path           = UIBezierPath()
        
        path.move(to: points.last!)
        points.forEach { point in
            path.addLine(to: point)
        }
        self.path = path.cgPath
    }
    
    
}
