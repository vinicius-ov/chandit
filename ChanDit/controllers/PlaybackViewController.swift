//
//  PlaybackViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 10/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import AVKit

class PlaybackViewController: UIViewController {
    //let mediaURL:String? = nil
    var mediaURL:URL? = nil
    var filename = "filename_my_file"
    
    @IBOutlet weak var movieView: UIView!
    
    var mediaPlayer = VLCMediaPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        setupMediaPLayer()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mediaPlayer.play()
    }
    
    func setupMediaPLayer() {
        setupMedia()
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
        mediaPlayer.audio.volume = 0
    }
    
    @IBAction func handlePlayPause(_ sender: UIButton) {
        if mediaPlayer.isPlaying {
            mediaPlayer.pause()
            sender.isSelected = true
        } else {
            mediaPlayer.play()
            sender.isSelected = false
        }
    }
    
    @IBAction func handleToggleAudio(_ sender: UIButton) {
        if sender.isSelected {
            mediaPlayer.audio.volume = 0
            sender.isSelected = false
        } else {
            mediaPlayer.audio.volume = 100
            sender.isSelected = true
        }
    }
    
    @IBAction func closeView(_ sender: Any) {
        mediaPlayer.stop()
        navigationController?.popViewController(animated: true)
        navigationController?.isNavigationBarHidden = false
    }
    
    fileprivate func setupMedia() {
        guard let url = mediaURL else { return }
        mediaPlayer.media = VLCMedia(url: url)
    }
    
    @IBAction func saveVideo(_ sender: Any) {
        guard let url = mediaURL else { return }
        encodeVideo(at:
//            url
        URL(string: "https://file-examples.com/wp-content/uploads/2018/04/file_example_MOV_480_700kB.mov")!
        ) { (exportUrl, error) in
            print(exportUrl)
            print(error)
        }
    }
}

extension PlaybackViewController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        if mediaPlayer.state == .stopped {
            setupMedia()
            mediaPlayer.play()
        }
    }
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        print(mediaPlayer.time.debugDescription)
        print(mediaPlayer.remainingTime.debugDescription)
    }
}

extension PlaybackViewController {
    func encodeVideo(at videoURL: URL, completionHandler: ((URL?, Error?) -> Void)?)  {
        let avAsset = AVURLAsset(url: videoURL, options: nil)
            
        let startDate = Date()
            
        print(AVAssetExportSession.exportPresets(compatibleWith: avAsset))
        //Create Export session
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetLowQuality) else {
            completionHandler?(nil, nil)
            return
        }
            
        //Creating temp path to save the converted video
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsDirectory.appendingPathComponent("rendered-Video.mp4")
            
        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: filePath.path) {
            do {
                try FileManager.default.removeItem(at: filePath)
            } catch {
                completionHandler?(nil, error)
            }
        }
            
        exportSession.outputURL = filePath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = false
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession.timeRange = range
            
        exportSession.exportAsynchronously(completionHandler: {() -> Void in
            switch exportSession.status {
            case .failed:
                print(exportSession.error ?? "NO ERROR")
                completionHandler?(nil, exportSession.error)
            case .cancelled:
                print("Export canceled")
                completionHandler?(nil, nil)
            case .completed:
                //Video conversion finished
                let endDate = Date()
                    
                let time = endDate.timeIntervalSince(startDate)
                print(time)
                print("Successful!")
                print(exportSession.outputURL ?? "NO OUTPUT URL")
                completionHandler?(exportSession.outputURL, nil)
                    
                default: break
            }
                
        })
    }
}
