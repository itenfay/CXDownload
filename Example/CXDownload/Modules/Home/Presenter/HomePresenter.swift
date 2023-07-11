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
    
    private var view: HomeViewable
    private var dataSource: [DataModel] = []
    let apiClient: ApiClient
    
    init(view: HomeViewable, apiClient: ApiClient) {
        self.view = view
        self.apiClient = apiClient
        super.init()
        self.addNotification()
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(downloadStateChange(_:)), name: CXDownloadConfig.stateChangeNotification, object: nil)
    }
    
    override func loadData() {
        guard let dataPath = Bundle.main.path(forResource: "testData", ofType: "plist"),
              let array = NSArray(contentsOfFile: dataPath) else {
            return
        }
        
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
                    newModel.fileName = m.fileName ?? ""
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
        for (i, source) in dataSource.enumerated() {
            if source.url == model.url {
                dataSource[i] = model.toDataModel(with: source.vid)
                view.reloadRows(atIndex: i)
                break
            }
        }
    }
    
    private func configure(cell: HomeTableViewCell, for indexPath: IndexPath) {
        let index = indexPath.item
        if index < dataSource.count {
            cell.bind(to: dataSource[index])
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: CXDownloadConfig.stateChangeNotification, object: nil)
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
        configure(cell: cell as! HomeTableViewCell, for: indexPath)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}
