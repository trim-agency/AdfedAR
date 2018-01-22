import Foundation
import CoreML
import Vision

class CoreMLService {
    let model = adFed()
    var delegate: CoreMLServiceDelegate?
    
    func getPageType(_ image: CVPixelBuffer) throws {
        let model = try VNCoreMLModel(for: adFed().model)
        let request = VNCoreMLRequest(model: model, completionHandler: pageRecognitionHandler)
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try handler.perform([request])
    }
    
    func pageRecognitionHandler(request: VNRequest, error: Error?) {
        if error == nil {
            guard let results = request.results as? [VNClassificationObservation] else {
                log.error("Classification downcast error")
                return
            }
            log.debug(results)
            parseResults(results)
        } else {
            delegate?.didReceiveRecognitionError(sender: self, error: error!)
        }
    }
    
    private func parseResults(_ observations: [VNClassificationObservation] ) {
        let highConfidenceObservation = observations.max { a, b in a.confidence < b.confidence }
        
        if highConfidenceObservation?.identifier == "judgesChoice" {
            delegate?.didRecognizePage(sender: self, page: Page.JudgesChoice)
        } else {
            delegate?.didRecognizePage(sender: self, page: Page.BestOfShow)
        }
    }
}
