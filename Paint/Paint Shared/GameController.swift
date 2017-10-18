//
//  GameController.swift
//  Paint Shared
//
//  Created by Andrew Finke on 10/15/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import SceneKit

#if os(macOS)
    typealias SCNColor = NSColor
#else
    typealias SCNColor = UIColor
#endif

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Wall      : UInt32 = 0b1       // 1
    static let PaintBall : UInt32 = 0b10      // 2
    static let Target    : UInt32 = 0b100      // 2
}

class GameController: NSObject, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer

    var cameraNode: SCNNode!
    
    init(sceneRenderer renderer: SCNSceneRenderer) {
        sceneRenderer = renderer
        scene = SCNScene(named: "Art.scnassets/ship.scn")!
        
        super.init()
        
        sceneRenderer.delegate = self
     
        sceneRenderer.scene = scene


        scene.physicsWorld.gravity = SCNVector3Make(0, -9.8, 0);

        let plabne = scene.rootNode.childNode(withName: "plane", recursively: true)!
        plabne.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: plabne, options: nil))

        plabne.physicsBody?.collisionBitMask = Int(PhysicsCategory.Wall | PhysicsCategory.PaintBall)
        scene.physicsWorld.contactDelegate = self

        createTargetNode()

        cameraNode = scene.rootNode.childNode(withName: "cameraNode", recursively: false)




     //   sceneRenderer.pointOfView = cameraNode
    }

    func createTargetNode() {
        let targetGeometry = SCNCylinder(radius: 2, height: 0.25)
        let targetNode = SCNNode(geometry: targetGeometry)
        targetNode.name = "targetNode"
        targetNode.position = SCNVector3(0,0,-5)
        targetNode.rotation = SCNVector4(1, 0, 0, SCNFloat.pi / 2)
        scene.rootNode.addChildNode(targetNode)
        targetGeometry.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "Target")
        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = SCNColor.white
        let targetMaterial = SCNMaterial()
        targetMaterial.diffuse.contents = #imageLiteral(resourceName: "Target")
        targetGeometry.materials = [sideMaterial, targetMaterial, targetMaterial]

        let physicsBody = SCNPhysicsBody(type: .static,
                                         shape: SCNPhysicsShape(geometry: targetGeometry, options: nil))

        //physicsBody.collisionBitMask = Int(PhysicsCategory.Target | PhysicsCategory.PaintBall)
        physicsBody.contactTestBitMask = Int(PhysicsCategory.Target | PhysicsCategory.PaintBall)
        targetNode.physicsBody = physicsBody

        targetNode.runAction(.repeatForever(.sequence([
            .moveBy(x: 0, y: 10, z: 0, duration: 2.0),
            .moveBy(x: 0, y: -10, z: 0, duration: 2.0)
            ])))
    }



    func launch() {
        let paintBallSphere = SCNSphere(radius: 0.5)
        let paintBall = SCNNode(geometry: paintBallSphere)
        paintBall.name = "paintBall"

        paintBall.geometry?.firstMaterial?.diffuse.contents = SCNColor(calibratedHue: rand(), saturation: 1, brightness: 1, alpha: 1)
        //  paintBall.geometry?.firstMaterial?.reflective.contents = #imageLiteral(resourceName: "texture.png")
        paintBall.geometry?.firstMaterial?.fresnelExponent = 1.0

        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: paintBallSphere, options: nil))
        physicsBody.restitution = 0.9
        physicsBody.collisionBitMask = Int(PhysicsCategory.Wall)
        physicsBody.contactTestBitMask = Int(PhysicsCategory.Wall)

        paintBall.physicsBody = physicsBody

        paintBall.position = SCNVector3(0, -0, 15)//cameraNode.position// - SCNVector3(0, -5, 0)

        scene.rootNode.addChildNode(paintBall)

        if let camera = sceneRenderer.pointOfView {

            print(camera.eulerAngles)

            print()
        }


        paintBall.physicsBody?.velocity = SCNVector3(0, rand(lowerBound: 10, upperBound: 30), rand(lowerBound: -25, upperBound: -15))
    }
    
    func highlightNodes(atPoint point: CGPoint) {
        let hitResults = self.sceneRenderer.hitTest(point, options: [:])
        for result in hitResults {
            // get its material
            guard let material = result.node.geometry?.firstMaterial else {
                return
            }
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = SCNColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = SCNColor.red
            
            SCNTransaction.commit()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called before each frame is rendered
    }


    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {

        if contact.nodeA.name == "paintBall" && contact.nodeB.name == "paintBall" {
            return
        }

        let particleSystem = SCNParticleSystem(named: "plok.scnp", inDirectory: "Art.scnassets")!
        particleSystem.particleColor = contact.nodeB.geometry?.firstMaterial?.diffuse.contents as! SCNColor
        let particleSystemNode = SCNNode()
        particleSystemNode.addParticleSystem(particleSystem)
        particleSystemNode.position = contact.contactPoint

        scene.rootNode.addChildNode(particleSystemNode)


        if contact.nodeA.name == "targetNode" {
            let contactPoint = contact.contactPoint
            let targetCenter = contact.nodeA.position
            let offsetPoint = contactPoint - targetCenter

            let distance = 100 - sqrt(pow(offsetPoint.x, 2) + pow(offsetPoint.y, 2)) * 50

            contact.nodeA.runAction(.rotateBy(x: 0, y: SCNFloat.pi, z: 0, duration: 0.15))

            if contact.nodeB.parent != nil {
                //contact.nodeB.runAction(.removeFromParentNode())
            }
            
           
            print(distance)
            print()
        } else if contact.nodeB.name == "paintBall" {
            if contact.nodeB.parent != nil {
               // contact.nodeB.runAction(.removeFromParentNode())
            }
        }
    }
    

    func rand(lowerBound: CGFloat? = nil, upperBound: CGFloat? = nil) -> CGFloat {
        if lowerBound == nil && upperBound == nil {
            return CGFloat(arc4random()) / CGFloat(UInt32.max)
        } else if let lowerBound = lowerBound, let upperBound = upperBound {
            return lowerBound + (CGFloat(arc4random()) / CGFloat(UInt32.max)) * (upperBound - lowerBound)
        } else if let upperBound = upperBound {
            return (CGFloat(arc4random()) / CGFloat(UInt32.max)) * upperBound
        } else {
            fatalError("Need upper bound if lower bound set.")
        }
    }

}

extension SCNVector3 {
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
}

