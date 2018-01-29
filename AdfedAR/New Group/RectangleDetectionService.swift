import Foundation
import Vision
import ARKit

class RectangleDetectionService {
    let sceneView: MainARSCNView!
    var rootAnchor: ARAnchor!
    
    init(sceneView: MainARSCNView, rootAnchor: ARAnchor) {
        self.sceneView = sceneView
        self.rootAnchor = rootAnchor
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        log.debug("Rect service")
        guard let observations = request.results as? [VNRectangleObservation] else {
            return
        }
        
        let highConfidenceObservation = observations.max { a, b in a.confidence < b.confidence }
        
        guard let highestConfidenceObservation = highConfidenceObservation else {
            log.debug("Error with high confidence observation")
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
            
            // Updates position of element when rect moves
            node.transform = SCNMatrix4(result.worldTransform)
            
        } else {
            
            // Creates a element if rootAnchor doesn't exist
            self.rootAnchor         = ARAnchor(transform: result.worldTransform)
//            self.hasFoundRectangle  = true
            self.sceneView.session.add(anchor: self.rootAnchor!)
        }
        
        drawDebugPolygon(points, color: .red)
    }
    
    private func getBoxCenter(_ observation: VNRectangleObservation?) -> CGPoint {
        return CGPoint(x: (observation?.boundingBox.midX)!,
                       y: (observation?.boundingBox.midY)!)
    }
    
    private func drawDebugPolygon(_ points: [CGPoint], color: UIColor) {
        #if DEBUG
            DispatchQueue.main.async {
                log.debug("Should display Rect")
                let convertedPoints = points.map{ self.sceneView.convertFromCamera($0) }
                let debugLayer = DebugPolygon(points: convertedPoints, color: color)
                self.sceneView.layer.addSublayer(debugLayer)
            }
        #endif
    }
}
