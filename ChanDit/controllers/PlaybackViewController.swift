//
//  PlaybackViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 10/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class PlaybackViewController: UIViewController {
    var mediaURL: URL?
    var filename = "filename_my_file"
    
    @IBOutlet weak var movieView: UIView!
    
    var mediaPlayer = VLCMediaListPlayer()
    var media: VLCMedia!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        setupMediaPLayer()
        setupMedia()
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
        navigationController?.isNavigationBarHidden = false
    }
    
    fileprivate func setupMedia() {
        guard let url = mediaURL else { return }
        media = VLCMedia(url: url)
        let mediaList = VLCMediaList()
        mediaList.add(media)
        mediaPlayer.mediaList = mediaList
        mediaPlayer.repeatMode = .repeatCurrentItem
        mediaPlayer.play(media)
    }
}

extension PlaybackViewController: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        print(mediaPlayer.mediaPlayer.time.debugDescription)
        print(mediaPlayer.mediaPlayer.remainingTime.debugDescription)
    }
}
