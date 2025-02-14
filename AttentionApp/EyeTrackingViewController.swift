import ARKit
import SwiftUI

class EyeTrackingViewController: UIViewController, ARSCNViewDelegate {
    var eyeTrackingCallback: ((Bool) -> Void)?
    private var sceneView: ARSCNView!
    var screenCenter: CGPoint = .zero
    private var isGazeOnTarget: Bool = false
    
    
    private var gazeHistoryCount = 0
    private let requiredConsecutiveGazes = 2 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAR()
        
        print("ARFaceTracking supported: \(ARFaceTrackingConfiguration.isSupported)")
        
        
        screenCenter = view.center
    }
    
    private func setupAR() {
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        
        sceneView.isOpaque = false
        sceneView.alpha = 0
        
        view.addSubview(sceneView)
        
        
        view.sendSubviewToBack(sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if ARFaceTrackingConfiguration.isSupported {
            print("Starting face tracking session...")
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            configuration.maximumNumberOfTrackedFaces = 1
            
           
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            print("Face tracking is not supported on this device")
           
            DispatchQueue.main.async {
                self.eyeTrackingCallback?(true)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    
    func updateTargetPosition(_ position: CGPoint) {
        screenCenter = position
    }
    
    
    private func isGazeOnTarget(_ faceAnchor: ARFaceAnchor) -> Bool {
        let lookAtPoint = faceAnchor.lookAtPoint
        let screenSize = UIScreen.main.bounds.size
        
        
        let screenX = CGFloat((lookAtPoint.x + 1) / 2) * screenSize.width
        let screenY = CGFloat((-lookAtPoint.y + 1) / 2) * screenSize.height
        let gazePoint = CGPoint(x: screenX, y: screenY)
        
        
        let targetRect = CGRect(
            x: screenCenter.x - 80,
            y: screenCenter.y - 80,
            width: 160,
            height: 160
        )
        
        let isLookingAtTarget = targetRect.contains(gazePoint)
        
        
        let leftEyeBlink = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 1.0
        let rightEyeBlink = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 1.0
        let leftEyeSquint = faceAnchor.blendShapes[.eyeSquintLeft]?.floatValue ?? 1.0
        let rightEyeSquint = faceAnchor.blendShapes[.eyeSquintRight]?.floatValue ?? 1.0
        
        let eyesWideOpen = leftEyeBlink < 0.2 && rightEyeBlink < 0.2 &&
                           leftEyeSquint < 0.3 && rightEyeSquint < 0.3
        
        return isLookingAtTarget && eyesWideOpen
    }
    
    
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
       
    }
}
