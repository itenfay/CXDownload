//
//  VPlayerController.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/17.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import CXDownload

class VPlayerController: BaseViewController {
    
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    
    var path: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func makeUI() {
        guard let localPath = path else {
            print("Warning: the path can not be nil.")
            return
        }
        
        let slider = UISlider(frame: CGRect(x: 30, y: kNavigaH + kFitScale(AT: 400), width: kScreenW - 60, height: 50))
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(slider)
        
        player = AVPlayer(url: URL(fileAtPath: localPath))
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0, y: kNavigaH, width: kScreenW, height: 400)
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
        player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: DispatchQueue.main) { [weak self] time in
            guard let s = self, let item = s.player.currentItem else {
                return
            }
            slider.value = Float(CMTimeGetSeconds(time) / CMTimeGetSeconds(item.duration))
        }
    }
    
    @objc func sliderValueChanged(_ slider: UISlider) {
        guard let item = player.currentItem else {
            return
        }
        let time = slider.value * Float(CMTimeGetSeconds(item.duration))
        player.seek(to: CMTime(value: CMTimeValue(time), timescale: 1), toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
}
