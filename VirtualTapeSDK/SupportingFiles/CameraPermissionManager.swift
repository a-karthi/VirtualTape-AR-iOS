//
//  CameraPermissionManager.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 18/01/23.
//

import Foundation
import AVFoundation

public enum CameraConfiguration {
    case success
    case failed
    case permissionDenied
}

open class CameraPermissionManager: NSObject {
    
    static public let shared = CameraPermissionManager()
    
    
    private var cameraConfiguration: CameraConfiguration = .failed
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    
    public func attemptToConfigureSession() -> CameraConfiguration {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraConfiguration = .success
            
        case .notDetermined:
            self.sessionQueue.suspend()
            self.requestCameraAccess(completion: { (granted) in
                self.sessionQueue.resume()
            })
            
        case .denied:
            self.cameraConfiguration = .permissionDenied
            
        default:
            break
        }
        return cameraConfiguration
    }
    
    /**
     This method requests for camera permissions.
     */
    private func requestCameraAccess(completion: @escaping (Bool) -> ()) {
        
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            if !granted {
                self.cameraConfiguration = .permissionDenied
            } else {
                self.cameraConfiguration = .success
            }
            completion(granted)
        }
        
    }
    
}
