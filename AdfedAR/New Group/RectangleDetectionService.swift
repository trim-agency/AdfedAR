import Foundation
import Vision
import ARKit

class RectangleDetectionService {
    var sceneView: MainARSCNView?
    var rootAnchor: ARAnchor?
    var delegate: RectangleDetectionServiceDelegate?
    var currentRotation: simd_float4x4?
    static let instance = RectangleDetectionService()
    
    public func setup(sceneView: MainARSCNView) {
        self.sceneView = sceneView
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation] else {
            log.debug("observation error")
            return
        }

        let highConfidenceObservation = observations.max { a, b in a.confidence < b.confidence }
        
        guard let highestConfidenceObservation = highConfidenceObservation else {
            delegate?.rectangleDetectionError(sender: self)
            return
        }

        highestConfidenceObservation.boundingBox.applying(CGAffineTransform(scaleX: 1, y: -1))
        highestConfidenceObservation.boundingBox.applying(CGAffineTransform(translationX: 0, y: 1))
        
        let points = (highConfidenceObservation?.corners())!

        let center          = getBoxCenter(highConfidenceObservation)
        let hitTestResults  = self.sceneView!.hitTest(center, types: [.existingPlaneUsingExtent, .featurePoint])
        guard let result    = hitTestResults.first else {
            delegate?.rectangleDetectionError(sender: self)
            return
        }

        
        updateRootAnchor(result)
        delegate?.didDetectRectangle(sender: self, corners: points)
    }

    private func updateRootAnchor(_ result: ARHitTestResult) {
        if let rootAnchor = self.rootAnchor,
            let node = self.sceneView!.node(for: rootAnchor),
            let rotate = currentRotation {
            let rotateTransform = simd_mul(result.worldTransform, rotate)
            node.transform = SCNMatrix4(rotateTransform)
//            node.transform = SCNMatrix4(result.worldTransform)
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
