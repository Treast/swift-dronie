//
//  File.swift
//  SparkDronie
//
//  Created by Vincent Riva on 18/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation
import UIKit

class EventViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension EventViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = DroneEvent.allCases[indexPath.item]
        SocketIOManager.shared.virtualEmit(event: event)
    }
}

extension EventViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DroneEvent.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        cell?.textLabel?.text = DroneEvent.allCases[indexPath.item].rawValue
        
        return cell!
    }
    
    
}
