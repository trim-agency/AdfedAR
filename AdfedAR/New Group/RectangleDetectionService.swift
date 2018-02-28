import Foundation
import Vision
import ARKit

class RectangleDetectionService {
    var sceneView: MainARSCNView?
    var rootAnchor: ARAnchor?
    var delegate: RectangleDetectionServiceDelegate?
    static let instance = RectangleDetectionService()
    
    public func setup(sceneView: MainARSCNView) {
        self.sceneView = sceneView
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation] else {
            log.debug("observation error")
            return
        }
        
        for observation in observations {
            log.debug(observation.boundingBox)
        }
        
        let highConfidenceObservation = observations.max { a, b in a.confidence < b.confidence }
        
        guard let highestConfidenceObservation = highConfidenceObservation else {
            delegate?.rectangleDetectionError(sender: self)
            return
        }
        highestConfidenceObservation.boundingBox.applying(CGAffineTransform(scaleX: 1, y: -1))
        highestConfidenceObservation.boundingBox.applying(CGAffineTransform(translationX: 0, y: 1))
        
        let points = (highConfidenceObservation?.corners())!
log.debug(points)

        
        let center          = getBoxCenter(highConfidenceObservation)
        log.debug(center)
        drawDebugDot(center)
        let hitTestResults  = self.sceneView!.hitTest(center, types: [.existingPlaneUsingExtent, .featurePoint])
        guard let result    = hitTestResults.first else {
            delegate?.rectangleDetectionError(sender: self)
            return
        }

        
        updateRootAnchor(result)
        delegate?.didDetectRectangle(sender: self, corners: points)
        drawDebugPolygon(points, color: .red)
    }

    private func drawDebugDot(_ center: CGPoint) {
        let circleLayer         = CAShapeLayer()
        let radius: CGFloat     = 15.0
        circleLayer.path        = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
        circleLayer.position    = center
        circleLayer.fillColor   = UIColor.red.cgColor
        sceneView?.layer.addSublayer(circleLayer)
    }
    
    private func updateRootAnchor(_ result: ARHitTestResult) {
        if let rootAnchor = self.rootAnchor,
            let node = self.sceneView!.node(for: rootAnchor) {
            node.transform = SCNMatrix4(result.worldTransform)
        } else {
            self.rootAnchor = ARAnchor(transform: result.worldTransform)
            self.sceneView!.session.add(anchor: self.rootAnchor!)
        }
    }
    
    private func getBoxCenter(_ observation: VNRectangleObservation?) -> CGPoint {
        return CGPoint(x: (observation?.boundingBox.midX)!,
                       y: (observation?.boundingBox.midY)!)
    }
    
    private func drawDebugPolygon(_ points: [CGPoint], color: UIColor) {
//        #if DEBUG
            DispatchQueue.main.async {
                let convertedPoints = points.map{ self.sceneView!.convertFromCamera($0) }
                let debugLayer = DebugPolygon(points: convertedPoints, color: color)
                self.sceneView!.layer.addSublayer(debugLayer)
            }
//        #endif
    }
}
