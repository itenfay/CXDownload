//
//  ViewController.swift
//  CXDownload
//
//  Created by chenxing on 08/09/2022.
//  Copyright (c) 2022 chenxing. All rights reserved.
//

import UIKit
import CXDownload

/// The url for this example.
public let urlStr1 = "https://dldir1.qq.com/qqfile/QQIntl/QQi_PC/QQIntl2.11.exe"
public let urlStr2 = "http://codown.youdao.com/cidian/download/MacDict.dmg"
public let urlStr3 = "https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4"
/// The urlStr4 occurs 403 error.
public let urlStr4 = "https://accktv.sd-rtn.com/202206211419/178223ad632f0428131b7138f78b0fb6/release/lyric/lrc/1/64ef53ade26b4ba18cc424e6dd6e1628.lrc"

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        let dataArray = CXDownloadDatabaseManager.shared.getAllCacheData()
        for model in dataArray {
            print("\(model)")
        }
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
        pauseButton1.setTitle("恢复", for: .selected)
        pauseButton2.setTitle("暂停", for: .normal)
        pauseButton2.setTitle("恢复", for: .selected)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onDownloadAction(_ sender: Any) {
        let button = sender as! UIButton
        if button == downloadButton1 {
            /*CXDownloadManager.shared.download(url: urlStr1) { [weak self] model in
                self?.progressLabel1.text = "\(Int(model.progress * 100)) %"
            } success: { model in
                CXDLogger.log(message: "filePath: \(model.localPath ?? "")", level: .info)
            } failure: { model in
                if let stateInfo = model.stateInfo {
                    CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
                }
            }*/
            
            downloadButton1.dl.download(url: urlStr1) { [weak self] model in
                self?.progressLabel1.text = "\(Int(model.progress * 100)) %"
            } success: { model in
                CXDLogger.log(message: "filePath: \(model.localPath ?? "")", level: .info)
            } failure: {  model in
                if let stateInfo = model.stateInfo {
                    CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
                }
            }
        }
        
        else if button == downloadButton2 {
            /*CXDownloadManager.shared.download(url: urlStr2, toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg") { [weak self] model in
                self?.progressLabel2.text = "\(Int(model.progress * 100)) %"
            } success: { model in
                CXDLogger.log(message: "filePath: \(model.localPath ?? "")", level: .info)
            } failure: { model in
                if let stateInfo = model.stateInfo {
                    CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
                }
            }*/
            
            downloadButton2.dl.download(url: urlStr2, toDirectory: "Softwares", fileName: "MacDict_v1.20.30.dmg") { [weak self] model in
                self?.progressLabel2.text = "\(Int(model.progress * 100)) %"
            } success: { model in
                CXDLogger.log(message: "filePath: \(model.localPath ?? "")", level: .info)
            } failure: {  model in
                if let stateInfo = model.stateInfo {
                    CXDLogger.log(message: "error: \(stateInfo.code), message: \(stateInfo.message)", level: .info)
                }
            }
        }
    }
    
    @IBAction func onPauseAction(_ sender: Any) {
        let button = sender as! UIButton
        button.isSelected = !button.isSelected
        if button == pauseButton1 {
            if button.isSelected {
                //CXDownloadManager.shared.pauseWithURLString(urlStr1)
                pauseButton1.dl.pauseDownloadTask(urlStr1)
            } else {
                onDownloadAction(downloadButton1)
            }
        }
        else if button == pauseButton2 {
            if button.isSelected {
                //CXDownloadManager.shared.pauseWithURLString(urlStr2)
                pauseButton2.dl.pauseDownloadTask(urlStr2)
            } else {
                onDownloadAction(downloadButton2)
            }
        }
    }
    
    @IBAction func onCancelAction(_ sender: Any) {
        let button = sender as! UIButton
        if button == cancelButton1 {
            //CXDownloadManager.shared.cancelWithURLString(urlStr1)
            cancelButton1.dl.cancelDownloadTask(urlStr1)
            downloadButton1.setTitle("下载", for: .normal)
            progressLabel1.text = "0%"
            pauseButton1.isSelected = false
        }
        else if button == cancelButton2 {
            //CXDownloadManager.shared.cancelWithURLString(urlStr2)
            cancelButton2.dl.cancelDownloadTask(urlStr2)
            downloadButton2.setTitle("下载", for: .normal)
            progressLabel2.text = "0%"
            pauseButton2.isSelected = false
        }
    }
    
    @IBAction func onDeleteAction(_ sender: Any) {
        let button = sender as! UIButton
        if button == deleteButton1 {
            //CXDownloadManager.shared.deleteTaskAndCache(url: urlStr1)
            deleteButton1.dl.deleteTaskAndCache(url: urlStr1)
            downloadButton1.setTitle("下载", for: .normal)
            progressLabel1.text = "0%"
            pauseButton1.isSelected = false
        }
        else if button == deleteButton2 {
            /*
            CXDownloadManager.shared.deleteTaskAndCache(
                url: urlStr2,
                atDirectory: "Softwares",
                fileName: "MacDict_v1.20.30.dmg"
            )*/
            deleteButton2.dl.deleteTaskAndCache(
                url: urlStr2,
                atDirectory: "Softwares",
                fileName: "MacDict_v1.20.30.dmg"
            )
            downloadButton2.setTitle("下载", for: .normal)
            progressLabel2.text = "0%"
            pauseButton2.isSelected = false
        }
    }
    
}

