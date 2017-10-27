//
//  FilmStrip.swift
//  EnigmaEdit
//
//  Created by Alan Franklin on 27/8/17.
//  Copyright © 2017 Alan Franklin. All rights reserved.
//
//  View is a composition of thumbnails in a filmstrip styl


import Cocoa
import AVFoundation
import AVKit

@IBDesignable
class FilmStrip: NSStackView
{
  
  var filmstripFrameGap: Double = 0.2         // seconds
  @IBInspectable dynamic var frames: Int = 7
    {
    didSet {
      changeThumbnailCountTo(frames)
    }
  }
  var frameWidth: CGFloat = 160.0/2.0
  var frameHeight: CGFloat = 90.0/2.0
  var frameSpacing: CGFloat = 8.0
  var imageBounds = NSRect()
  
  // TODO: setup in prefs (duplicated)
  let textFontName = "Helvetica-Bold"
  
  private var debug = false
  
  /// use this queue to synchronize access to requestedTimes array
  private var filmStripProcessingQueue = DispatchQueue(label: "filmStripProcessingQueue")
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    // Drawing code here.
  }
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    filmstripSetup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    filmstripSetup()
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  /// Common setup code
  private func filmstripSetup()
  {
    //    Swift.print("saw "+#function)
    imageBounds = NSRect(origin: CGPoint(x:0.0, y:0.0), size: CGSize(width:frameWidth,height:frameHeight))
    //    self.backgroundColor = NSColor.green
    self.orientation = .horizontal
    self.alignment = .centerY
    self.spacing = CGFloat(frameSpacing)
    self.distribution = .equalCentering
    changeThumbnailCountTo(frames)
  }
  
  private func changeThumbnailCountTo(_ frameCount: Int)
  {
    var thumbnails = [NSImageView]()
    for _ in 1...frameCount
    {
      let filmCell = NSImageView(image: getDefaultFilmStripImageForView(imageBounds))
      //      filmCell.backgroundColor = NSColor.yellow
      thumbnails.append(filmCell)
    }
    //    self.addView(thumbnails[0], in: NSStackViewGravity.center)
    self.setViews(thumbnails, in: .center)
    
  }
  
  /// replaces the transparent overlay label that shows the time delta of the thumbnail
  /// called when user changes filmstrip gap in preferences
  
  func updateTimeTextLabels()
  {
    let secondsApart = filmstripFrameGap  // from user prefs
    let frames = self.arrangedSubviews.count
    let nominalCentreFrametime = Double(frames/2) * secondsApart
    let startDelta = Double(frames / 2) * secondsApart
    var frameDelta = startDelta * -1.0
    var startTimeInSeconds = nominalCentreFrametime - startDelta
    
    for view in self.arrangedSubviews
    {
      let deltaString = filmStripTextFromDeltaSecs(frameDelta)
      if view.wantsLayer {
        if let imageLayer = view.layer!.sublayers?[0] {
          let textLayer = timeDeltaCATextLayer(deltaValue: deltaString, in: imageLayer.frame)
          let oldTextLayer = imageLayer.sublayers?[0]
          oldTextLayer?.removeFromSuperlayer()
          imageLayer.addSublayer(textLayer)
        }
      }
      view.invalidateIntrinsicContentSize()
      frameDelta += secondsApart
      startTimeInSeconds += secondsApart
    }
  }
  
  
  // slow and synchronous for developement testing only
  func updateFilmStripSynchronous(time: CMTime, secondsApart: Double, imageGenerator: AVAssetImageGenerator)
  {
    let frames = self.arrangedSubviews.count
    let startDelta = Double(frames / 2) * secondsApart
    var startTimeInSeconds = time.seconds - startDelta
    for view in self.arrangedSubviews
    {
      //      var textLabel : NSTextField?
      let imageView = view as! NSImageView
      let viewWidth = view.bounds.width == 0 ? view.bounds.height * (16.0/9.0): view.bounds.width
      let viewSize = CGSize(width: viewWidth, height: view.bounds.height)
      if let frameImage = singleImageAtTime(seconds: startTimeInSeconds, generator: imageGenerator, imageSize: viewSize)
      {
        imageView.image = frameImage
        imageView.frame = NSRect(x: 0, y: 0, width: frameImage.size.width, height: frameImage.size.height)
      }
      startTimeInSeconds += secondsApart
    }
  }
  
  private var requestedTimes = [NSValue]()
  
  /// Generate and display thumbnails either size of the current position
  /// Only do this if the player is paused
  func updateFor(time: CMTime, secondsApart: Double, imageGenerator: AVAssetImageGenerator)
  {
    let  handler = assetImageCompletionHandler
    imageGenerator.cancelAllCGImageGeneration()
    // Create array of 7 times for filmstrip (never negative)
    let startSeconds = (time.seconds - 3.0*secondsApart) > 0.0 ? (time.seconds - 3.0*secondsApart) : 0.0
    
    filmStripProcessingQueue.sync {
      self.requestedTimes.removeAll()
      for position in 0 ..< frames
      {
        requestedTimes.append(CMTime(seconds: startSeconds + Double(position)*secondsApart, preferredTimescale: CutsTimeConst.PTS_TIMESCALE) as NSValue)
        self.arrangedSubviews[position].layer?.sublayers?[0].contents = self.getDefaultFilmStripImageForView(self.arrangedSubviews[position].frame)
      }
    }

    imageGenerator.generateCGImagesAsynchronously(forTimes: requestedTimes, completionHandler: handler)
  }
  
  func filmStripTextFromDeltaSecs(_ frameDelta: Double) -> String
  {
    var deltaString = String.init(format: "%.2f", frameDelta)
    // suppress "-0.0" output from formatting
    if abs(frameDelta) <= 0.0001 {
      deltaString = " 0.00"
    }
    if frameDelta >= 0.0001 {
      deltaString = "+"+deltaString
    }
    return deltaString
  }
  
  func timeDeltaCATextLayer(deltaValue : String, in frame:NSRect) -> CATextLayer
  {
    // 10 % inset from image
    let fontHeight = CGFloat(20.0)
    let insetWidth = 0.15 * frame.width
    let insetHeight = 0.25 * frame.height
    let textframe = frame.insetBy(dx: insetWidth, dy: insetHeight)
    let deltaTextLayer = CATextLayer()
    deltaTextLayer.frame = textframe
    deltaTextLayer.cornerRadius = 0.15 * deltaTextLayer.bounds.width
    deltaTextLayer.string = deltaValue
    let textBackgroundColour = NSColor.white.withAlphaComponent(0.3)
    deltaTextLayer.backgroundColor = textBackgroundColour.cgColor
    let textFont = NSFont(name: textFontName, size: fontHeight)
    deltaTextLayer.font = textFont
    deltaTextLayer.fontSize = fontHeight
    deltaTextLayer.contentsScale = (NSScreen.main?.backingScaleFactor)!
    let transWhite = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)
    deltaTextLayer.alignmentMode = kCAAlignmentCenter
    deltaTextLayer.foregroundColor = transWhite.cgColor
    //    deltaTextLayer.alignment = NSTextAlignment.justified
    return deltaTextLayer
  }
  
  // add a transparent overlay label to show the time delta of the frame
  // in relationship to the centre frame
  // only called at view setup time (ie once only)
  
  func addTimeTextLabels()
  {
    // TODO: Add to user configuration
    let secondsApart = filmstripFrameGap    // nominal initial value
    let frames = self.arrangedSubviews.count
    let nominalCentreFrametime = Double(frames/2) * secondsApart
    let startDelta = Double(frames / 2) * secondsApart
    var frameDelta = startDelta * -1.0
    var startTimeInSeconds = nominalCentreFrametime - startDelta
    // static starter image
    let resizedImage = getDefaultFilmStripImageForView(imageBounds)
    let imageFrame = NSRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height)
    
    for view in self.arrangedSubviews
    {
      // round the corners of the "frame"
      view.wantsLayer = true
      if let layer = view.layer {
        layer.backgroundColor = NSColor.blue.cgColor
        layer.cornerRadius = 0.1 * resizedImage.size.width
        layer.masksToBounds = true
        let imageLayer = CALayer()
        imageLayer.contents = resizedImage
        imageLayer.frame = imageFrame
        layer.addSublayer(imageLayer)
        
        let deltaString = filmStripTextFromDeltaSecs(frameDelta)
        let textLayer = timeDeltaCATextLayer(deltaValue: deltaString, in: imageLayer.frame)
        
        imageLayer.addSublayer(textLayer)
      }
      frameDelta += secondsApart
      startTimeInSeconds += secondsApart
    }
  }
  
  /* original function before trying layers instead of views
   
   func addTimeTextLabelsToFilmStrip()
   {
   // TODO: Add to user configuration
   let secondsApart = 0.1    // nominal initial value
   let nominalCentreFrametime = 0.3
   let frames = self.filmstrip.arrangedSubviews.count
   let startDelta = Double(frames / 2) * secondsApart
   var frameDelta = startDelta * -1.0
   var startTimeInSeconds = nominalCentreFrametime - startDelta
   // static starter image
   let resizedImage = getDefaultFilmStripImageForView(filmstrip.arrangedSubviews[0].bounds)
   let imageFrame = NSRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height)
   //    print("image frame is \(imageFrame)")
   
   var identifierIndex = 0
   for view in self.filmstrip.arrangedSubviews
   {
   // round the corners of the "frame"
   view.wantsLayer = true
   if let layer = view.layer {
   layer.backgroundColor = NSColor.blue.cgColor
   layer.cornerRadius = 0.1 * layer.bounds.width
   layer.masksToBounds = true
   }
   //      print("intrinsic view size is \(view.intrinsicContentSize)")
   //      print("initial view frame is \(view.frame)")
   let imageView = view as! NSImageView
   //      let viewWidth = view.bounds.width == 0 ? view.bounds.height * (16.0/9.0): view.bounds.width
   imageView.image = resizedImage
   imageView.frame = imageFrame
   var deltaString = String.init(format: "%.2f", frameDelta)
   // suppress "-0.0" output from formatting
   if abs(frameDelta) <= 0.0001 {
   deltaString = " 0.00"
   }
   if frameDelta >= 0.0001 {
   deltaString = "+"+deltaString
   }
   let label = timeDeltaTextLabel(deltaValue: deltaString, in: imageView.frame, withId: identifierIndex)
   //      print ("label position =\(label.frame), label size = \(label.bounds)")
   frameDelta += secondsApart
   imageView.addSubview(label)
   imageView.setFrameSize(imageFrame.size)
   //      print("post view frame is \(view.frame)")
   //      print("post processing view size \(view.fittingSize)")
   startTimeInSeconds += secondsApart
   identifierIndex += 1
   }
   }
   
   */
  /// Main queue callback from handler to update user interface with
  /// image generated for filmstrip display
  
  func updateFilmstripWithImage(_ image: CGImage, atStripIndex index: Int)
  {
    //    let pixelData = image.pixelData()
    //    for i in 0 ... 10 {
    //      let startByte = i*4
    //
    //      print("InitialBytes[\(index)] \(i): \(pixelData![startByte+0]):\(pixelData![startByte+1]):\(pixelData![startByte+2]):\(pixelData![startByte+3])")
    //    }
    let imageHeight = self.bounds.height
    let imageWidth = imageHeight*(16.0/9.0)
    let viewSize = CGSize(width: imageWidth, height: imageHeight)
    let sizedImage = NSImage(cgImage: image, size: viewSize)
    if let layer = self.arrangedSubviews[index].layer {
      layer.sublayers?[0].contents = sizedImage
    }
  }
  
  let defaultFilmstripImage = NSImage(imageLiteralResourceName: "scissors_icon-icons.com_50046-128.png")
  
  func getDefaultFilmStripImageForView(_ bounds:NSRect) -> NSImage
  {
    let frameImage = defaultFilmstripImage
    var imageRect = CGRect(x: 0, y: 0, width: defaultFilmstripImage.size.width, height: defaultFilmstripImage.size.height)
    let cgFrameImageRef = frameImage.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    let viewWidth = bounds.height * (16.0/9.0)
    let viewSize = CGSize(width: viewWidth, height: bounds.height)
    let resizedImage = NSImage(cgImage: cgFrameImageRef!, size: viewSize)
    return resizedImage
  }
  
  func scaleImageForFilmStripSize(filmStripSize: CGSize, image: CGImage) -> NSImage
  {
    let imageSize = CGSize(width:filmStripSize.height*(16.0/9.0), height:filmStripSize.height)
    //    var imageRect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
    //    let cgFrameImageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    //    let viewWidth = bounds.height * (16.0/9.0)
    //    let viewSize = CGSize(width: viewWidth, height: bounds.height)
    let resizedImage = NSImage(cgImage: image, size: imageSize)
    return resizedImage
    
  }
  
  /// Handler to deal with each image as it becomes available.
  /// Needs to determine which array element it belongs to.
  /// To do this, we need the base start time to calculate an array index
  /// from the "requested" time.
  /// Also need to access the "spacing" of the frames
  func assetImageCompletionHandler (time:CMTime, image: CGImage?, actualTime:CMTime, result:AVAssetImageGeneratorResult, error: Error?)
  {
    //    let resultAsString = result == AVAssetImageGeneratorResult.succeeded ? "Succeeded" : (result == AVAssetImageGeneratorResult.failed) ? "Failed": "Cancelled"
    //    print("result: \(resultAsString) requested at time \(time.seconds)")
    if (result == AVAssetImageGeneratorResult.failed && debug)
    {
      Swift.print("error: \(String(describing: error))")
      Swift.print("requestedTime \(time.seconds)")
      Swift.print("actualTime \(actualTime.seconds)")
    }
    
//    if let _image = image, let viewIndex = requestedTimes.index(of: time as NSValue)
//    {
//      DispatchQueue.main.async  {
//        self.updateFilmstripWithImage(_image, atStripIndex: viewIndex)
//      }
//    }
    if let _image = image {
      filmStripProcessingQueue.async {
        if let viewIndex = self.requestedTimes.index(of: time as NSValue) {
          DispatchQueue.main.async  {
            self.updateFilmstripWithImage(_image, atStripIndex: viewIndex)
          }
        }
      }
    }
  }
  
  func singleImageAtTime( seconds: Double, generator: AVAssetImageGenerator, imageSize:CGSize?) -> NSImage?
  {
    let fiveMinutes = CMTimeMakeWithSeconds(seconds, 600)
    var actualTime = CMTime()
    var scaledImage : NSImage?
    do {
      let image = try generator.copyCGImage(at:fiveMinutes, actualTime: &actualTime)
      let actualTimeString = String(describing: CMTimeCopyDescription(nil, actualTime))
      let requestedTimeString = String(describing: CMTimeCopyDescription(nil, fiveMinutes))
      Swift.print("Got image at times: Asked for  \(requestedTimeString), got \(actualTimeString)");
      
      // Do something interesting with the image.
      //      print("image size is \(image.width)/\(image.height)")
      scaledImage = (imageSize != nil) ? NSImage(cgImage: image, size: imageSize!):NSImage(cgImage: image, size:NSSize(width:image.width, height: image.height))
    }
    catch let error as NSError {
      Swift.print(error.localizedDescription)
    }
    return scaledImage
  }
  
  override func prepareForInterfaceBuilder() {
    // what goes here ?
    super.prepareForInterfaceBuilder()
    self.filmstripSetup()
  }
}
