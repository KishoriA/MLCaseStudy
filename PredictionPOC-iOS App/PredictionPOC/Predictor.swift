//
//  Predictor.swift
//  PredictionPOC
//
//  Created by Agrawal, Kishori (US - Mumbai) on 10/10/18.
//  Copyright © 2018 Agrawal, Kishori (US - Mumbai). All rights reserved.
//

import Foundation
import CoreML

class Predictor {
    
    var model: StructuredModel?
    
    static let standard: Predictor = {
        let instance = Predictor()
        
        return instance
    }()
    
    init() {
        self.model = StructuredModel()
    }
    
    func updateModelWith(url: URL) -> Bool {
        do {
            self.model = try StructuredModel(contentsOf: url)
            return true
        }
        catch {
            print("Model creation failed \(error)")
            return false
        }
    }
}
