//
//  PlaybackViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 10/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class PlaybackViewController: UIViewController {
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
        navigationController?.isNavigationBarHidden = false
        navigationController?.popViewController(animated: true)
    }
    
    fileprivate func setupMedia() {
        guard let url = mediaURL else { return }
        mediaPlayer.media = VLCMedia(url: url)
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
