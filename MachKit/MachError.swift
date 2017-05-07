//
//  MachError.swift
//  MachKit
//
//  Created by Pedro José Pereira Vieito on 7/5/17.
//  Copyright © 2017 Pedro José Pereira Vieito. All rights reserved.
//

import Foundation

extension MachError {

    init(_ code: Int32) {

        guard let errorCode = MachErrorCode(rawValue: code) else {
            self.init(MachErrorCode.notSupported)
            return
        }

        self.init(errorCode)
    }
}
