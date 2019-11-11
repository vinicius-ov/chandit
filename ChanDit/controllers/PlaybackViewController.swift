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
    
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var downloadProgress: UIProgressView!
    @IBOutlet weak var elapsedTime: UILabel!
    @IBOutlet weak var totalTime: UILabel!
    @IBOutlet weak var sliderTimer: UISlider!
    
    var mediaPlayer = VLCMediaListPlayer()
    var media: VLCMedia!
    let fileManager = FileManager.default
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        let number = "\(postNumber ?? 0)"
        if let videoData = UserDefaults.standard.data(forKey: number) {
            print("cache memory")
            do {
                try setVideoDataToFolder(videoData: videoData)
                
            } catch {
                callAlertView(title: "Failed to load video",
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
    
    private func stopActivity() {
        mediaPlayer.stop()
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
        mediaPlayer.mediaList = mediaList
        mediaPlayer.repeatMode = .repeatCurrentItem
        mediaPlayer.play(media)
    }
    
    @IBAction func saveVideo(_ sender: Any) {
        shouldSave = true
        (sender as? UIButton)?.setTitle("Saved", for: .normal)
        (sender as? UIButton)?.isEnabled = false
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        //block timer =  true
        print((sender as? UISlider)?.value)
    }
}

extension PlaybackViewController: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        //if !block timer 
        elapsedTime.text = mediaPlayer.mediaPlayer.time!.debugDescription
        totalTime.text = mediaPlayer.mediaPlayer.media.length.debugDescription
        sliderTimer.maximumValue = Float(mediaPlayer.mediaPlayer.media.length.intValue)
        sliderTimer.value = Float(mediaPlayer.mediaPlayer.time.intValue)
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
            callAlertView(title: "Failed to load video",
                          message: "Failed to load video from server. Try again later.")
        }
    }
}
