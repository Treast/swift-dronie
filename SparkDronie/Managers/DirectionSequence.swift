//
//  Sequence.swift
//  fr.vincentriva.RivaVincentMentalist
//
//  Created by Digital on 10/01/2019.
//  Copyright © 2019 Digital. All rights reserved.
//

import Foundation

class DirectionSequence {
    enum ActionType: String {
        case TakeOff, Landing, MoveForward, Stop
    }
    
    static let shared = DirectionSequence()
    
    var content = [String]() {
        didSet{
            print(content.last!)
        }
    }
    
    private init() {}
}
