//
//  ViewController.swift
//  CXDownload
//
//  Created by chenxing on 08/09/2022.
//  Copyright (c) 2022 chenxing. All rights reserved.
//

import UIKit
import CXDownload

class ViewController: UIViewController {
    
    @IBOutlet weak var slider1: UISlider!
    @IBOutlet weak var progressLabel1: UILabel!
    @IBOutlet weak var downloadButton1: UIButton!
    @IBOutlet weak var pauseButton1: UIButton!
    @IBOutlet weak var cancelButton1: UIButton!
    @IBOutlet weak var deleteButton1: UIButton!
    
    @IBOutlet weak var slider2: UISlider!
    @IBOutlet weak var progressLabel2: UILabel!
    @IBOutlet weak var downloadButton2: UIButton!
    @IBOutlet weak var pauseButton2: UIButton!
    @IBOutlet weak var cancelButton2: UIButton!
    @IBOutlet weak var deleteButton2: UIButton!
    
    /// The urls for this example. The urls[3] occurs an error(403).
    private var urls: [String] = ["https://dldir1.qq.com/qqfile/QQIntl/QQi_PC/QQIntl2.11.exe", "http://codown.youdao.com/cidian/download/MacDict.dmg", "https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4", "https://accktv.sd-rtn.com/202206211419/178223ad632f0428131b7138f78b0fb6/release/lyric/lrc/1/64ef53ade26b4ba18cc424e6dd6e1628.lrc"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    private func setup() {
        slider1.setThumbImage(UIImage.init(), for: .normal)
        slider1.setThumbImage(UIImage.init(), for: .highlighted)
        slider2.setThumbImage(UIImage.init(), for: .normal)
        slider2.setThumbImage(UIImage.init(), for: .highlighted)
        
        downloadButton1.layer.cornerRadius = 16
        downloadButton1.showsTouchWhenHighlighted = true
        pauseButton1.layer.cornerRadius = 16
        pauseButton1.showsTouchWhenHighlighted = true
        cancelButton1.layer.cornerRadius = 16
        cancelButton1.showsTouchWhenHighlighted = true
        downloadButton1.layer.cornerRadius = 16
        downloadButton1.showsTouchWhenHighlighted = true
        deleteButton1.layer.cornerRadius = 16
        deleteButton1.showsTouchWhenHighlighted = true
        pauseButton2.layer.cornerRadius = 16
        pauseButton2.showsTouchWhenHighlighted = true
        cancelButton2.layer.cornerRadius = 16
        cancelButton2.showsTouchWhenHighlighted = true
        downloadButton2.layer.cornerRadius = 16
        downloadButton2.showsTouchWhenHighlighted = true
        deleteButton2.layer.cornerRadius = 16
        deleteButton2.showsTouchWhenHighlighted = true
        
        pauseButton1.setTitle("暂停", for: .normal)
        pauseButton1.setTitle("下载", for: .selected)
        pauseButton2.setTitle("暂停", for: .normal)
        pauseButton2.setTitle("下载", for: .selected)
        
        addNotification()
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(downloadStateChange(_:)), name: CXDownloadConfig.stateChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgressChange(_:)), name: CXDownloadConfig.progressNotification, object: nil)
    }
    
    @objc func downloadStateChange(_ noti: Notification) {
        guard let downloadModel = noti.object as? CXDownloadModel else {
            return
        }
        if downloadModel.state == .finish {
            CXDLogger.log(message: "filePath: \(downloadModel.localPath ?? "")", level: .info)
        } else if downloadModel.state == .error || downloadModel.state == .cancelled {
            if let stateInfo = downloadModel.stateInfo {
                CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
            }
        }
        if downloadModel.url == urls[0] {
            
        } else if downloadModel.url == urls[1] {
            
        }
    }
    
    @objc func downloadProgressChange(_ noti: Notification) {
        guard let downloadModel = noti.object as? CXDownloadModel else {
            return
        }
        CXDLogger.log(message: "[\(downloadModel.url ?? "")] \(Int(downloadModel.progress * 100)) %", level: .info)
        if downloadModel.url == urls[0] {
            self.progressLabel1.text = "\(Int(downloadModel.progress * 100)) %"
        } else if downloadModel.url == urls[1] {
            self.progressLabel2.text = "\(Int(downloadModel.progress * 100)) %"
        }
    }
    
    private func reset(url: String) {
        if url == urls[0] {
            downloadButton1.setTitle("下载", for: .normal)
            progressLabel1.text = "0%"
            pauseButton1.isSelected = false
        } else if url == urls[1] {
            downloadButton2.setTitle("下载", for: .normal)
            progressLabel2.text = "0%"
            pauseButton2.isSelected = false
        }
    }
    
    @IBAction func onDownloadAction(_ sender: Any) {
        let button = sender as! UIButton
        if button == downloadButton1 {
            //CXDownloadManager.shared.download(url: urls[0])
            downloadButton1.dl.download(url: urls[0])
        }
        else if button == downloadButton2 {
            //CXDownloadManager.shared.download(url: urls[1], toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
            downloadButton2.dl.download(url: urls[1], toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
        }
    }
    
    @IBAction func onPauseAction(_ sender: Any) {
        let button = sender as! UIButton
        button.isSelected = !button.isSelected
        if button == pauseButton1 {
            if button.isSelected {
                //CXDownloadManager.shared.pause(url: urls[0])
                pauseButton1.dl.pauseTask(url: urls[0])
            } else {
                onDownloadAction(downloadButton1)
            }
        }
        else if button == pauseButton2 {
            if button.isSelected {
                //CXDownloadManager.shared.pause(url: urls[1])
                pauseButton2.dl.pauseTask(url: urls[1])
            } else {
                onDownloadAction(downloadButton2)
            }
        }
    }
    
    @IBAction func onCancelAction(_ sender: Any) {
        let button = sender as! UIButton
        if button == cancelButton1 {
            //CXDownloadManager.shared.cancel(url: urls[0])
            cancelButton1.dl.cancelTask(url: urls[0])
            reset(url: urls[0])
        }
        else if button == cancelButton2 {
            //CXDownloadManager.shared.cancel(url: urls[1])
            cancelButton2.dl.cancelTask(url: urls[1])
            pauseButton2.isSelected = false
            reset(url: urls[1])
        }
    }
    
    @IBAction func onDeleteAction(_ sender: Any) {
        let button = sender as! UIButton
        if button == deleteButton1 {
            //CXDownloadManager.shared.deleteTaskAndCache(url: urls[0])
            deleteButton1.dl.deleteTaskAndCache(url: urls[0])
            reset(url: urls[0])
        }
        else if button == deleteButton2 {
            //CXDownloadManager.shared.deleteTaskAndCache(url: urls[1], atDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
            deleteButton2.dl.deleteTaskAndCache(url: urls[1], atDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg")
            reset(url: urls[1])
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
