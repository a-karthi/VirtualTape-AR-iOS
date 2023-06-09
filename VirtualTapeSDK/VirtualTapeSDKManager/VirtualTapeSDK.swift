//
//  VirtualTapeSDK.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 18/01/23.
//

import Foundation
import ARKit

open class VirtualTapeSDK: CameraPermissionManager {
    
    private var ocrRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    public var sceneView: VirtualObjectARView!
    
    public let virtualObjectLoader = VirtualObjectLoader()
    
    let coachingOverlay = ARCoachingOverlayView()
    
    public var focusSquare = FocusSquare()
    
    public var delegate: VirtualTapeDelegate?
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    public var virtualObjectInteraction: VirtualObjectInteraction?
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private lazy var realTimeLine: LineNode = {
        let line = LineFactory.createMeasurementLine()
        line.update(with: .stripes)
        line.isHidden = true
        return line
    }()
    
    public init(_ arContainerView: VirtualObjectARView) {
       
        self.sceneView = arContainerView
        
//        arContainerView.addSubview(self.sceneView)
//        
//        self.sceneView.frame = arContainerView.frame
        
        super.init()
        
        self.virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView, tapeSDK: self)
        
        impactFeedbackGenerator.prepare()
        
        sceneView.delegate = self
        
        sceneView.session.delegate = self
        
        // Set up coaching overlay.
        setupCoachingOverlay(arContainerView)

        // Set up scene content.
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
    }
    
    func updateFocusSquare(isObjectVisible: Bool) {
        if isObjectVisible || coachingOverlay.isActive {
            focusSquare.unhide()
        } else {
            focusSquare.unhide()
            print("TRY MOVING LEFT OR RIGHT")
            //statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        if let pos = self.detectNodes(self.sceneView.center) {
            print(pos.name ?? "")
            return
        }
        
        // Perform ray casting only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let query = sceneView.getRaycastQuery(),
            let result = sceneView.castRay(for: query).first {
            
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
            }
//            if !coachingOverlay.isActive {
//                addObjectButton.isHidden = false
//            }
//            statusViewController.cancelScheduledMessage(for: .focusSquare)
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
//            addObjectButton.isHidden = true
        }
    }
    
    // MARK: - Focus Square
    func detectNodes(_ location: CGPoint) -> SCNNode? {
        //let hitTestResults = self.sceneView.hitTest(location)
        let hitTestResults = sceneView.hitTest(location, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue,
            SCNHitTestOption.ignoreHiddenNodes: false,
            SCNHitTestOption.ignoreChildNodes: false
        ])
        let radius: Float = 0.05
        let nodes = hitTestResults.compactMap({$0.node as? VirtualObject})
        guard let nearestNode = nodes.filter({$0.position.distance(to: focusSquare.position) < radius}).first else {return nil}
        let distance = nearestNode.position.distance(to: focusSquare.position)
        print(distance)
        if focusSquare.position != nearestNode.position {
            self.impactFeedbackGenerator.impactOccurred()
            self.focusSquare.position = nearestNode.position
        }
        return nearestNode
    }
    
    func updateRealTimeLine(_ startPoint: SCNVector3 , _ endPoint: SCNVector3) {
            self.realTimeLine.isHidden = false
            let lookAt = endPoint - startPoint
            let height = lookAt.length()
            let y = lookAt.normalized()
            let up = lookAt.cross(vector: endPoint).normalized()
            let x = y.cross(vector: up).normalized()
            let z = x.cross(vector: y).normalized()
            let transform = SCNMatrix4(x: x, y: y, z: z, w: startPoint)
            realTimeLine.cylinderGeometry.height = CGFloat(height)
            realTimeLine.transform = SCNMatrix4MakeTranslation(0.0, height / 2.0, 0.0) * transform
            sceneView.scene.rootNode.addChildNode(realTimeLine)
    }
    
    func hideRealTimeLine() {
        self.realTimeLine.isHidden = true
        self.realTimeLine.removeFromParentNode()
    }
    
    public func resetTracking() {
        virtualObjectInteraction?.selectedObject = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        print("FIND A SURFACE TO PLACE AN OBJECT")
    }
    
    public func pauseARSession() {
        session.pause()
    }
    
}


extension VirtualTapeSDK: ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        let isAnyObjectInView = virtualObjectLoader.dotObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        DispatchQueue.main.async {
            self.updateFocusSquare(isObjectVisible: isAnyObjectInView)
            if self.virtualObjectLoader.dotObjects.count % 2 != 0 {
                guard let last = self.virtualObjectLoader.dotObjects.last else {return}
                self.updateRealTimeLine(last.position, self.focusSquare.physicsBody?.centerOfMassOffset ?? self.focusSquare.position)
            }
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            //self.statusViewController.cancelScheduledMessage(for: .planeEstimation)
            //self.statusViewController.showMessage("SURFACE DETECTED")
            if self.virtualObjectLoader.dotObjects.isEmpty {
                //self.statusViewController.scheduleMessage("TAP + TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .contentPlacement)
            }
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        updateQueue.async {
            if let objectAtAnchor = self.virtualObjectLoader.dotObjects.first(where: { $0.anchor == anchor }) {
                objectAtAnchor.simdPosition = anchor.transform.translation
                objectAtAnchor.anchor = anchor
            }
        }
    }
    
    /// - Tag: ShowVirtualContent
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        //statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
//        switch camera.trackingState {
//        case .notAvailable, .limited:
//            print(camera.trackingState.presentationString)
//            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
//        case .normal:
//            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
//            showVirtualContent()
//        }
    }

    func showVirtualContent() {
        virtualObjectLoader.dotObjects.forEach { $0.isHidden = false }
    }

    public func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            print( "The AR session failed.")
            print(errorMessage)
            //self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    public func sessionWasInterrupted(_ session: ARSession) {
        // Hide content before going into the background.
        hideVirtualContent()
    }
    
    /// - Tag: HideVirtualContent
    func hideVirtualContent() {
        virtualObjectLoader.dotObjects.forEach { $0.isHidden = true }
    }

    /*
     Allow the session to attempt to resume after an interruption.
     This process may not succeed, so the app must be prepared
     to reset the session if the relocalizing status continues
     for a long time -- see `escalateFeedback` in `StatusViewController`.
     */
    /// - Tag: Relocalization
    public func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
