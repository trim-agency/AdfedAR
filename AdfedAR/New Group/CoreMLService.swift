import UIKit
import CoreML
import Vision
import Photos

class CoreMLService {
    var delegate: CoreMLServiceDelegate?
    var frameCounter = 0
    func getPageType(_ image: CVPixelBuffer) throws {
        let transformedImage = transformBuffer(image)
        var croppedImage = UIImage(ciImage: transformedImage)
        croppedImage = croppedImage.crop(to: CGSize(width: UIScreen.main.bounds.width * 0.6,
                                                    height: UIScreen.main.bounds.width * 0.6))
        let model   = try VNCoreMLModel(for: AdFed().model)
        let request = VNCoreMLRequest(model: model, completionHandler: pageRecognitionHandler)
        let handler = VNImageRequestHandler(ciImage: croppedImage.ciImage!, options: [:])
        try handler.perform([request])
    }
    
    private func transformBuffer(_ pixelBuffer: CVPixelBuffer) -> CIImage {
        var image = CIImage(cvPixelBuffer: pixelBuffer)
        filterImage(image: &image, filterName: "CIColorControls", filterKey: "inputContrast", value: 1.5)
        filterImage(image: &image, filterName: "CISharpenLuminance", filterKey: "inputSharpness", value: 1)
        return image
    }
    
    private func filterImage(image: inout CIImage, filterName: String, filterKey: String, value: Float ) {
        let filter = CIFilter(name: filterName)!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(value, forKey: filterKey)
    }

    private func saveImage(_ image: CIImage?) {
        frameCounter += 1
            guard let image = image else {
                return
            }
            let newUIImage = UIImage(ciImage: image)
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: newUIImage)
            }, completionHandler: nil)
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
