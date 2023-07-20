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
        guard let downloadModel = noti.object as? CXDownloadModel else {
            return
        }
        for (index, model) in dataSource.enumerated() {
            if downloadModel.url == model.url {
                dataSource[index] = downloadModel.toDataModel(with: model.vid)
                view.reloadRow(atIndex: index)
                break
            }
        }
    }
    
    @objc func downloadProgressChange(_ noti: Notification) {
        guard let downloadModel = noti.object as? CXDownloadModel else {
            return
        }
        for (index, model) in dataSource.enumerated() {
            if downloadModel.url == model.url {
                dataSource[index] = downloadModel.toDataModel(with: model.vid)
                view.updateViewCell(atIndex: index)
                break
            }
        }
    }
    
    func update(cell: UITableViewCell?, at index: Int) {
        guard let homeCell = cell as? HomeTableViewCell else {
            return
        }
        guard index < dataSource.count else { return }
        homeCell.bind(to: dataSource[index])
    }
    
    private func configure(cell: HomeTableViewCell, at indexPath: IndexPath) {
        let index = indexPath.item
        if index < dataSource.count {
            cell.bind(to: dataSource[index])
        }
    }
    
    @objc func clearAllCaches(_ noti: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadData()
        }
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
        
        configure(cell: cell as! HomeTableViewCell, at: indexPath)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let homeVC = view as? HomeViewController else {
            return
        }
        if indexPath.item < dataSource.count {
            let model = dataSource[indexPath.item]
            if model.state == .finish {
                let filePath = CXDFileUtils.filePath(withURL: URL(string: model.url)!, atDirectory: model.directory, fileName: model.fileName)
                let playerVC = VPlayerController(path: filePath)
                playerVC.hidesBottomBarWhenPushed = true
                homeVC.navigationController?.pushViewController(playerVC, animated: true)
            }
        }
    }
    
}
