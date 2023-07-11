//
//  HomeTableViewCell.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/10.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import CXDownload

class HomeTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private var state: CXDownloadState = .default {
        didSet {
            changeImageForDownloadButton(by: state)
        }
    }
    
    private var url: String?
    private var vid: String = ""
    private var fileName: String = ""
    
    override func setup() {
        
    }
    
    override func layoutUI() {
        
    }
    
    override func addActions() {
        downloadButton.addTarget(self, action: #selector(onDownloadClick(_:)), for: .touchUpInside)
    }
    
    func bind(to model: DataModel) {
        url = model.url
        vid = model.vid
        fileName = model.fileName
        nameLabel.text = model.fileName
        speedLabel.text = ""
        updateDownloadState(model.state)
    }
    
    func updateDownloadState(_ state: CXDownloadState) {
        self.state = state
    }
    
    func changeImageForDownloadButton(by state: CXDownloadState) {
        var image: UIImage?
        switch state {
        case .`default`:
            image = UIImage(named: "com_download_default")
        case .downloading: break
        case .waiting:
            image = UIImage(named: "com_download_waiting")
        case .paused:
            image = UIImage(named: "com_download_pause")
        case .finish:
            image = UIImage(named: "com_download_finish")
        case .cancelled, .error:
            image = UIImage(named: "com_download_error")
        }
        downloadButton.setImage(image, for: .normal)
    }
    
    func reloadLabelWithModel(_ model: DataModel) {
        changeImageForDownloadButton(by: model.state)
        
        let totalSize = CXDToolbox.string(fromByteCount: model.totalFileSize)
        let tmpSize = CXDToolbox.string(fromByteCount: model.tmpFileSize)
        if model.state == .finish {
            progressLabel.text = totalSize + " | \(Int(model.progress * 100))%"
        } else {
            progressLabel.text = "\(tmpSize) / \(totalSize)" + " | \(Int(model.progress * 100))%"
        }
        
        if model.speed > 0 {
            speedLabel.text = CXDToolbox.string(fromByteCount: model.speed) + " / s"
        }
        
        speedLabel.isHidden = !(model.state == .downloading && model.totalFileSize > 0)
    }
    
    @objc func onDownloadClick(_ sender: UIButton) {
        guard let url = url else { return }
        if state == .default || state == .cancelled || state == .paused || state == .error {
            CXDownloadManager.shared.download(url: url, toDirectory: nil, fileName: fileName) { [weak self] model in
                self?.reloadLabelWithModel(model.toDataModel(with: self?.vid ?? ""))
            } success: { [weak self] model in
                self?.reloadLabelWithModel(model.toDataModel(with: self?.vid ?? ""))
            } failure: { [weak self] model in
                self?.reloadLabelWithModel(model.toDataModel(with: self?.vid ?? ""))
            }
        } else if state == .downloading || state == .waiting {
            CXDownloadManager.shared.pauseWithURLString(url)
        }
    }
    
}
