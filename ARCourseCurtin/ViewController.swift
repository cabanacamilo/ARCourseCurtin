//
//  ViewController.swift
//  ARCourseCurtin
//
//  Created by Camilo Cabana on 7/08/20.
//  Copyright © 2020 Camilo Cabana. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var podiumAdded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        
        // Set the scene to the view
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.horizontal]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if !podiumAdded {
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlane])
            if let result = hitTestResult.first {
                createPodium(result: result)
                podiumAdded = true
            }
        } else {
            createBall()
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            let floor = self.createFloor(planeAnchor: planeAnchor)
            node.addChildNode(floor)
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            for node in node.childNodes {
                node.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
                if let plane = node.geometry as? SCNPlane {
                    plane.width = CGFloat(planeAnchor.extent.x)
                    plane.height = CGFloat(planeAnchor.extent.z)
                }
            }
        }
    }
    
    func createFloor(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let node = SCNNode()
        let geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        node.geometry = geometry
        node.eulerAngles.x = -Float.pi / 2
        node.opacity = 0.5
        return node
    }

    func createPodium(result: ARHitTestResult) {
        let podiumScene = SCNScene(named: "art.scnassets/podium.scn")
        guard let podiumNode = podiumScene?.rootNode.childNode(withName: "podium", recursively: false) else { return }
        let planePosition = result.worldTransform.columns.3
        podiumNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: podiumNode, options: nil))
        podiumNode.position = SCNVector3(planePosition.x, planePosition.y, planePosition.z)
        sceneView.scene.rootNode.addChildNode(podiumNode)
    }
    
    func createBall() {
        guard let currentFrame = sceneView.session.currentFrame else { return }
        let ball = SCNNode(geometry: SCNSphere(radius: 0.125))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball, options: nil))
        ball.physicsBody = physicsBody
        let cameraTransform = SCNMatrix4(currentFrame.camera.transform)
        let power = Float(10)
        let force = SCNVector3(-cameraTransform.m31 * power, -cameraTransform.m32 * power, -cameraTransform.m33 * power)
        ball .physicsBody?.applyForce(force, asImpulse: true)
        ball.transform = cameraTransform
        sceneView.scene.rootNode.addChildNode(ball)
    }
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
