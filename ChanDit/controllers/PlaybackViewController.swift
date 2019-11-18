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
    var shouldSave = false
    var task: URLSessionTask!
    var blockTimer = false
    
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var downloadProgress: UIProgressView!
    @IBOutlet weak var elapsedTime: UILabel!
    @IBOutlet weak var totalTime: UILabel!
    @IBOutlet weak var sliderTimer: UISlider!
    
    var mediaListPlayer = VLCMediaListPlayer()
    var media: VLCMedia!
    let fileManager = FileManager.default
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        
        sliderTimer.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        
        let number = "\(postNumber ?? 0)"
        if let videoData = UserDefaults.standard.data(forKey: number) {
            print("cache memory")
            do {
                try setVideoDataToFolder(videoData: videoData)
                
            } catch {
                showAlertView(title: "Failed to load video",
                              message: "Failed to load video from cache. Try again later.")
            }
            self.setupMediaPLayer()
            self.setupMedia()
        } else {
            print("remote")
            task = Service(delegate: self).loadVideoData(from: mediaURL)
            task.resume()
        }
    }
    
    @objc
    func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                // handle drag began
                print(1)
            case .moved:
                // handle drag moved
                print(2)
            case .ended:
                // handle drag ended
                let value = slider.value
                mediaListPlayer.mediaPlayer.time = VLCTime(number: NSNumber(value: value))
                blockTimer = false
            default:
                break
            }
        }
    }
    
    private func setVideoDataToFolder(videoData: Data) throws {
        let documentDirectory = try? self.fileManager.url(
            for: .documentDirectory, in: .userDomainMask,
            appropriateFor: nil, create: false)
        let path = documentDirectory?.appendingPathComponent("webm", isDirectory: true)
        try fileManager.createDirectory(at: path!, withIntermediateDirectories: true, attributes: nil)
        fileURL = path!
            .appendingPathComponent(self.filename, isDirectory: false)
        try videoData.write(to: fileURL!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mediaListPlayer.play()
    }
    
    func setupMediaPLayer() {
        mediaListPlayer.mediaPlayer.delegate = self
        mediaListPlayer.mediaPlayer.drawable = movieView
        mediaListPlayer.mediaPlayer.audio.volume = 0
    }
    
    @IBAction func handlePlayPause(_ sender: UIButton) {
        if mediaListPlayer.mediaPlayer.isPlaying {
            mediaListPlayer.pause()
            sender.isSelected = true
        } else {
            mediaListPlayer.play()
            sender.isSelected = false
        }
    }
    
    @IBAction func handleToggleAudio(_ sender: UIButton) {
        if sender.isSelected {
            mediaListPlayer.mediaPlayer.audio.volume = 0
            sender.isSelected = false
        } else {
            mediaListPlayer.mediaPlayer.audio.volume = 100
            sender.isSelected = true
        }
    }
    
    private func stopActivity() {
        mediaListPlayer.stop()
        if task != nil {
            task.cancel()
        }
        if let url = fileURL, !shouldSave {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                print("could not delete file")
            }
        }
        //navigationController?.popViewController(animated: true)
    }
    
    @IBAction func closeView(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopActivity()
    }

    private func setupMedia() {
        media = VLCMedia(url: fileURL!)
        let mediaList = VLCMediaList()
        mediaList.add(media)
        mediaListPlayer.mediaList = mediaList
        mediaListPlayer.repeatMode = .repeatCurrentItem
        mediaListPlayer.play(media)
    }
    
    @IBAction func saveVideo(_ sender: Any) {
        shouldSave = true
        (sender as? UIButton)?.setTitle("Saved", for: .normal)
        (sender as? UIButton)?.isEnabled = false
    }
    
    @IBAction func valueChanged(_ sender: UISlider) {
        blockTimer = true
        print(sender.value)
        elapsedTime.text = "\(VLCTime(number: NSNumber(value: sender.value)) ?? VLCTime())"
    }
}

extension PlaybackViewController: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        if !blockTimer {
            elapsedTime.text = mediaListPlayer.mediaPlayer.time!.debugDescription
            totalTime.text = mediaListPlayer.mediaPlayer.media.length.debugDescription
            sliderTimer.maximumValue = Float(mediaListPlayer.mediaPlayer.media.length.intValue)
            sliderTimer.value = Float(mediaListPlayer.mediaPlayer.time.intValue)
        }
    }
}

extension PlaybackViewController: URLSessionDelegate,
URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async { [weak self] in
            self?.downloadProgress.setProgress(
                Float(totalBytesWritten) / Float(totalBytesExpectedToWrite),
                animated: true)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            UserDefaults.standard.set(data, forKey: "\(postNumber ?? 0)")
            try setVideoDataToFolder(videoData: data)
            setupMediaPLayer()
            setupMedia()
        } catch {
            showAlertView(title: "Failed to load video",
                          message: "Failed to load video from server. Try again later.")
        }
    }
}
