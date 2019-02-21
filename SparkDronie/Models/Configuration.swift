//
//  Configuration.swift
//  SparkDronie
//
//  Created by Vincent Riva on 20/02/2019.
//  Copyright © 2019 Vincent Riva. All rights reserved.
//

import Foundation

class Configuration {
    var filterValue: Float = 0.0
    static let shared = Configuration()
    
    private init() {}
}
