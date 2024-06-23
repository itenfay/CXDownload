//
//  HomeTableViewCell.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/10.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import UIKit
import CXDownload

class HomeTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
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
            adaptDownloadButtonStyle(with: state)
        }
    }
    
    private var url: String?
    private var vid: String = ""
    private var fileName: String = ""
    private var progress: Float = 0
    
    override func setup() {
        progressLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        progressLabel.textColor = .orange
        progressLabel.isUserInteractionEnabled = true
    }
    
    override func layoutUI() {
        
    }
    
    override func addActions() {
        downloadButton.addTarget(self, action: #selector(onDownloadClick(_:)), for: .touchUpInside)
        progressLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(progressLabelDidTap)))
    }
    
    func bind(to model: DataModel) {
        url = model.url
        vid = model.vid
        fileName = model.fileName
        nameLabel.text = model.fileName
        speedLabel.text = ""
        progressLabel.text = ""
        totalLabel.text = ""
        progress = model.progress
        reloadLabelWithModel(model)
    }
    
    func updateDownloadState(_ state: CXDownloadState) {
        self.state = state
    }
    
    func adaptDownloadButtonStyle(with state: CXDownloadState) {
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
        if state == .downloading {
            progressLabel.text = "\(Int(progress * 100))%"
            downloadButton.layer.cornerRadius = 30
            downloadButton.layer.borderWidth = 1
            downloadButton.layer.borderColor = UIColor.orange.cgColor
        } else {
            progressLabel.text = ""
            downloadButton.layer.cornerRadius = 0
            downloadButton.layer.borderWidth = 0
        }
    }
    
    func reloadLabelWithModel(_ model: DataModel) {
        // Resolve reusable cell.
        if model.url != url { return }
        
        progress = model.progress
        updateDownloadState(model.state)
        
        let totalSize = CXDToolbox.string(fromByteCount: model.totalFileSize)
        let tmpSize = CXDToolbox.string(fromByteCount: model.tmpFileSize)
        if model.state == .finish {
            totalLabel.text = totalSize
        } else {
            if model.tmpFileSize > 0 && model.totalFileSize > 0 {
                totalLabel.text = "\(tmpSize) / \(totalSize)"
            } else {
                totalLabel.text = ""
            }
        }
        
        if model.speed > 0 {
            speedLabel.text = CXDToolbox.string(fromByteCount: model.speed) + " / s"
        }
        speedLabel.isHidden = !(model.state == .downloading && model.totalFileSize > 0)
    }
    
    @objc func progressLabelDidTap() {
        onDownloadClick(downloadButton)
    }
    
    @objc func onDownloadClick(_ sender: UIButton) {
        guard let url = url else { return }
        if state == .default || state == .cancelled || state == .paused || state == .error {
            CXDownloadManager.shared.download(url: url, toDirectory: nil, fileName: fileName)
        } else if state == .downloading || state == .waiting {
            CXDownloadManager.shared.pause(url: url)
        }
    }
    
}
