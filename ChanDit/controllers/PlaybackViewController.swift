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
    
    @IBOutlet weak var movieView: UIView!
    
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
            Service(delegate: self).loadVideoData(from: mediaURL)
//            Service(delegate: self).loadData(from: mediaURL, lastModified: nil) { [weak self] (result) in
//                switch result {
//                case .success(let response):
//                     UserDefaults.standard.set(response.data, forKey: number)
//                    do {
//                        try self?.setVideoDataToFolder(videoData: response.data)
//
//                    } catch {
//                        self?.callAlertView(title: "Failed to load video",
//                        message: "Failed to load video from server. Try again later.")
//                    }
//                    self?.setupMediaPLayer()
//                    self?.setupMedia()
//                case .failure(let error):
//                    self?.callAlertView(title: "Failed to load video",
//                                        message: "Failed to load video from server \(error.localizedDescription). Try again later.")
//                }
//            }
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
    
    @IBAction func closeView(_ sender: Any) {
        mediaPlayer.stop()
        if let url = fileURL, !shouldSave {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                print("could not delete file")
            }
        }
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
    
    @IBAction func saveVideo(_ sender: Any) {
        shouldSave = true
        (sender as? UIButton)?.setTitle("Saved", for: .normal)
        (sender as? UIButton)?.isEnabled = false
    }
}

extension PlaybackViewController: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        print(mediaPlayer.mediaPlayer.time.debugDescription)
        print(mediaPlayer.mediaPlayer.remainingTime.debugDescription)
    }
}

extension PlaybackViewController: URLSessionDelegate,
URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                     downloadTask: URLSessionDownloadTask,
                     didWriteData bytesWritten: Int64,
                     totalBytesWritten: Int64,
                     totalBytesExpectedToWrite: Int64) {
        print("perc \(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print(location.absoluteString)
    }
}
