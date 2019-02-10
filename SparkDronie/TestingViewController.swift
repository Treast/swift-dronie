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
    @IBOutlet weak var durationSlider: UISlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ParcoursManager.shared.open(file: "parcours1")
    }
    
    @IBAction func speedChange(_ sender: Any) {
        speedLabel.text = "Slider Factor (\(String(format: "%.2f", speedSlider.value)))"
    }
    
    @IBAction func durationChange(_ sender: Any) {
        durationLabel.text = "Slider Factor (\(String(format: "%.2f", durationSlider.value)))"
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
        ParcoursManager.shared.playParcours(duration: durationSlider.value)
    }
}
