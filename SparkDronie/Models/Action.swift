//
//  Action.swift
//  fr.vincentriva.RivaVincentMentalist
//
//  Created by Digital on 21/01/2019.
//  Copyright © 2019 Digital. All rights reserved.
//

import Foundation
import UIKit

struct Action {
    var action: ActionType
    var duration: CGFloat
    var callback: (() -> ())?
    
    init(action: ActionType, duration: CGFloat, callback: (() -> ())? = nil) {
        self.action = action
        self.duration = duration
        self.callback = callback
    }
    
    // Possibilité de rajouter une 3ème direction et des rotations
    enum ActionType: String, CaseIterable {
        case TakeOff, Land, CameraUp, CameraDown, TurnBack, Custom, None
    }
    
    func description() -> String {
        return "\(self.action.rawValue) during \(duration)"
    }
}
