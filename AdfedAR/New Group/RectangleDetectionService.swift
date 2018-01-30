import Foundation
import Vision
import ARKit

class RectangleDetectionService {
    let sceneView: MainARSCNView!
    var rootAnchor: ARAnchor!
    var delegate: RectangleDetectionServiceDelegate?
    
    init(sceneView: MainARSCNView, rootAnchor: ARAnchor) {
        self.sceneView = sceneView
        self.rootAnchor = rootAnchor
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        log.debug("Rect Service Started")
        guard let observations = request.results as? [VNRectangleObservation] else {
            return
        }
        
        let highConfidenceObservation = observations.max { a, b in a.confidence < b.confidence }
        
        guard let highestConfidenceObservation = highConfidenceObservation else {
            delegate?.rectangleDetectionError(sender: self)
            return
        }
        
        let points = (highConfidenceObservation?.corners())!
        
        highestConfidenceObservation.boundingBox.applying(CGAffineTransform(scaleX: 1, y: -1))
        highestConfidenceObservation.boundingBox.applying(CGAffineTransform(translationX: 0, y: 1))
        
        let center          = getBoxCenter(highConfidenceObservation)
        let hitTestResults  = self.sceneView.hitTest(center, types: [.existingPlaneUsingExtent, .featurePoint])
        guard let result    = hitTestResults.first else {
            log.debug("no hit test results")
            return
            
        }
        
        if let rootAnchor = self.rootAnchor,
            let node = self.sceneView.node(for: rootAnchor) {
                node.transform = SCNMatrix4(result.worldTransform)
        } else {
            updateRootAnchor(result)
        }
        delegate?.didDetectRectangle(sender: self, corners: points)
        drawDebugPolygon(points, color: .red)
    }
  
    private func updateRootAnchor(_ result: ARHitTestResult) {
        self.rootAnchor = ARAnchor(transform: result.worldTransform)
        self.sceneView.session.add(anchor: self.rootAnchor!)
    }
    
    private func getBoxCenter(_ observation: VNRectangleObservation?) -> CGPoint {
        return CGPoint(x: (observation?.boundingBox.midX)!,
                       y: (observation?.boundingBox.midY)!)
    }
    
    private func drawDebugPolygon(_ points: [CGPoint], color: UIColor) {
        #if DEBUG
            DispatchQueue.main.async {
                let convertedPoints = points.map{ self.sceneView.convertFromCamera($0) }
                let debugLayer = DebugPolygon(points: convertedPoints, color: color)
                self.sceneView.layer.addSublayer(debugLayer)
                self.delegate?.didDetectRectangle(sender: self, corners: convertedPoints)
            }
        #endif
    }
}
