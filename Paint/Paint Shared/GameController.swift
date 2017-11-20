//
//  GameController.swift
//  Paint Shared
//
//  Created by Andrew Finke on 10/15/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import SceneKit
import SpriteKit

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
    static let Target    : UInt32 = 0b100     // 2
}

class GameController: NSObject, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer

    var cameraNode: SCNNode!
    var acameraNode: SCNNode!

    let scale = CGFloat(10.0)
    
    init(sceneRenderer renderer: SCNSceneRenderer) {
        sceneRenderer = renderer
        scene = SCNScene(named: "Art.scnassets/ship.scn")!
        
        super.init()
        
        sceneRenderer.delegate = self
     
        sceneRenderer.scene = scene


        scene.physicsWorld.gravity = SCNVector3Make(0, -9.8, 0);

        let plane = scene.rootNode.childNode(withName: "plane", recursively: true)!
        acameraNode = plane

        plane.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: plane, options: nil))
        plane.physicsBody?.categoryBitMask = Int(PhysicsCategory.Wall)
        plane.physicsBody?.collisionBitMask = Int(PhysicsCategory.PaintBall)
        scene.physicsWorld.contactDelegate = self

        let spriteScene = SKScene(size: CGSize(width: 50.0 * scale, height: 50.0 * scale))
        spriteScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spriteScene.backgroundColor = SCNColor.clear
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = spriteScene
        plane.geometry?.firstMaterial = planeMaterial

       // createTargetNode()


        cameraNode = scene.rootNode.childNode(withName: "cameraNode", recursively: false)

        createTargetNode(position: SCNVector3(15,-5,-4))
        createTargetNode(position: SCNVector3(0,-5,-4))
        createTargetNode(position: SCNVector3(-15,-5,-4))
    }

    func createTargetNode(position: SCNVector3) {
        let targetNode = TargetNode()
        targetNode.position = position
        scene.rootNode.addChildNode(targetNode)
        targetNode.runAction(.repeatForever(.sequence([
            .moveBy(x: 0, y: 10, z: 0, duration: 2.0),
            .moveBy(x: 0, y: -10, z: 0, duration: 2.0)
            ])))
    }

    func launch() {
        let paintBallSphere = SCNSphere(radius: 0.5)
        let paintBall = SCNNode(geometry: paintBallSphere)
        paintBall.name = "paintBall"

        #if os(macOS)
            paintBall.geometry?.firstMaterial?.diffuse.contents = SCNColor(calibratedHue: rand(), saturation: 1, brightness: 1, alpha: 1)
        #else
            paintBall.geometry?.firstMaterial?.diffuse.contents = SCNColor(hue: rand(), saturation: 1, brightness: 1, alpha: 1)
        #endif


        //  paintBall.geometry?.firstMaterial?.reflective.contents = #imageLiteral(resourceName: "texture.png")
        paintBall.geometry?.firstMaterial?.fresnelExponent = 1.0

        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: paintBallSphere, options: nil))
        physicsBody.restitution = 0.9
        physicsBody.categoryBitMask = Int(PhysicsCategory.PaintBall)
        physicsBody.collisionBitMask = Int(PhysicsCategory.Wall | PhysicsCategory.Target)
        physicsBody.contactTestBitMask = Int(PhysicsCategory.Wall | PhysicsCategory.Target)

        paintBall.physicsBody = physicsBody

        paintBall.position = sceneRenderer.pointOfView!.position - SCNVector3(0, 2, 2.5)// SCNVector3(0, -2, 12.5)//cameraNode.position// - SCNVector3(0, -5, 0)

        scene.rootNode.addChildNode(paintBall)

        if let camera = sceneRenderer.pointOfView {

        }


        guard let pointOfView = sceneRenderer.pointOfView else {
            return
        }

        //Creating unit vector
        let unitVector = GLKVector4Make(0, 0, -4, 4)
        //converting tranform matrix
        let glktranform =  SCNMatrix4ToGLKMatrix4(pointOfView.transform)
        //multiply unit vector with transform matrix
        let rotatedMatrix = GLKMatrix4MultiplyVector4(glktranform, unitVector)


        paintBall.physicsBody?.velocity = SCNVector3(-rotatedMatrix.x, -rotatedMatrix.y, -rotatedMatrix.z)
    }

    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called before each frame is rendered
    }


    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let color = contact.nodeB.geometry?.firstMaterial?.diffuse.contents as? SCNColor else {
            return
        }

        if let targetNode = contact.nodeA as? TargetNode,
            let spriteScene = targetNode.geometry?.materials[1].diffuse.contents as? SKScene {
            targetNode.didHit(color: color)

            let contactScenePoint = scene.rootNode.convertPosition(contact.contactPoint, to: targetNode)
            let contactPoint = CGPoint(x: CGFloat(contactScenePoint.x), y: CGFloat(contactScenePoint.z))
            let distance = sqrt(contactPoint.x*contactPoint.x + contactPoint.y*contactPoint.y)
            print(distance)
//            let targetCenter = contact.nodeA.position
//            let offsetPoint = contactPoint - targetCenter




            let sprite = SKSpriteNode(imageNamed: "splash.png")
            sprite.color = color.withAlphaComponent(0.5)
            sprite.colorBlendFactor = 1
            sprite.size = CGSize(width: 30, height: 30)
            sprite.zRotation = rand(lowerBound: 0, upperBound: CGFloat.pi * 200) / 100

            sprite.position = CGPoint(x: CGFloat(contactPoint.y) * 150 / 4,
                                      y: CGFloat(contactPoint.x) * 150 / 4)

            spriteScene.addChild(sprite)

          // print(distance)
        } else if let planeNode = contact.nodeA as? SCNNode,
            let spriteScene = planeNode.geometry?.firstMaterial?.diffuse.contents as? SKScene {
            let sprite = SKSpriteNode(imageNamed: "splash.png")
            sprite.color = color.withAlphaComponent(0.75)
            sprite.colorBlendFactor = 1
            sprite.size = CGSize(width: 10, height: 10)
sprite.zRotation = rand(lowerBound: 0, upperBound: CGFloat.pi * 200) / 100
            #if os(macOS)
                sprite.position = CGPoint(x: (contact.contactPoint.x * scale) + sprite.size.width,
                                          y: (-contact.contactPoint.y * scale) + sprite.size.height / 2 * scale)
            #else
                sprite.position = CGPoint(x: (CGFloat(contact.contactPoint.x) * scale) + sprite.size.width,
                                          y: (CGFloat(-contact.contactPoint.y) * scale) + sprite.size.height / 2 * scale)
            #endif

            spriteScene.addChild(sprite)

            let particleSystem = SCNParticleSystem(named: "plok.scnp", inDirectory: "Art.scnassets")!
            particleSystem.particleColor = color

            let particleSystemNode = SCNNode()
            particleSystemNode.addParticleSystem(particleSystem)
            particleSystemNode.position = SCNVector3(CGFloat(contact.contactPoint.x + 1), CGFloat(contact.contactPoint.y) - sprite.size.height / 2, 0.0)

            acameraNode.addChildNode(particleSystemNode)
        }

        if contact.nodeB.parent != nil {
            contact.nodeB.runAction(.removeFromParentNode())
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

extension SCNVector3 {
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
}

