//
//  MovieView.swift
//  CoreImageTest
//
//  Created by Jia Jing on 6/25/15.
//  Copyright © 2015 Jia Jing. All rights reserved.
//

import UIKit
import GLKit

class MovieView: GLKView {
    var ciContext : CIContext?
    var currentFrame : CIImage?
    

    
    func drawCiImage(image : CIImage){
        self.currentFrame = image
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        guard let ciContext = ciContext else { NSLog("no CIContext"); return }
        guard let currentFrame = currentFrame else { NSLog("no frame to draw"); return }
        ciContext.drawImage(currentFrame, inRect: rect, fromRect: currentFrame.extent)
    }
}
