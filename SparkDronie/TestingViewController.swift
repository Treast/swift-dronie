//
//  Testing.swift
//  SparkDronie
//
//  Created by Vincent Riva on 10/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation
import UIKit

class TestingViewController: UIViewController {
    
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var speedYSlider: UISlider!
    @IBOutlet weak var durationSlider: UISlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var speedYLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var filterSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func filterSliderChanged(_ sender: Any) {
        Configuration.shared.filterValue = filterSlider.value
    }
    
    @IBAction func standBy(_ sender: Any) {
        MovementManager.shared.standBy()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ParcoursManager.shared.open(file: "parcours1")
    }
    
    @IBAction func speedChange(_ sender: Any) {
        speedLabel.text = "Speed X (\(String(format: "%.2f", speedSlider.value)))"
        MovementManager.shared.speedFactor = speedSlider.value
    }
    
    @IBAction func durationChange(_ sender: Any) {
        durationLabel.text = "Duration (\(String(format: "%.2f", durationSlider.value)))"
    }
    
    @IBAction func speedYChange(_ sender: Any) {
        speedYLabel.text = "Speed Y (\(String(format: "%.2f", speedYSlider.value)))"
        MovementManager.shared.speedFactorY = speedYSlider.value
    }
    
    @IBAction func changeParcours(_ sender: Any) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            ParcoursManager.shared.open(file: "parcours1")
        case 1:
            ParcoursManager.shared.open(file: "parcours2")
        case 2:
            ParcoursManager.shared.open(file: "parcours3")
        case 3:
            ParcoursManager.shared.open(file: "parcours4")
        case 4:
            ParcoursManager.shared.open(file: "parcours5")
        case 5:
            ParcoursManager.shared.open(file: "parcours6")
        case 6:
            MovementManager.shared.setSpeed(speedX: 0.25, speedY: 0.55)
            ParcoursManager.shared.currentPoint = ParcoursPoint(x: 0.0, y: 0.0)
            MovementManager.shared.moveTo(x: 5.0, y: 5.0, duration: 3) {
            }
        case 7:
            ParcoursManager.shared.open(file: "parcours8")
        case 8:
            ParcoursManager.shared.open(file: "parcours9")
        case 9:
            ParcoursManager.shared.open(file: "parcours10")
        default:
            break
        }
    }
    
    @IBAction func takeOff(_ sender: Any) {
        MovementManager.shared.takeOff()
    }
    
    @IBAction func land(_ sender: Any) {
        MovementManager.shared.land()
    }
    
    @IBAction func stop(_ sender: Any) {
        ParcoursManager.shared.stop()
    }
    
    @IBAction func run(_ sender: Any) {
        MovementManager.shared.speedFactor = speedSlider.value
        MovementManager.shared.speedFactorY = speedYSlider.value
        ParcoursManager.shared.playParcours(duration: durationSlider.value) {
            MovementManager.shared.stop()
        }
    }
}
