//
//  PlaybackViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 10/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import AVFoundation

class PlaybackViewController: UIViewController {
    var mediaURL: URL!
    var postNumber: Int!
    var filename: String!
    
    @IBOutlet weak var movieView: UIView!
    
    var mediaPlayer = VLCMediaListPlayer()
    var media: VLCMedia!
    let fileManager = FileManager.default
    var fileURL: URL?
    
    fileprivate func setVideoDataToFolder(videoData: Data) throws{
        let documentDirectory = try? self.fileManager.url(
            for: .documentDirectory, in: .userDomainMask,
            appropriateFor: nil, create: false)
        self.fileURL = documentDirectory!.appendingPathComponent("\(self.postNumber)")
        try videoData.write(to: self.fileURL!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        
        if let videoData = UserDefaults.standard.data(forKey: "\(postNumber)") {
            print("cache memory")
            do {
                try setVideoDataToFolder(videoData: videoData)
                self.setupMediaPLayer()
                self.setupMedia()
            } catch {
                callAlertView(title: "Failed to load video",
                              message: "Failed to load video from cache. Try again later.")
            }
        } else {
            print("remote")
            Service().loadData(from: mediaURL, lastModified: nil) { [weak self] (result) in
                switch result {
                case .success(let response):
                    UserDefaults.standard.set(response.data, forKey: "\(self?.postNumber)")
                    do {
                        try self?.setVideoDataToFolder(videoData: response.data)
                        self?.setupMediaPLayer()
                        self?.setupMedia()
                    } catch {
                        self?.callAlertView(title: "Failed to load video",
                        message: "Failed to load video from server. Try again later.")
                    }
                case .failure(let error):
                    self?.callAlertView(title: "Failed to load video",
                                        message: "Failed to load video from server \(error.localizedDescription ?? ""). Try again later.")
                }
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mediaPlayer.play()
    }
    
    func setupMediaPLayer() {
        mediaPlayer.mediaPlayer.delegate = self
        mediaPlayer.mediaPlayer.drawable = movieView
        mediaPlayer.mediaPlayer.audio.volume = 0
    }
    
    @IBAction func handlePlayPause(_ sender: UIButton) {
        if mediaPlayer.mediaPlayer.isPlaying {
            mediaPlayer.pause()
            sender.isSelected = true
        } else {
            mediaPlayer.play()
            sender.isSelected = false
        }
    }
    
    @IBAction func handleToggleAudio(_ sender: UIButton) {
        if sender.isSelected {
            mediaPlayer.mediaPlayer.audio.volume = 0
            sender.isSelected = false
        } else {
            mediaPlayer.mediaPlayer.audio.volume = 100
            sender.isSelected = true
        }
    }
    
    @IBAction func closeView(_ sender: Any) {
        mediaPlayer.stop()
        navigationController?.popViewController(animated: true)
        navigationController?.navigationBar.isHidden = false
    }
    
    private func setupMedia() {
        media = VLCMedia(url: fileURL!)
        let mediaList = VLCMediaList()
        mediaList.add(media)
        mediaPlayer.mediaList = mediaList
        mediaPlayer.repeatMode = .repeatCurrentItem
        mediaPlayer.play(media)
    }
    
    @IBAction func saveVideo() {
        //movFileTransformToMp4WithSourceUrl(sourceUrl: fileURL!)
        savePDF()
    }
}

extension PlaybackViewController: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        print(mediaPlayer.mediaPlayer.time.debugDescription)
        print(mediaPlayer.mediaPlayer.remainingTime.debugDescription)
    }
}

extension PlaybackViewController {
       //Video conversion format .mov is converted to .mp4
       // Method sourceUrl parameter is .mov URL data
    func movFileTransformToMp4WithSourceUrl(sourceUrl: URL) {
                    // Name the file with the current time
           let date = Date()
           let formatter = DateFormatter.init()
           formatter.dateFormat = "yyyyMMddHHmmss"
           let fileName = formatter.string(from: date) + ".mov"
           
                    // Save the address sandbox path
           let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
           let videoSandBoxPath = (docPath as String) + "/albumVideo/" + fileName
           
           print(videoSandBoxPath)
           
                    // Transcoding configuration
        let avAsset = AVURLAsset.init(url: URL(string: "https://file-examples.com/wp-content/uploads/2018/04/file_example_MOV_480_700kB.mp4")!, options: nil)
    
                    // Take the video time and process for uploading
           let time = avAsset.duration
           let number = Float(CMTimeGetSeconds(time)) - Float(Int(CMTimeGetSeconds(time)))
           let totalSecond = number > 0.5 ? Int(CMTimeGetSeconds(time)) + 1 : Int(CMTimeGetSeconds(time))
           let photoId = String(totalSecond)
           
           
        let exportSession = AVAssetExportSession.init(asset: avAsset, presetName: AVAssetExportPresetHighestQuality)
           exportSession?.shouldOptimizeForNetworkUse = true
           exportSession?.outputURL = URL.init(fileURLWithPath: videoSandBoxPath)
        exportSession?.outputFileType = .mp4 //Control the format of the transcoding
           exportSession?.exportAsynchronously(completionHandler: {
            if exportSession?.status == AVAssetExportSession.Status.failed {
                                    print("transcode failed")
               }
            if exportSession?.status == AVAssetExportSession.Status.completed {
                                    print("transcode success")
                                    // After the transcoding is successful, you can use the dataurl to get the video data for uploading.
                   let dataurl = URL.init(fileURLWithPath: videoSandBoxPath)
                                       // Upload a video, you need to upload a video cover image at the same time, here is a way to get a screenshot of the video cover, the method is implemented below
                   let image = 1
               }
           })
       }
    
}

extension PlaybackViewController {
    func savePDF() {
        guard let videoData = UserDefaults.standard.data(forKey: "\(postNumber)") else { return }
        let activityController = UIActivityViewController(activityItems:
            [filename, videoData], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
}
