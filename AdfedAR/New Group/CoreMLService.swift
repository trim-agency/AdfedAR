import Foundation
import CoreML
import Vision

class CoreMLService {
    var delegate: CoreMLServiceDelegate?
    
    func getPageType(_ image: CVPixelBuffer) throws {
        let model   = try VNCoreMLModel(for: AdFed().model)
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
            logResults(results)
            parseResults(results)
        } else {
            log.debug(error!)
            delegate?.didReceiveRecognitionError(sender: self, error: CoreMLError.observationError)
        }
    }
    
    private func logResults(_ results: [VNClassificationObservation]) {
        var logString = ""
        results.forEach({ (observation) in
            logString.append("\(observation.identifier) -> \(observation.confidence)\n")
        })
        log.info(logString)
    }
    
    private func parseResults(_ observations: [VNClassificationObservation] ) {
        var highConfidenceObservation: VNClassificationObservation!
        do {
           highConfidenceObservation = try highestConfidenceObservation(observations)
        } catch {
            delegate?.didReceiveRecognitionError(sender: self, error: error as! CoreMLError)
            return
        }
        
        if highConfidenceObservation.confidence > 0.70 {
            if let page = Page(rawValue: highConfidenceObservation.identifier)  {
                delegate?.didRecognizePage(sender: self, page: page)
            } else {
                delegate?.didReceiveRecognitionError(sender: self, error: CoreMLError.observationError)
                log.error("Page not created")
            }
        } else {
            delegate?.didReceiveRecognitionError(sender: self, error: CoreMLError.lowConfidence)
        }
    }
    
    private func highestConfidenceObservation(_ observations: [VNClassificationObservation]) throws -> VNClassificationObservation {
        if let highConfidenceObservation = (observations.max { a, b in a.confidence < b.confidence }){
            return highConfidenceObservation
        } else {
            throw CoreMLError.invalidObject
        }
    }
}
