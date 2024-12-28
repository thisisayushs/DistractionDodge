import ARKit
import SwiftUI

class EyeTrackingViewController: UIViewController, ARSCNViewDelegate {
    var eyeTrackingCallback: ((Bool) -> Void)?
    private var sceneView: ARSCNView!
    var screenCenter: CGPoint = .zero
    private var isGazeOnTarget: Bool = false
    
    // Add properties for smoothing
    private var gazeHistoryCount = 0
    private let requiredConsecutiveGazes = 2 // Changed from 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAR()
        // Set up debug information
        print("ARFaceTracking supported: \(ARFaceTrackingConfiguration.isSupported)")
        
        // Get screen center point
        screenCenter = view.center
    }
    
    private func setupAR() {
        // Initialize AR scene view
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Hide the camera feed by making the view transparent
        sceneView.isOpaque = false
        sceneView.alpha = 0
        
        view.addSubview(sceneView)
        
        // Ensure AR view stays behind other content
        view.sendSubviewToBack(sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if ARFaceTrackingConfiguration.isSupported {
            print("Starting face tracking session...")
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            configuration.maximumNumberOfTrackedFaces = 1
            
            // Run with options to reset tracking
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            print("Face tracking is not supported on this device")
            // Fallback to always consider as gazing for testing
            DispatchQueue.main.async {
                self.eyeTrackingCallback?(true)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // Add method to update target position
    func updateTargetPosition(_ position: CGPoint) {
        screenCenter = position
    }
    
    // Simplified gaze detection
    private func isGazeOnTarget(_ faceAnchor: ARFaceAnchor) -> Bool {
        let lookAtPoint = faceAnchor.lookAtPoint
        let screenSize = UIScreen.main.bounds.size
        
        // Convert normalized coordinates to screen points
        let screenX = CGFloat((lookAtPoint.x + 1) / 2) * screenSize.width
        let screenY = CGFloat((-lookAtPoint.y + 1) / 2) * screenSize.height
        let gazePoint = CGPoint(x: screenX, y: screenY)
        
        // Define target area
        let targetRect = CGRect(
            x: screenCenter.x - 80,
            y: screenCenter.y - 80,
            width: 160,
            height: 160
        )
        
        let isLookingAtTarget = targetRect.contains(gazePoint)
        
        // Check if eyes are open
        let leftEyeBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 1.0
        let rightEyeBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 1.0
        let leftEyeSquint = faceAnchor.blendShapes[.eyeSquintLeft]?.floatValue ?? 1.0
        let rightEyeSquint = faceAnchor.blendShapes[.eyeSquintRight]?.floatValue ?? 1.0
        
        let eyesWideOpen = leftEyeBlink < 0.2 && rightEyeBlink < 0.2 &&
                           leftEyeSquint < 0.3 && rightEyeSquint < 0.3
        
        return isLookingAtTarget && eyesWideOpen
    }
    
    // Update renderer function
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        let currentGaze = isGazeOnTarget(faceAnchor)
        
        if currentGaze {
            gazeHistoryCount += 1
        } else {
            gazeHistoryCount = 0
        }
        
        let newGazeState = gazeHistoryCount >= requiredConsecutiveGazes
        
        if newGazeState != isGazeOnTarget {
            isGazeOnTarget = newGazeState
            DispatchQueue.main.async {
                self.eyeTrackingCallback?(self.isGazeOnTarget)
            }
        }
    }
}

extension EyeTrackingViewController: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR Session failed with error: \(error)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("AR Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("AR Session interruption ended")
        // Reset tracking when interruption ends
        session.run(session.configuration!, options: [.resetTracking, .removeExistingAnchors])
    }
}

struct EyeTrackingView: UIViewControllerRepresentable {
    let onGazeUpdate: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> EyeTrackingViewController {
        let viewController = EyeTrackingViewController()
        viewController.eyeTrackingCallback = onGazeUpdate
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: EyeTrackingViewController, context: Context) {
        // No updates needed since we removed distraction tracking
    }
}
