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

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var pixelFormatLabel: UILabel!
    @IBOutlet weak var capturePhotoButton: UIButton!
    
    private var captureSession: AVCaptureSession?
    
    private var imageFormatType: OSType? {
        didSet {
            if let type = imageFormatType {
                pixelFormatLabel.text = "RAW (\(type))"
            } else {
                pixelFormatLabel.text = "JPEG"
            }
        }
    }
    
    private let deviceTypes: [AVCaptureDeviceType: String]
        = [.builtInWideAngleCamera: "Wide Angle",
           .builtInTelephotoCamera: "Telephoto",
           .builtInDuoCamera: "Duo"]

    
    // MARK:- Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectCamera()
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
    
    @IBAction func selectPixelFormatButtonAction(sender: UIButton) {
        selectPixelFormatType()
    }
    
    @IBAction func capturePhotoButtonAction(sender: UIButton) {
        capturePhoto()
    }
    
    
    // MARK:- Private
    
    private func selectCamera() {
        var devicesOfType = [AVCaptureDeviceType: [AVCaptureDevice]]()
        for (type, _) in deviceTypes {
            guard let deviceDiscoverySession
                = AVCaptureDeviceDiscoverySession(deviceTypes: [type],
                                                  mediaType: AVMediaTypeVideo,
                                                  position: .unspecified) else {
                                                    continue
            }
            
            guard let discoveredDevices = deviceDiscoverySession.devices else {
                continue
            }
            
            devicesOfType[type] = discoveredDevices
        }
        
        let actionSheet = UIAlertController(title: "Select Camera", message: nil, preferredStyle: .actionSheet)
        for (type, devices) in devicesOfType {
            let typeName = deviceTypes[type] ?? "Unknown"
            for device in devices {
                let name = "\(typeName) [\(device.localizedName ?? "Unknown")]"
                actionSheet.addAction(UIAlertAction(title: name, style: .default, handler: { [weak self, weak device] (action) in
                    guard let device = device else { return }
                    self?.startCapture(withDevice: device, name: name)
                }))
            }
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func selectPixelFormatType() {
        let actionSheet = UIAlertController(title: "Select Image Format", message: nil, preferredStyle: .actionSheet)
        if let captureOutput = captureSession?.outputs?.first as? AVCapturePhotoOutput {
            for rawPixelFormat in captureOutput.availableRawPhotoPixelFormatTypes {
                actionSheet.addAction(UIAlertAction(title: "RAW (\(rawPixelFormat))", style: .default, handler: { [weak self] (action) in
                    self?.imageFormatType = rawPixelFormat.uint32Value
                    }))
            }
        }
        actionSheet.addAction(UIAlertAction(title: "JPEG", style: .default, handler: { [weak self] (action) in
            self?.imageFormatType = nil
            }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
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
            cameraLabel.text = "Error: AVCaptureDeviceInput"
            return
        }
        
        let newCaptureSession = AVCaptureSession()
        newCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto
        newCaptureSession.addInput(deviceInput)
        newCaptureSession.addOutput(AVCapturePhotoOutput())
        
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: newCaptureSession) else {
            cameraLabel.text = "Error: AVCaptureVideoPreviewLayer"
            return
        }
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        
        newCaptureSession.startRunning()
        captureSession = newCaptureSession
        capturePhotoButton.isEnabled = true
    }
    
    private func capturePhoto() {
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            return
        }
        guard let captureOutput = captureSession.outputs?.first as? AVCapturePhotoOutput else {
            return
        }
        
        let photoSettings: AVCapturePhotoSettings
        if let imageFormatType = self.imageFormatType {
            // RAW
            photoSettings = AVCapturePhotoSettings(rawPixelFormatType: imageFormatType)
        } else {
            // JPEG
            photoSettings = AVCapturePhotoSettings()
        }
        
        captureOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    private func saveImage(data: Data) {
        if let image = UIImage(data: data) {
            logImage(image: image)
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(image:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    private func logImage(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        print("[width] \(cgImage.width)")
        print("[height] \(cgImage.height)")
        print("[bytesPerRow] \(cgImage.bytesPerRow)")
        print("[bitsPerPixel] \(cgImage.bitsPerPixel)")
        print("[bitsPerComponent] \(cgImage.bitsPerComponent)")
        print("[shouldInterpolate] \(cgImage.shouldInterpolate)")
        print("[isMask] \(cgImage.isMask)")
        
        let alphaInfo: String
        switch cgImage.alphaInfo {
        case .none:
            alphaInfo = "none"
        case .premultipliedLast:
            alphaInfo = "premultipliedLast"
        case .premultipliedFirst:
            alphaInfo = "premultipliedFirst"
        case .last:
            alphaInfo = "last"
        case .first:
            alphaInfo = "first"
        case .noneSkipLast:
            alphaInfo = "noneSkipLast"
        case .noneSkipFirst:
            alphaInfo = "noneSkipFirst"
        case .alphaOnly:
            alphaInfo = "alphaOnly"
        }
        print("[alphaInfo] \(alphaInfo)")
        
        let renderingIntent: String
        switch cgImage.renderingIntent {
        case .defaultIntent:
            renderingIntent = "defaultIntent"
        case .absoluteColorimetric:
            renderingIntent = "absoluteColorimetric"
        case .relativeColorimetric:
            renderingIntent = "relativeColorimetric"
        case .perceptual:
            renderingIntent = "perceptual"
        case .saturation:
            renderingIntent = "saturation"
        }
        print("[renderingIntent] \(renderingIntent)")
        
        var bitmapInfo: [String] = []
        if cgImage.bitmapInfo.contains(.alphaInfoMask) { bitmapInfo.append("alphaInfoMask") }
        if cgImage.bitmapInfo.contains(.byteOrder16Big) { bitmapInfo.append("byteOrder16Big") }
        if cgImage.bitmapInfo.contains(.byteOrder16Little) { bitmapInfo.append("byteOrder16Little") }
        if cgImage.bitmapInfo.contains(.byteOrder32Big) { bitmapInfo.append("byteOrder32Big") }
        if cgImage.bitmapInfo.contains(.byteOrder32Little) { bitmapInfo.append("byteOrder32Little") }
        if cgImage.bitmapInfo.contains(.floatComponents) { bitmapInfo.append("floatComponents") }
        print("[bitmapInfo] \(bitmapInfo)")
    }
    
    private func showErrorAlert(_ error: Error) {
        showAlert(title: "Error", message: error.localizedDescription)
    }
    
    private func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        if let error = error {
            showErrorAlert(error)
        } else {
            showAlert(title: "Saved.", message: nil)
        }
    }
    
    // MARK:- AVCapturePhotoCaptureDelegate
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        print(#function)
        if let error = error {
            showErrorAlert(error)
            return
        }
        
        guard let photoSampleBuffer = photoSampleBuffer else {
            showAlert(title: "Error", message: "photoSampleBuffer is nil.")
            return
        }
        
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
            forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                showAlert(title: "Error", message: "Failed to create JPEG data.")
                return
        }
 
        saveImage(data: imageData)
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingRawPhotoSampleBuffer rawSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        print(#function)
        if let error = error {
            showErrorAlert(error)
            return
        }
        
        guard let rawSampleBuffer = rawSampleBuffer else {
            showAlert(title: "Error", message: "rawSampleBuffer is nil.")
            return
        }

        guard let imageData = AVCapturePhotoOutput.dngPhotoDataRepresentation(
            forRawSampleBuffer: rawSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                showAlert(title: "Error", message: "Failed to create RAW(DNG) data.")
                return
        }
        
        saveImage(data: imageData)
    }
    

}

