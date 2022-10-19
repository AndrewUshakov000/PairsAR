//
//  ViewController.swift
//  PairsAR
//
//  Created by Andrew Ushakov on 7/27/22.
//

import UIKit
import RealityKit
import Combine

class ViewController: UIViewController {

    @IBOutlet var arView: ARView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create an anchor to tether our cards
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        arView.scene.addAnchor(anchor)

        // Create our cards
        var cards: [Entity] = []

        // Create cards
        for _ in 1...16 {
            // Size of a card
            let box = MeshResource.generateBox(width: 0.04, height: 0.002, depth: 0.04)

            // Material of a cards
            let metalMaterial = SimpleMaterial(color: .gray, isMetallic: true)

            // Model of a card
            let model = ModelEntity(mesh: box, materials: [metalMaterial])

            // Make it clickable
            model.generateCollisionShapes(recursive: true)

            cards.append(model)
        }

        // Spread our cards equally
        for (index, card) in cards.enumerated() {
            let xCoordinate = Float(index % 4) - 1.5
            let zCoordinate = Float(index / 4) - 1.5

            card.position = [xCoordinate * 0.1, 0, zCoordinate * 0.1]
            anchor.addChild(card)
        }

        // Create an occlusion to hide our models when they are turned upside-down
        let boxSize: Float = 0.7
        let occlusionBoxMesh = MeshResource.generateBox(size: boxSize)
        let occlusionBox = ModelEntity(mesh: occlusionBoxMesh, materials: [OcclusionMaterial()])

        occlusionBox.position.y = -boxSize / 2
        anchor.addChild(occlusionBox)

        // We need that to download every object asynchronyously
        lazy var cancellable: AnyCancellable? = nil

        cancellable = ModelEntity.loadModelAsync(named: "01")

            // Add a 3D model
            .append(ModelEntity.loadModelAsync(named: "02"))
            .append(ModelEntity.loadModelAsync(named: "03"))
            .append(ModelEntity.loadModelAsync(named: "04"))
            .append(ModelEntity.loadModelAsync(named: "05"))
            .append(ModelEntity.loadModelAsync(named: "06"))
            .append(ModelEntity.loadModelAsync(named: "07"))
            .append(ModelEntity.loadModelAsync(named: "08"))

            // Collect all our models
            .collect()

            // Closure that runs when our asset is loaded
            .sink(receiveCompletion: { error in
                print("Error: \(error)")

                // Stop effects or anything that is currently running related to that
                cancellable?.cancel()
            }, receiveValue: { entities in
                var objects: [ModelEntity] = []

                for entity in entities {
                    // Set sized for an entity
                    entity.setScale(SIMD3<Float>(0.002, 0.002, 0.002), relativeTo: anchor)

                    // Make it clickable
                    entity.generateCollisionShapes(recursive: true)

                    // Clone it
                    for _ in 1...2 {
                        objects.append(entity.clone(recursive: true))
                    }
                }

                // Shuffle cards
                objects.shuffle()

                // Place every object on top of cards
                for (index, object) in objects.enumerated() {
                    cards[index].addChild(object)
                    cards[index].transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                }

                cancellable?.cancel()
            })
    }

    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        // Find a card
        let tapLocation = sender.location(in: arView)
        if let card = arView.entity(at: tapLocation) {
            if card.transform.rotation.angle == .pi {
                var flipDownTransform = card.transform

                // Moving action
                flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])

                // Force the card to move
                card.move(to: flipDownTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            } else {
                var flipUpTransform = card.transform

                // Moving action
                flipUpTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])

                // Force the card to move
                card.move(to: flipUpTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            }
        }
    }
}
