import Foundation
import CoreML
import Vision

class CoreMLService {
    var delegate: CoreMLServiceDelegate?
    
    func getPageType(_ image: CVPixelBuffer) throws {
        let model = try VNCoreMLModel(for: AdFed().model)
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
    // TODO: Fix creation of page, currently failing
    private func parseResults(_ observations: [VNClassificationObservation] ) {
        let highConfidenceObservation = (observations.max { a, b in a.confidence < b.confidence })?.identifier
        log.debug(highConfidenceObservation)
        if let page = Page(rawValue: highConfidenceObservation!) {
            log.debug(page)
        } else {
            log.error("Page not created")
        }
    }
}
