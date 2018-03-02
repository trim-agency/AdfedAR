import Foundation
import Vision
import ARKit
import SceneKit

class RectangleDetectionService {
    var sceneView: MainARSCNView?
    var rootAnchor: ARAnchor?
    var delegate: RectangleDetectionServiceDelegate?
    var currentRotation: simd_float4x4?
    static let instance = RectangleDetectionService()
    var recentAnchorID: UUID?
    
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
        
        let points          = (highConfidenceObservation?.corners())!
        let center          = getBoxCenter(highConfidenceObservation)
        DispatchQueue.main.async {
            let orientedCenter  = self.sceneView?.convertFromCamera(center)
            let hitTestResults  = self.sceneView!.hitTest(orientedCenter!, types: [.existingPlaneUsingExtent])
            //        let hitTestResults  = self.sceneView!.hitTest(center, types: [.existingPlaneUsingExtent, .featurePoint])
            guard let result    = hitTestResults.first else {
                self.delegate?.rectangleDetectionError(sender: self)
                return
            }
//            if !AppState.instance.hasReset {
                self.updateRootAnchor(result)
//            }
            self.delegate?.didDetectRectangle(sender: self, corners: points)
        }
        
    }

    private func updateRootAnchor(_ result: ARHitTestResult) {
        let anchor           = ARAnchor(transform: result.worldTransform)
        let vector3 = SCNVector3Make(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
        let node = SCNNode()
        node.position = vector3
        node.name = "test"
        sceneView?.scene.rootNode.addChildNode(node)
        sceneView?.session.add(anchor: anchor)

////        let resultTransform = SCNMatrix4(result.worldTransform)
////        sceneView?.node(for: rootAnchor)
//        if let rootAnchor   = self.rootAnchor,
//           let node         = self.sceneView!.node(for: rootAnchor),
//           let rotate       = currentRotation {
////               let rotateTransform  = simd_mul(result.worldTransform, rotate)
////               node.transform       = SCNMatrix4(rotateTransform)
//               let anchor           = ARAnchor(transform: result.worldTransform)
//               sceneView?.session.add(anchor: anchor)
////            node.transform = SCNMatrix4(result.worldTransform)
//        } else {
//            self.rootAnchor = ARAnchor(transform: result.worldTransform)
//            self.sceneView!.session.add(anchor: self.rootAnchor!)
//        }
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
