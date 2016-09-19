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
    private let captureOutput = AVCapturePhotoOutput()
    
    private var selectedPixelFormat: PixelFormat? {
        didSet {
            guard let format = selectedPixelFormat else { return }
            pixelFormatLabel.text = format.description
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
        selectPixelFormat()
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
    
    private var availablePixelFormats: [PixelFormat] {
        var availablePixelFormats: [PixelFormat] = []
        
        for typeNumber in captureOutput.availablePhotoPixelFormatTypes {
            var copiedPixelFormat = PixelFormat.pixelFormat(ofType: typeNumber.uint32Value)
            copiedPixelFormat.isRaw = false
            availablePixelFormats.append(copiedPixelFormat)
        }
        
        for typeNumber in captureOutput.availableRawPhotoPixelFormatTypes {
            var copiedPixelFormat = PixelFormat.pixelFormat(ofType: typeNumber.uint32Value)
            copiedPixelFormat.isRaw = false
            availablePixelFormats.append(copiedPixelFormat)
        }
        
        return availablePixelFormats
    }
    
    private func selectPixelFormat() {
        let actionSheet = UIAlertController(title: "Select Pixel Format", message: nil, preferredStyle: .actionSheet)
        for pixelFormat in availablePixelFormats {
            actionSheet.addAction(UIAlertAction(title: pixelFormat.name, style: .default, handler: { [weak self] (action) in
                self?.selectedPixelFormat = pixelFormat
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func startCapture(withDevice device: AVCaptureDevice, name: String) {
        capturePhotoButton.isEnabled = false

        if captureSession?.isRunning ?? false {
            captureSession?.stopRunning()
        }
        
        cameraLabel.text = name
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            cameraLabel.text = "Error: AVCaptureDeviceInput"
            return
        }
        
        let newCaptureSession = AVCaptureSession()
        newCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto
        newCaptureSession.addInput(deviceInput)
        newCaptureSession.addOutput(captureOutput)
        
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: newCaptureSession) else {
            cameraLabel.text = "Error: AVCaptureVideoPreviewLayer"
            return
        }
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        guard let pixelFormat = availablePixelFormats.last else {
            pixelFormatLabel.text = "Error: Pixel Format"
            return
        }
        selectedPixelFormat = pixelFormat
        
        newCaptureSession.startRunning()
        captureSession = newCaptureSession
        capturePhotoButton.isEnabled = true
    }
    
    private func capturePhoto() {
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            return
        }
        
        guard let pixelFormat = self.selectedPixelFormat else {
            return
        }
        
        let photoSettings: AVCapturePhotoSettings
        if let pixelFormat = selectedPixelFormat, pixelFormat.isRaw ?? false {
            photoSettings = AVCapturePhotoSettings(rawPixelFormatType: pixelFormat.type)
        } else {
            let key = kCVPixelBufferPixelFormatTypeKey as String
            photoSettings = AVCapturePhotoSettings(format: [key: NSNumber(value: pixelFormat.type)])
        }
        captureOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    private func logCaptured(pixelBuffer: CVPixelBuffer) {
        var pixelFormat = PixelFormat.pixelFormat(ofType: CVPixelBufferGetPixelFormatType(pixelBuffer))
        pixelFormat.isRaw = false
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let dataSize = CVPixelBufferGetDataSize(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let isPlanar = CVPixelBufferIsPlanar(pixelBuffer)
        print(" -[Pixel Format]-> \(pixelFormat)")
        print(" -[Width]-> \(width)")
        print(" -[Height]-> \(height)")
        print(" -[Bytes/Row]-> \(bytesPerRow)")
        print(" -[Data Size]-> \(dataSize)")
        print(" -[Is Planar?]-> \(isPlanar)")
        
        if isPlanar {
            let planeCount = CVPixelBufferGetPlaneCount(pixelBuffer)
            var planeWidthArray: [Int] = []
            var planeHeightArray: [Int] = []
            var planeBytesPerRowArray: [Int] = []
            for planeIndex in 0..<planeCount {
                planeWidthArray.append(CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex))
                planeHeightArray.append(CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex))
                planeBytesPerRowArray.append(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex))
            }
            print(" -[Plane Count]-> \(planeCount)")
            print(" -[Plane Width]-> \(planeWidthArray)")
            print(" -[Plane Height]-> \(planeHeightArray)")
            print(" -[Plane Bytes/Row]-> \(planeBytesPerRowArray)")
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
            print(" -[Error]-> \(error)")
            return
        }
        
        guard let photoSampleBuffer = photoSampleBuffer else {
            print(" -[Error]-> photoSampleBuffer is nil")
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(photoSampleBuffer) else {
            print(" -[Error]-> Cannot get image buffer from photoSampleBuffer")
            return
        }
        logCaptured(pixelBuffer: pixelBuffer)
        
        /*
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
            forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                print(" -[Error]-> jpegPhotoDataRepresentation is nil")
                return
        }*/
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags())
        let dataSize = CVPixelBufferGetDataSize(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let imageData = NSData(bytes: baseAddress, length: dataSize)

        // TODO: Save to photo library by Photos.framework

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags())
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingRawPhotoSampleBuffer rawSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?,
                 error: Error?) {
        print(#function)
        if let error = error {
            print(" -[Error]-> \(error)")
            return
        }
        
        guard let rawSampleBuffer = rawSampleBuffer else {
            print(" -[Error]-> rawSampleBuffer is nil")
            return
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(rawSampleBuffer) else {
            print(" -[Error]-> Cannot get image buffer from rawSampleBuffer")
            return
        }
        logCaptured(pixelBuffer: pixelBuffer)
        
        guard let imageData = AVCapturePhotoOutput.dngPhotoDataRepresentation(
            forRawSampleBuffer: rawSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                print(" -[Error]-> dngPhotoDataRepresentation is nil")
                return
        }
        
        // TODO: Save to photo library by Photos.framework
    }
    

}

