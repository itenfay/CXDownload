//
//  HomePresenter.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import CXDownload

class HomePresenter: BasePresenter {
    
    private unowned let view: HomeViewable
    private var dataSource: [DataModel] = []
    private let apiClient: ApiClient
    
    init(view: HomeViewable, apiClient: ApiClient) {
        self.view = view
        self.apiClient = apiClient
        super.init()
        self.addNotification()
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(downloadStateChange(_:)), name: CXDownloadConfig.stateChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgressChange(_:)), name: CXDownloadConfig.progressNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clearAllCaches(_:)), name: NSNotification.Name("ClearAllCachesNotification"), object: nil)
    }
    
    override func loadData() {
        guard let dataPath = Bundle.main.path(forResource: "testData", ofType: "plist"),
              let array = NSArray(contentsOfFile: dataPath) else {
            return
        }
        dataSource.removeAll()
        
        for e in array {
            if e is Dictionary<String, String> {
                let dict = e as! Dictionary<String, String>
                let model = DataModel()
                model.vid = dict["vid"] ?? ""
                model.fileName = dict["fileName"] ?? ""
                model.url = dict["url"] ?? ""
                dataSource.append(model)
            }
        }
        
        getCacheData()
        
        view.refreshView()
    }
    
    func getCacheData() {
        let cachedModels = CXDownloadDatabaseManager.shared.getAllCacheData()
        for (i, model) in dataSource.enumerated() {
            for m in cachedModels {
                if model.url == m.url {
                    let newModel = DataModel()
                    newModel.vid = model.vid
                    newModel.url = model.url
                    newModel.fileName = model.fileName
                    newModel.state = m.state
                    dataSource[i] = newModel
                }
            }
        }
    }
    
    @objc func downloadStateChange(_ noti: Notification) {
        guard let model = noti.object as? CXDownloadModel else {
            return
        }
        updateSourceModel(model)
    }
    
    @objc func downloadProgressChange(_ noti: Notification) {
        guard let model = noti.object as? CXDownloadModel else {
            return
        }
        updateSourceModel(model)
    }
    
    private func updateSourceModel(_ model: CXDownloadModel) {
        for (index, source) in dataSource.enumerated() {
            if source.url == model.url {
                // Update model.
                let dataModel = model.toDataModel(with: source.vid)
                dataSource[index] = dataModel
                updateView(model: dataModel, at: index)
                break
            }
        }
    }
    
    private func updateView(model: DataModel, at index: Int) {
        if !CXDownloadManager.shared.hasClosured(url: model.url) {
            view.updateView(model: model, atIndex: index)
        }
    }
    
    func updateCell(_ cell: UITableViewCell?, with model: DataModel) {
        guard let homeCell = cell as? HomeTableViewCell else {
            if model.state == .finish {
                view.refreshView()
            }
            return
        }
        homeCell.reloadLabelWithModel(model)
    }
    
    private func configure(cell: HomeTableViewCell, for indexPath: IndexPath) {
        let index = indexPath.item
        if index < dataSource.count {
            cell.bind(to: dataSource[index])
        }
    }
    
    @objc func clearAllCaches(_ noti: Notification) {
        loadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: CXDownloadConfig.stateChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: CXDownloadConfig.progressNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ClearAllCachesNotification"), object: nil)
    }
    
}

extension HomePresenter: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableViewCell")
        if cell == nil {
            cell = HomeTableViewCell(style: .default, reuseIdentifier: "HomeTableViewCell")
        }
        cell!.selectionStyle = .none
        
        //cell!.backgroundColor = .white
        //let backgroundView = UIView(frame: cell!.frame)
        //backgroundView.backgroundColor = UIColor(red: 0, green: 198/255, blue: 198/255, alpha: 1)
        //cell!.backgroundView = backgroundView
        
        configure(cell: cell as! HomeTableViewCell, for: indexPath)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}
