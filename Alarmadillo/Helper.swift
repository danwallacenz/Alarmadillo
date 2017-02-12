//
//  Helper.swift
//  Alarmadillo
//
//  Created by Daniel Wallace on 12/02/17.
//  Copyright © 2017 Daniel Wallace. All rights reserved.
//

import Foundation

struct Helper {
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
}
