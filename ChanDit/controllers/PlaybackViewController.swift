//
//  PlaybackViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 10/09/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

class PlaybackViewController: UIViewController {
    //let mediaURL:String? = nil
    var mediaURL:URL? = nil
    
    @IBOutlet weak var movieView: UIView!
    
    var mediaPlayer = VLCMediaPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMediaPLayer()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mediaPlayer.play()
    }
    
    func setupMediaPLayer() {
        guard let url = mediaURL else { return }
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
        mediaPlayer.media = VLCMedia(url: url)
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
}

extension PlaybackViewController: VLCMediaPlayerDelegate {
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        if mediaPlayer.state == .stopped {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

