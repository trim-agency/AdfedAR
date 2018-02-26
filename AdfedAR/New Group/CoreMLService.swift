import UIKit
import CoreML
import Vision
import Photos
import ARKit

class CoreMLService {
    var delegate: CoreMLServiceDelegate?
    var hasFoundPage = false
    let model           = try! VNCoreMLModel(for: AdFed().model)
    var currentFrame: ArFrameData?
    static let instance = CoreMLService()

    func getPageType() throws {
        DispatchQueue.global().async  {
            do {
                self.hasFoundPage        = false
                guard let currentFrame = self.currentFrame else {
                    log.debug("Current frame nil")
                    return
                }
                let transformedImage = self.transformBuffer(currentFrame.image, currentFrame.exposure)
                let context         = CIContext()
                let cgImage         = context.createCGImage(transformedImage, from: transformedImage.extent)
                let croppedImage    = UIImage(cgImage: cgImage!).cropToCenter(to: CGSize(width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.width * 0.6))
                let ciImage         = CIImage(image: croppedImage)
                let request         = VNCoreMLRequest(model: self.model, completionHandler: self.pageRecognitionHandler)
                request.usesCPUOnly = true
                let handler         = VNImageRequestHandler(ciImage: ciImage!, options: [:])
                log.debug("Performoing request")
                try handler.perform([request])
            } catch {
                log.debug("handler error")
            }
        }
    }
    
    private func transformBuffer(_ pixelBuffer: CVPixelBuffer, _ exposure: CGFloat?) -> CIImage {
        var image = CIImage(cvPixelBuffer: pixelBuffer)
        if let exposure = exposure {
            modifyExposure(exposure: exposure, for: &image)
        }
        
        filterImage(image: &image, filterName: "CIColorControls", filterKey: "inputContrast", value: 1.2)
        filterImage(image: &image, filterName: "CISharpenLuminance", filterKey: "inputSharpness", value: 1)
        return image
    }
    
    private func modifyExposure(exposure: CGFloat, for image: inout CIImage) {
        switch exposure {
        case 0..<1000:
            log.debug("low light")
        case 1000..<2000:
            log.debug("above neutral")
        default:
            log.debug("Ambience error")
        }
    }
    
    private func filterImage(image: inout CIImage, filterName: String, filterKey: String, value: Float ) {
        let filter = CIFilter(name: filterName)!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(value, forKey: filterKey)
        image = filter.outputImage!
    }

    func pageRecognitionHandler(request: VNRequest, error: Error?) {
        if error == nil {
            guard let results = request.results as? [VNClassificationObservation] else {
                log.error("Classification downcast error")
                return
            }
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
        
        if highConfidenceObservation.confidence > 0.90 {
            if let page = Page(rawValue: highConfidenceObservation.identifier)  {
                if hasFoundPage { return }
                delegate?.didRecognizePage(sender: self, page: page)
                hasFoundPage = true
            } else {
                delegate?.didReceiveRecognitionError(sender: self, error: CoreMLError.observationError)
                log.error("Page not created")
            }
        } else {
            log.debug(highConfidenceObservation.confidence)
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
