//
//  Group.swift
//  Alarmadillo
//
//  Created by Daniel Wallace on 12/02/17.
//  Copyright © 2017 Daniel Wallace. All rights reserved.
//

import UIKit

class Group: NSObject {
    var id: String
    var name: String
    var playSound: Bool
    var enabled: Bool
    var alarms: [Alarm]
    
    init(name: String, playSound: Bool, enabled: Bool, alarms: [Alarm]) {
        self.id = UUID().uuidString
        self.name = name
        self.playSound = playSound
        self.enabled = enabled
        self.alarms = alarms
    }
}
