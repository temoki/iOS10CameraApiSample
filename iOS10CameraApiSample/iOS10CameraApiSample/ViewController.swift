//
//  ViewController.swift
//  iOS10CameraApiSample
//
//  Created by temoki on 2016/09/18.
//  Copyright © 2016 temoki. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreImage

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK:- IBOutlets
    
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var imageFormatLabel: UILabel!
    @IBOutlet weak var capturePhotoButton: UIButton!
    
    
    // MARK:- Properties
    
    private var captureSession: AVCaptureSession?
    
    private var imageFormatType: OSType? {
        didSet {
            imageFormatLabel.text = imageFormatName(ofType: imageFormatType)
        }
    }
    
    
    // MARK:- Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let captureSession = self.captureSession {
            captureSession.startRunning()
        } else {
            selectCamera()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let captureSession = self.captureSession, captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK:- Action
    
    @IBAction func selectCameraButtonAction(sender: UIButton) {
        selectCamera()
    }
    
    @IBAction func selectImageFormatButtonAction(sender: UIButton) {
        selectImageFormat()
    }
    
    @IBAction func capturePhotoButtonAction(sender: UIButton) {
        capturePhoto()
    }
    
    @IBAction func photoLibraryButtonAction(sender: UIButton) {
        selectPhoto()
    }
    
    
    // MARK:- Setup Camera
    
    private func selectCamera() {
        let actionSheet = UIAlertController(title: "Select Camera", message: nil, preferredStyle: .actionSheet)
        
        let deviceTypes: [AVCaptureDeviceType: String] = [.builtInWideAngleCamera: "Wide-Angle",
                                                          .builtInTelephotoCamera: "Telephoto",
                                                          .builtInDuoCamera: "Duo"]
        for (deviceType, deviceTypeName) in deviceTypes {
            let discoverySession = AVCaptureDeviceDiscoverySession(
                deviceTypes: [deviceType], mediaType: AVMediaTypeVideo, position: .unspecified)
            guard let discoveredDevices = discoverySession?.devices else {
                continue
            }
            
            for device in discoveredDevices {
                let deviceName = "\(deviceTypeName)(\(device.localizedName ?? "Unknown"))"
                actionSheet.addAction(UIAlertAction(title: deviceName, style: .default, handler: { [weak self] (action) in
                        self?.startCapture(withDevice: device, name: deviceName)
                    }))
            }
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func selectImageFormat() {
        let actionSheet = UIAlertController(title: "Select Image Format", message: nil, preferredStyle: .actionSheet)
        
        if let captureOutput = captureSession?.outputs?.first as? AVCapturePhotoOutput {
            for rawPixelFormat in captureOutput.availableRawPhotoPixelFormatTypes {
                let type = rawPixelFormat.uint32Value as OSType
                let name = imageFormatName(ofType: type)
                actionSheet.addAction(UIAlertAction(title: name, style: .default, handler: { [weak self] (action) in
                    self?.imageFormatType = type
                    }))
            }
        }
        
        let nonRawName = imageFormatName(ofType: nil)
        actionSheet.addAction(UIAlertAction(title: nonRawName, style: .default, handler: { [weak self] (action) in
            self?.imageFormatType = nil
            }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func imageFormatName(ofType type: OSType?) -> String {
        if let type = type {
            return "RAW(\(type)-\(uint32To4CharsString(type as UInt32)))"
        }
        return "JPEG"
    }
    
    private func startCapture(withDevice device: AVCaptureDevice, name: String) {
        capturePhotoButton.isEnabled = false
        imageFormatType = nil

        if captureSession?.isRunning ?? false {
            captureSession?.stopRunning()
        }
        captureSession = nil
        
        cameraLabel.text = name
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            showErrorAlert(message: "Failed to create AVCaptureDeviceInput instance.")
            cameraLabel.text = nil
            return
        }
        
        
        let newCaptureSession = AVCaptureSession()
        newCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto
        newCaptureSession.addInput(deviceInput)
        newCaptureSession.addOutput(AVCapturePhotoOutput())
        
        if let previewLayers = (view.layer.sublayers?.map { $0 as? AVCaptureVideoPreviewLayer }), previewLayers.isEmpty {
            previewLayers.forEach { $0?.session = newCaptureSession }
        } else {
            if let previewLayer = AVCaptureVideoPreviewLayer(session: newCaptureSession) {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
            } else {
                showErrorAlert(message: "Failed to create AVCaptureVideoPreviewLayer instance.")
                cameraLabel.text = nil
            }
        }
        
        newCaptureSession.startRunning()
        captureSession = newCaptureSession
        capturePhotoButton.isEnabled = true
    }
    
    
    // MARK:- Capture Photo
    
    private func capturePhoto() {
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            return
        }
        guard let captureOutput = captureSession.outputs?.first as? AVCapturePhotoOutput else {
            return
        }
        
        let photoSettings: AVCapturePhotoSettings
        
        // Image format
        if let imageFormatType = self.imageFormatType {
            // RAW
            photoSettings = AVCapturePhotoSettings(rawPixelFormatType: imageFormatType)
        } else {
            // JPEG
            photoSettings = AVCapturePhotoSettings()
        }
        photoSettings.isHighResolutionPhotoEnabled = true
        
        // Preview format type
        let previewPixelTypes = photoSettings.availablePreviewPhotoPixelFormatTypes
        previewPixelTypes.forEach { print("\(self.uint32To4CharsString($0.uint32Value))") }
        if let previewPixelType = previewPixelTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                                kCVPixelBufferWidthKey as String: 1600,
                                                kCVPixelBufferHeightKey as String: 1600]
        }
        
        captureOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    private func getSaveDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
    
    private func getSaveFileName(withExtension ext: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        
        let date = dateFormatter.string(from: Date())
        let camera = cameraLabel.text ?? "Unknown-Camera"
        let format = imageFormatLabel.text ?? "Unknown-Format"
        
        return ("\(camera)_\(format)_\(date)" as NSString).appendingPathExtension(ext)
    }
    
    private func saveImage(data: Data, ext: String) {
        guard let saveDirectory = getSaveDirectory() else {
            showErrorAlert(message: "The directory to save image is not found.")
            return
        }

        guard let fileName = getSaveFileName(withExtension: ext) else {
            showErrorAlert(message: "Cannot get file name to save image.")
            return
        }
        
        let filePath = (saveDirectory as NSString).appendingPathComponent(fileName)
        let fileURL = URL(fileURLWithPath: filePath)
        
        do {
            try data.write(to: fileURL)
        } catch let error as NSError {
            showErrorAlert(error: error)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
            }, completionHandler: { [weak self] (success, error) in
                if success {
                    self?.showAlert(title: "Saved", message: filePath)
                } else  {
                    self?.showErrorAlert(error: error)
                }
            })
        
        /*
        if ext == "dng" {
            if let rawFilter = CIFilter(imageURL: fileURL, options: nil) {
                if let outputImage = rawFilter.outputImage {
                    let context: CIContext = CIContext(options: [kCIContextCacheIntermediates: false, kCIContextPriorityRequestLow: true])
                    let jpegURL = URL(fileURLWithPath: filePath + ".jpg")
                    let colorSpaceP3 = CGColorSpace(name: CGColorSpace.displayP3)!
                    do {
                        try context.writeJPEGRepresentation(of: outputImage, to: jpegURL, colorSpace: colorSpaceP3,
                                                            options: [String(kCGImageDestinationLossyCompressionQuality): 1.0])
                    } catch let error as NSError {
                        showErrorAlert(error: error)
                        return
                    }
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: jpegURL)
                        }, completionHandler: { [weak self] (success, error) in
                            if success {
                                self?.showAlert(title: "Saved [JPEG]", message: filePath)
                            } else  {
                                self?.showErrorAlert(error: error)
                            }
                        })
                }
            }
        }
 */

    }
    
    
    // MARK:- Photo Library
    
    private func selectPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    // MARK:- Utilities
    
    private func showErrorAlert(error: Error?) {
        showErrorAlert(message: error?.localizedDescription)
    }
    
    private func showErrorAlert(message: String?) {
        showAlert(title: "Error", message: message)
    }
    
    private func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func printSampleBuffer(buffer: CMSampleBuffer) {
        print("---[CMSampleBuffer]---")
        print("Is valid = \(CMSampleBufferIsValid(buffer))")
        print("Data is ready = \(CMSampleBufferDataIsReady(buffer))")
        CMSampleBufferGetTotalSampleSize(buffer)
        print("Duration = \(CMSampleBufferGetDuration(buffer))")
        print("Output duration = \(CMSampleBufferGetOutputDuration(buffer))")
        print("Decode time stamp = \(CMSampleBufferGetDecodeTimeStamp(buffer))")
        print("Output decode time stamp = \(CMSampleBufferGetOutputDecodeTimeStamp(buffer))")
        print("Presentation time stamp = \(CMSampleBufferGetPresentationTimeStamp(buffer))")
        print("Output presentation time stamp = \(CMSampleBufferGetOutputPresentationTimeStamp(buffer))")
        
        //CMSampleBufferGetOutputSampleTimingInfoArray
        //CMSampleBufferGetAudioStreamPacketDescriptions
        //CMSampleBufferGetAudioStreamPacketDescriptionsPtr
        //CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer
        
        let numSamples = CMSampleBufferGetNumSamples(buffer)
        print("Num samples = \(numSamples)")
        for sampleIndex in 0 ..< numSamples {
            print("Sample[\(sampleIndex)] size = \(CMSampleBufferGetSampleSize(buffer, sampleIndex))")
            //CMSampleBufferGetSampleSizeArray
            //CMSampleBufferGetSampleTimingInfo
            //CMSampleBufferGetSampleAttachmentsArray
            //CMSampleBufferGetSampleTimingInfoArray(
        }
        
        if let formatDescription = CMSampleBufferGetFormatDescription(buffer) {
            printFormatDescription(desc: formatDescription)
        } else {
            print("Format description = nil")
        }

        if let blockBuffer = CMSampleBufferGetDataBuffer(buffer) {
            printBlockBuffer(buffer: blockBuffer)
        } else {
            print("Block buffer = nil")
        }
        
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            printPixelBuffer(buffer: pixelBuffer)
        } else {
            print("Image buffer = nil")
        }
    }
    
    private func printPixelBuffer(buffer: CVPixelBuffer) {
        print("Image buffer =>")
        print("  Width = \(CVPixelBufferGetWidth(buffer))")
        print("  Height = \(CVPixelBufferGetHeight(buffer))")
        print("  Data size = \(CVPixelBufferGetDataSize(buffer))")
        print("  Bytes per row = \(CVPixelBufferGetBytesPerRow(buffer))")
        let type = CVPixelBufferGetPixelFormatType(buffer) as UInt32
        let typeStr = uint32To4CharsString(type)
        print("  Pixel format type = \(type) => \(typeStr)")
        
        let isPlanar = CVPixelBufferIsPlanar(buffer)
        print("  Is planar = \(isPlanar)")
        if isPlanar {
            let planeCount = CVPixelBufferGetPlaneCount(buffer)
            print("  Plane count = \(planeCount)")
            
            for planeIndex in 0 ..< planeCount {
                print("  Plane [\(planeIndex)]")
                print("    Width = \(CVPixelBufferGetWidthOfPlane(buffer, planeIndex))")
                print("    Height = \(CVPixelBufferGetHeightOfPlane(buffer, planeIndex))")
                print("    Bytes per row = \(CVPixelBufferGetBytesPerRowOfPlane(buffer, planeIndex))")
            }
        }
    }
    
    private func printBlockBuffer(buffer: CMBlockBuffer) {
        print("Block buffer =>")
        print("  Is empty = \(CMBlockBufferIsEmpty(buffer))")
        print("  Data length = \(CMBlockBufferGetDataLength(buffer))")
    }
    
    private func printFormatDescription(desc: CMFormatDescription) {
        print("Format description =>")
        let mediaTypeStr: String
        switch CMFormatDescriptionGetMediaType(desc) {
        case kCMMediaType_Video:
            mediaTypeStr = "Video" // 🌟
        case kCMMediaType_Audio:
            mediaTypeStr = "Audio"
        case kCMMediaType_Muxed:
            mediaTypeStr = "Muxed"
        case kCMMediaType_Text:
            mediaTypeStr = "Text"
        case kCMMediaType_ClosedCaption:
            mediaTypeStr = "ClosedCaption"
        case kCMMediaType_Subtitle:
            mediaTypeStr = "Subtitle"
        case kCMMediaType_TimeCode:
            mediaTypeStr = "TimeCode"
        case kCMMediaType_Metadata:
            mediaTypeStr = "Metadata"
        default:
            mediaTypeStr = "Unknown"
        }
        print("  Media type = \(mediaTypeStr)")
        
        let subtype = CMFormatDescriptionGetMediaSubType(desc) as UInt32
        let subtypeStr = uint32To4CharsString(subtype)
        print("  Media sub type = \(subtype) => \(subtypeStr)")

        print("  Extensions = \(CMFormatDescriptionGetExtensions(desc) as? NSDictionary)")
    }
    
    private func uint32To4CharsString(_ value: UInt32) -> String {
        let characters: [unichar] = [unichar((value >> 24) & 0xFF),
                                     unichar((value >> 16) & 0xFF),
                                     unichar((value >> 8) & 0xFF),
                                     unichar((value >> 0) & 0xFF)]
        return NSString(characters: characters, length: 4) as String
    }
    
    
    // MARK:- AVCapturePhotoCaptureDelegate
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {

        if let error = error {
            showErrorAlert(error: error)
            return
        }
        
        guard let buffer = photoSampleBuffer else {
            showErrorAlert(message: "photoSampleBuffer is nil.")
            return
        }
        printSampleBuffer(buffer: buffer)
        
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
            forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                showErrorAlert(message: "Failed to create jpeg data.")
                return
        }
 
        saveImage(data: imageData, ext: "jpg")
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingRawPhotoSampleBuffer rawSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {

        if let error = error {
            showErrorAlert(error: error)
            return
        }
        
        guard let buffer = rawSampleBuffer else {
            showErrorAlert(message: "rawSampleBuffer is nil.")
            return
        }
        printSampleBuffer(buffer: buffer)

        guard let imageData = AVCapturePhotoOutput.dngPhotoDataRepresentation(
            forRawSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                showErrorAlert(message: "Failed to create RAW(DNG) data.")
                return
        }
        
        saveImage(data: imageData, ext: "dng")
    }
    
    
    // MARK:- UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            var text = "Information"
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                text += "\nSize = \(image.size)"
            }
            if let url = info[UIImagePickerControllerReferenceURL] as? URL {
                text += "\nURL = \(url.absoluteString)"
            }
            self?.showAlert(title: "Image", message: text)
        }
    }

}

