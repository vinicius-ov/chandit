//
//  PlaybackViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 10/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
// swiftlint:disable trailing_whitespace

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
    @IBOutlet weak var timerHud: UIStackView!
    @IBOutlet weak var buttonsHud: UIStackView!
    
    var mediaListPlayer = VLCMediaListPlayer()
    var media: VLCMedia!
    let fileManager = FileManager.default
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true

        sliderTimer.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        movieView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleHud(_:))))

        do {
            try fileURL = getVideoURL()
            let path = fileURL?.path ?? ""
            setupMediaPLayer()
            if fileManager.fileExists(atPath: path) {
                setupMedia()

            } else {
                task = Service(delegate: self).loadVideoData(from: mediaURL)
                task.resume()

            }
        } catch {
            showAlertView(title: "Failed to load video",
            message: "Failed to load video from server. Try again later.")
        }
    }
    
    @objc
    func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .ended:
                let value = slider.value
                mediaListPlayer.mediaPlayer.time = VLCTime(number: NSNumber(value: value))
                blockTimer = false
            default:
                break
            }
        }
    }
    
    private func setVideoDataToFolder(videoData: Data) throws {
        let documentDirectory = try getBaseDirectory(for: .cachesDirectory)
        try fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
        fileURL = documentDirectory.appendingPathComponent(self.filename, isDirectory: false)
        try videoData.write(to: fileURL!)
    }

    private func getVideoURL() throws -> URL {
        let documentDirectory = try getBaseDirectory(for: .cachesDirectory)
        let path = documentDirectory.appendingPathComponent(self.filename,
                                    isDirectory: false)
        return path
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mediaListPlayer.play()
    }
    
    func setupMediaPLayer() {
        mediaListPlayer.mediaPlayer.delegate = self
        mediaListPlayer.mediaPlayer.drawable = movieView
        var volume: Int32 = 0
        if UserDefaults.standard.integer(forKey: "webm_volume") == 1 {
            let isSfw = UserDefaults.standard.bool(forKey: "isSfw")
            if isSfw {
                volume = 100
            }
        }
        mediaListPlayer.mediaPlayer.audio.volume = volume
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
        toggleHud(self)
    }

    func saveWebm() throws {
        let documentDirectory = try getBaseDirectory(for: .documentDirectory)
        try fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
        let filenameExtension = documentDirectory
            .appendingPathComponent(filename ?? "a", isDirectory: false)
            .appendingPathExtension("webm")
        try fileManager.copyItem(at: fileURL!, to: filenameExtension)
    }

    @IBAction func saveVideo(_ sender: Any) {
        do {
            try saveWebm()
        } catch {
            showAlertView(title: "Failed to save video",
            message: "Failed saving webm locally. Maybe video was already saved?")
        }
        (sender as? UIButton)?.setTitle("Saved", for: .normal)
        (sender as? UIButton)?.isEnabled = false
    }

    @IBAction func valueChanged(_ sender: UISlider) {
        blockTimer = true
        elapsedTime.text = "\(VLCTime(number: NSNumber(value: sender.value)) ?? VLCTime())"
    }
    
    @objc
    func toggleHud(_ sender: Any) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.buttonsHud.alpha = self.buttonsHud.alpha == 1.0 ? 0.0 : 1.0
                self.timerHud.alpha = self.timerHud.alpha == 1.0 ? 0.0 : 1.0
            })
        }
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
    
    fileprivate func showAlertFailedLoadVideo(_ localizedDescription: String? = "") {
        showAlertView(title: "Failed to load video",
                      message: "Failed to load video from server. Try again later.")
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            try setVideoDataToFolder(videoData: data)
            setupMedia()
        } catch {
            showAlertFailedLoadVideo()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        showAlertFailedLoadVideo(error.localizedDescription)
    }
}

extension PlaybackViewController {
    func getBaseDirectory(for path: FileManager.SearchPathDirectory) throws -> URL {
        let fileManager = FileManager.default
        let url = try fileManager.url(for: path, in: .userDomainMask,
                                      appropriateFor: nil, create: false)
        if path == .documentDirectory {
            return url.appendingPathComponent("webm", isDirectory: true)
        }
        let bundle: String = Bundle.main.bundleIdentifier ?? ""
        return url.appendingPathComponent(bundle, isDirectory: true).appendingPathComponent("webm", isDirectory: true)
    }
}
