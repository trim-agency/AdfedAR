import UIKit
import CoreML
import Vision
import Photos
import ARKit

class CoreMLService {
    var delegate: CoreMLServiceDelegate?
    var hasFoundRune    = false
    let model           = try! VNCoreMLModel(for: AdFed().model)
    var currentFrame: ArFrameData?
    static let instance = CoreMLService()

    func getRuneType() throws {
        DispatchQueue.global().async  {
            do {
                self.hasFoundRune      = false
                guard let currentFrame = self.currentFrame else {
                    self.delegate?.didReceiveRuneRecognitionError(sender: self, error: .missingARFrame)
                    return
                }
                let transformedImage = self.transformBuffer(currentFrame.image, currentFrame.exposure)
                let context         = CIContext()
                let cgImage         = context.createCGImage(transformedImage, from: transformedImage.extent)
                let croppedImage    = UIImage(cgImage: cgImage!).cropToCenter(to: CGSize(width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.width * 0.6))
                let ciImage         = CIImage(image: croppedImage)
                if currentFrame.exposure > 300 && currentFrame.exposure < 600 {
                    print("foo")
                }
                let request         = VNCoreMLRequest(model: self.model, completionHandler: self.pageRecognitionHandler)
                request.usesCPUOnly = true
                let handler         = VNImageRequestHandler(ciImage: ciImage!, options: [:])
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

        filterImage(image: &image, filterName: "CIColorControls", filterKey: "inputContrast", value: 1.1)
        filterImage(image: &image, filterName: "CISharpenLuminance", filterKey: "inputSharpness", value: 1)
        return image
    }
    
    private func modifyExposure(exposure: CGFloat, for image: inout CIImage) {
        var inputEV: Float!
        switch exposure {
        case 0..<300:
            inputEV = 2.5
        case 300..<600:
            inputEV = 0.75
        case 600..<1000:
            inputEV = 0.6
        default:
            inputEV = 0.5
        }
        filterImage(image: &image, filterName: "CIExposureAdjust", filterKey: "inputEV", value: inputEV)
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
            delegate?.didReceiveRuneRecognitionError(sender: self, error: CoreMLError.observationError)
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
            delegate?.didReceiveRuneRecognitionError(sender: self, error: error as! CoreMLError)
            return
        }
        
        if highConfidenceObservation.confidence > 0.90 {
            if let page = Page(rawValue: highConfidenceObservation.identifier)  {
                if hasFoundRune { return }
                delegate?.didRecognizeRune(sender: self, page: page)
                hasFoundRune = true
            } else {
                delegate?.didReceiveRuneRecognitionError(sender: self, error: CoreMLError.observationError)
                log.error("Page not created")
            }
        } else {
            delegate?.didReceiveRuneRecognitionError(sender: self, error: CoreMLError.lowConfidence)
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
