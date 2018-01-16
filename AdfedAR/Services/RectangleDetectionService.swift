import Foundation
import ARKit

class RectangleDetectionService {
    var sceneView: ARSCNView!
    var rectangleDetected = false
    var delegate: RectangleDetectionDelegate?
    var rectangleDispathQueue = DispatchQueue(label: "com.rectangleDetection")
    
    init(_ sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    func detectionLoop() {
        rectangleDispathQueue.async {
            let point = self.detectRectangle()
            if point == nil && !self.rectangleDetected {
                self.detectionLoop()
            }  else {
                log.debug("Found Rect")
                self.rectangleDetected = true
                self.delegate?.didDetectRectangle(sender: self, point: point!)
            }
        }
    }
    
    func detectRectangle() -> CGPoint? {
        guard let image = currentFrame() else { return nil }
        let detector = CIDetector(ofType: CIDetectorTypeRectangle,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh,
                                            CIDetectorAspectRatio: 1.6,
                                            CIDetectorMaxFeatureCount: 10])!
        
        let features = detector.features(in: image)
        var point: CGPoint?
        for feature in features as! [CIRectangleFeature] {
            let centerX = feature.bounds.midX
            let centerY = feature.bounds.midY
            point = CGPoint(x: centerX, y: centerY)
        }
        return point
    }
    
    func currentFrame()-> CIImage? {
        let pixelBuffer = sceneView.session.currentFrame?.capturedImage
        if pixelBuffer == nil {  return nil }
        return CIImage(cvPixelBuffer: pixelBuffer!)
    }
}
