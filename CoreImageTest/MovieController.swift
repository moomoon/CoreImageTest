//
//  MovieController.swift
//  CoreImageTest
//
//  Created by Jia Jing on 6/25/15.
//  Copyright © 2015 Jia Jing. All rights reserved.
//

import UIKit
import GLKit
import OpenGLES
import AVFoundation

class MovieController: GLKViewController {
    @IBOutlet var movieView: MovieView!

    private var eaglContext : EAGLContext?
    private var ciContext : CIContext?
    private var avAsset : AVAsset?
    private var avAssetReader : AVAssetReader?
    private var avAssetReaderOutput : AVAssetReaderOutput!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        guard let eaglContext = eaglContext else { NSLog("cannot initialize EAGLContext for api2"); return }
        movieView.context = eaglContext
        ciContext = CIContext(EAGLContext: eaglContext)
        guard let ciContext = ciContext else { NSLog("cannot initialize CIContext from EAGLContext"); return }
        movieView.ciContext = ciContext
        startPlay()
    }
    
    
    
    func startPlay(){
        let moviePath : String = NSBundle.mainBundle().pathForResource("movie", ofType: "mp4")!
        let movieUrl : NSURL = NSURL(fileURLWithPath: moviePath)
        self.avAsset = AVURLAsset(URL: movieUrl, options : nil);
        guard let avAsset = avAsset else { NSLog("cannot retrieve av file"); return }
        do{
            try self.avAssetReader = AVAssetReader(asset: avAsset)
        } catch {
            
        }
        guard let avAssetReader = avAssetReader else { NSLog("cannot initialize AVAssetReader from AVAsset"); return }
        for track in avAsset.tracks {
            guard track.mediaType == AVMediaTypeVideo else { continue }
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)])
            guard avAssetReader.canAddOutput(output) else { break }
            avAssetReader.addOutput(output)
            self.avAssetReaderOutput = output
            break
        }
        avAssetReader.startReading()
        dispatch_async(dispatch_queue_create("decodeQueue", DISPATCH_QUEUE_SERIAL)) {
            while let cmSampleBuffer = self.avAssetReaderOutput.copyNextSampleBuffer() {
                guard let cvImageBufferRef = CMSampleBufferGetImageBuffer(cmSampleBuffer) else { continue }
                let ciImage = CIImage(CVImageBuffer: cvImageBufferRef)
                //dispatch_async(dispatch_get_main_queue()) {
                    self.movieView.drawCiImage(ciImage)
                //}
            }
        }
    }
}
