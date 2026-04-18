import QuartzCore
import SceneKit
import SwiftUI
import UIKit

/// Lightweight 3D “stage”: textured card avatar that can roam and play named actions from `PetActionCatalog`.
struct PetScene3DView: UIViewRepresentable {
    var image: UIImage?
    var modelURL: URL?
    var speciesEmoji: String
    var actionName: String
    var actionTick: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.makeScene()
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = .clear
        view.allowsCameraControl = false
        context.coordinator.bind(view: view, image: image, modelURL: modelURL, emoji: speciesEmoji)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.updateVisual(image: image, modelURL: modelURL, emoji: speciesEmoji)
        if context.coordinator.lastActionTick != actionTick {
            context.coordinator.lastActionTick = actionTick
            context.coordinator.play(actionName: actionName)
        }
    }

    final class Coordinator: NSObject {
        private weak var view: SCNView?
        private var petRoot: SCNNode!
        private var importedModelNode: SCNNode?
        private var avatarPlaneNode: SCNNode?
        private var material: SCNMaterial!
        private var loadedModelURL: URL?
        private let basePosition = SCNVector3(0, 0.85, 0)
        private var link: CADisplayLink?
        private var startRef = CACurrentMediaTime()

        var lastActionTick: Int = -1

        func makeScene() -> SCNScene {
            let scene = SCNScene()

            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.zFar = 100
            cameraNode.position = SCNVector3(0, 1.1, 4.2)
            cameraNode.look(at: SCNVector3(0, 0.75, 0))
            scene.rootNode.addChildNode(cameraNode)

            let light = SCNNode()
            light.light = SCNLight()
            light.light?.type = .omni
            light.light?.intensity = 650
            light.position = SCNVector3(3, 6, 5)
            scene.rootNode.addChildNode(light)

            let floor = SCNNode(geometry: SCNPlane(width: 8, height: 8))
            floor.geometry?.firstMaterial?.diffuse.contents = UIColor.secondarySystemBackground
            floor.geometry?.firstMaterial?.lightingModel = .constant
            floor.eulerAngles.x = -.pi / 2
            floor.position = SCNVector3(0, 0, 0)
            scene.rootNode.addChildNode(floor)

            petRoot = SCNNode()
            petRoot.position = basePosition
            scene.rootNode.addChildNode(petRoot)

            let plane = SCNPlane(width: 1.35, height: 1.35)
            material = SCNMaterial()
            material.isDoubleSided = true
            material.lightingModel = .blinn
            plane.materials = [material]

            let avatarPlane = SCNNode(geometry: plane)
            let bill = SCNBillboardConstraint()
            bill.freeAxes = .Y
            avatarPlane.constraints = [bill]
            petRoot.addChildNode(avatarPlane)
            avatarPlaneNode = avatarPlane

            return scene
        }

        func bind(view: SCNView, image: UIImage?, modelURL: URL?, emoji: String) {
            self.view = view
            updateVisual(image: image, modelURL: modelURL, emoji: emoji)
            startIdleMotion()
        }

        deinit {
            link?.invalidate()
        }

        func updateVisual(image: UIImage?, modelURL: URL?, emoji: String) {
            if let modelURL {
                if let modelNode = loadUSDZIfNeeded(modelURL) {
                    avatarPlaneNode?.isHidden = true
                    modelNode.isHidden = false
                    return
                }
                avatarPlaneNode?.isHidden = false
                importedModelNode?.isHidden = true
            } else {
                importedModelNode?.removeFromParentNode()
                importedModelNode = nil
                loadedModelURL = nil
                avatarPlaneNode?.isHidden = false
            }
            let resolved = image ?? Self.emojiImage(emoji)
            material.diffuse.contents = resolved
        }

        func play(actionName: String) {
            petRoot.removeAllActions()
            let h = abs(actionName.hashValue)
            let dur = 0.28 + Double(h % 7) * 0.05
            let up = SCNAction.moveBy(x: 0, y: 0.22, z: 0, duration: dur)
            up.timingMode = .easeOut
            let down = SCNAction.moveBy(x: 0, y: -0.22, z: 0, duration: dur)
            down.timingMode = .easeIn
            let wobbleX = SCNAction.moveBy(x: CGFloat((h % 5) - 2) * 0.08, y: 0, z: 0, duration: dur * 1.2)
            let wobbleZ = SCNAction.moveBy(x: 0, y: 0, z: CGFloat((h % 3) - 1) * 0.12, duration: dur * 1.4)
            let spin = SCNAction.rotateBy(x: 0, y: (h % 2 == 0 ? 1 : -1) * CGFloat.pi * 2, z: 0, duration: dur * 2.1)
            let sequence = SCNAction.sequence([up, wobbleX, spin, wobbleZ, down])
            petRoot.runAction(sequence)
        }

        private func startIdleMotion() {
            link?.invalidate()
            guard view != nil else { return }
            startRef = CACurrentMediaTime()
            let dl = CADisplayLink(target: self, selector: #selector(tickIdle))
            dl.add(to: .main, forMode: .common)
            link = dl
        }

        @objc private func tickIdle() {
            let t = CACurrentMediaTime() - startRef
            let dx = Float(sin(t * 1.1)) * 0.35
            let dz = Float(cos(t * 0.95)) * 0.22
            petRoot.position = SCNVector3(basePosition.x + dx, basePosition.y + Float(sin(t * 2.4)) * 0.04, basePosition.z + dz)
            petRoot.eulerAngles.y = Float(sin(t * 0.8)) * 0.35
        }

        private static func emojiImage(_ s: String) -> UIImage {
            let size: CGFloat = 256
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
            label.text = s
            label.font = .systemFont(ofSize: size * 0.5)
            label.textAlignment = .center
            let renderer = UIGraphicsImageRenderer(size: label.bounds.size)
            return renderer.image { ctx in
                label.layer.render(in: ctx.cgContext)
            }
        }

        private func loadUSDZIfNeeded(_ url: URL) -> SCNNode? {
            if let importedModelNode, loadedModelURL == url {
                return importedModelNode
            }
            importedModelNode?.removeFromParentNode()
            importedModelNode = nil
            loadedModelURL = nil

            guard let scene = try? SCNScene(url: url, options: nil) else { return nil }
            let container = SCNNode()
            for c in scene.rootNode.childNodes {
                container.addChildNode(c)
            }
            container.scale = SCNVector3(0.012, 0.012, 0.012)
            container.position = SCNVector3(0, -0.55, 0)
            petRoot.addChildNode(container)
            importedModelNode = container
            loadedModelURL = url
            return container
        }
    }
}
