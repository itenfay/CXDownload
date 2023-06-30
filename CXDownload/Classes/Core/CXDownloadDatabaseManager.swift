//
//  CXDownloadDatabaseManager.swift
//  CXDownload
//
//  Created by chenxing on 2023/6/28.
//

import Foundation
#if canImport(FMDB)
import FMDB

enum CXDBGetDataType: Int {
    case allCacheData           // Get all cache data.
    case allDownloadingData     // Get all downloading data.
    case allDownloadedData      // Get all downloaded data.
    case allUnDownloadedData    // Get all unDownloaded data.
    case allWaitingData         // Get all waiting data.
    case modelByUrl             // Get model by url.
    case waitingModel           // Get first waiting model.
    case lastDownloadingModel   // Get last downloading model.
}

struct CXDBUpdateOption: OptionSet {
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Update state.
    static let state  = CXDBUpdateOption(rawValue: 1 << 0)
    /// Update last time of changed state.
    static let lastStateTime = CXDBUpdateOption(rawValue: 1 << 1)
    /// Update the progress data(tmpFileSize、totalFileSize、progress、intervalFileSize、lastSpeedTime).
    static let progressData = CXDBUpdateOption(rawValue: 1 << 2)
    /// Update all data.
    static let allParam = CXDBUpdateOption(rawValue: 1 << 3)
}

public class CXDownloadDatabaseManager: NSObject {
    
    @objc public static let shared = CXDownloadDatabaseManager()
    
    private var dbQueue: FMDatabaseQueue!
    /// Represents the table is created.
    private var tableCreated: Bool = false
    
    private override init() {
        super.init()
        self.createTable()
    }
    
    /// Create a table.
    func createTable() {
        let path = CXDFileUtils.cachePath(withPathComponent: "cxDLDB")?.cxd_appendingPathComponent("cxDLFileCaches.db").cxd_path
        
        // Create db queue using path.
        dbQueue = FMDatabaseQueue(path: path)
        
        dbQueue.inDatabase { db in
            let sql = "CREATE TABLE IF NOT EXISTS t_fileCaches (id integer PRIMARY KEY AUTOINCREMENT, fid text, fileName text, url text, totalFileSize integer, tmpFileSize integer, state integer, progress float, lastSpeedTime double, intervalFileSize integer, lastStateTime integer);"
            do {
                try db.executeUpdate(sql, values: nil)
                tableCreated = true
                CXDLogger.log(message: "Creating table is OK.", level: .info)
            } catch {
                CXDLogger.log(message: "Creating table is failed, error: \(error.localizedDescription).", level: .error)
            }
        }
    }
    
    /// Inserts a model into the table.
    func insertModel(_ model: CXDownloadModel) {
        guard tableCreated else { return }
        dbQueue.inDatabase { db in
            let sql = "INSERT INTO t_fileCaches (fid, fileName, url, totalFileSize, tmpFileSize, state, progress, lastSpeedTime, intervalFileSize, lastStateTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
            do {
                try db.executeUpdate(sql, values: [model.fid ?? "", model.fileName ?? "", model.url ?? "", model.totalFileSize, model.tmpFileSize, model.state.rawValue, model.progress, model.lastSpeedTime, model.intervalFileSize, model.lastStateTime])
                CXDLogger.log(message: "Inserting data is successful.", level: .info)
            } catch {
                CXDLogger.log(message: "Insert data: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    func getModel(by url: String) -> CXDownloadModel? {
        return getModel(with: CXDBGetDataType.modelByUrl, url: url)
    }
    
    func getModel(with dataType: CXDBGetDataType, url: String) -> CXDownloadModel? {
        guard tableCreated else { return nil }
        var model: CXDownloadModel?
        dbQueue.inDatabase { db in
            do {
                var resultSet: FMResultSet!
                switch dataType {
                case .modelByUrl:
                    resultSet = try db.executeQuery("SELECT * FROM t_fileCaches WHERE url = ?;", values: [url])
                case .waitingModel:
                    resultSet = try db.executeQuery("SELECT * FROM t_fileCaches WHERE state = ? order by lastStateTime asc limit 0,1;", values: [CXDownloadState.waiting.rawValue])
                case .lastDownloadingModel:
                    resultSet = try db.executeQuery("SELECT * FROM t_fileCaches WHERE state = ? order by lastStateTime desc limit 0,1;", values: [CXDownloadState.downloading.rawValue])
                default: break
                }
                guard let rs = resultSet else {
                    return
                }
                while rs.next() {
                    model = CXDownloadModel(resultSet: rs)
                }
            } catch {
                CXDLogger.log(message: "Selecting data occurs error: \(error.localizedDescription)", level: .error)
            }
        }
        return model
    }
    
    /// Gets the first waiting data.
    func getWaitingModel() -> CXDownloadModel? {
        return getModel(with: .waitingModel, url: "")
    }
    
    /// Gets the last downloading data.
    func getLastDownloadingModel() -> CXDownloadModel? {
        return getModel(with: .lastDownloadingModel, url: "")
    }
    
    /// Gets the all cache data.
    @objc public func getAllCacheData() -> [CXDownloadModel] {
        return getModels(with: .allCacheData)
    }
    
    /// Gets the all downloading data.
    func getAllDownloadingData() -> [CXDownloadModel] {
        return getModels(with: .allDownloadingData)
    }
    
    /// Gets the all downloaded data.
    @objc public func getAllDownloadedData() -> [CXDownloadModel] {
        return getModels(with: .allDownloadedData)
    }
    
    /// Gets the all undownloaded data.
    @objc public func getAllUnDownloadedData() -> [CXDownloadModel] {
        return getModels(with: .allUnDownloadedData)
    }
    
    /// Get the all waiting data.
    func getAllWaitingData() -> [CXDownloadModel] {
        return getModels(with: .allWaitingData)
    }
    
    func getModels(with dataType: CXDBGetDataType) -> [CXDownloadModel] {
        var dataArray: [CXDownloadModel] = []
        guard tableCreated else { return dataArray }
        dbQueue.inDatabase { db in
            var resultSet: FMResultSet!
            switch dataType {
            case .allCacheData:
                resultSet = try? db.executeQuery("SELECT * FROM t_fileCaches;", values: nil)
            case .allDownloadingData:
                resultSet = try? db.executeQuery("SELECT * FROM t_fileCaches WHERE state = ? order by lastStateTime desc;", values: [CXDownloadState.downloading.rawValue])
            case .allDownloadedData:
                resultSet = try? db.executeQuery("SELECT * FROM t_fileCaches WHERE state = ?;", values: [CXDownloadState.finish.rawValue])
            case .allUnDownloadedData:
                resultSet = try? db.executeQuery("SELECT * FROM t_fileCaches WHERE state != ?;", values: [CXDownloadState.finish.rawValue])
            case .allWaitingData:
                resultSet = try? db.executeQuery("SELECT * FROM t_fileCaches WHERE state = ?;", values: [CXDownloadState.waiting.rawValue])
            default: break
            }
            guard let rs = resultSet else {
                CXDLogger.log(message: "Don't select data...", level: .info)
                return
            }
            while rs.next() {
                dataArray.append(CXDownloadModel(resultSet: rs))
            }
        }
        return dataArray
    }
    
    func updateModel(_ model: CXDownloadModel, option: CXDBUpdateOption) {
        guard tableCreated else { return }
        dbQueue.inDatabase { [weak self] db in
            guard let url = model.url else {
                return
            }
            if option.contains(.state) {
                self?.postStateChangeNotification(with: db, model: model)
                try? db.executeUpdate("UPDATE t_fileCaches SET state = ? WHERE url = ?;", values: [model.state.rawValue, url])
            }
            if option.contains(.lastStateTime) {
                try? db.executeUpdate("UPDATE t_fileCaches SET lastStateTime = ? WHERE url = ?;", values: [0, url])
            }
            if option.contains(.progressData) {
                try? db.executeUpdate("UPDATE t_fileCaches SET totalFileSize = ?, tmpFileSize = ?, progress = ?, lastSpeedTime = ?, intervalFileSize = ? WHERE url = ?;", values: [model.totalFileSize, model.tmpFileSize, model.progress, model.lastSpeedTime, model.intervalFileSize, url])
            }
            if option.contains(.allParam) {
                self?.postStateChangeNotification(with: db, model: model)
                try? db.executeUpdate("UPDATE t_fileCaches SET totalFileSize = ?, tmpFileSize = ?, progress = ?, state = ?, lastSpeedTime = ?, intervalFileSize = ?, lastStateTime = ? WHERE url = ?;", values: [model.totalFileSize, model.tmpFileSize, model.progress, model.state, model.lastSpeedTime, model.intervalFileSize, model.lastStateTime, url])
            }
        }
    }
    
    private func postStateChangeNotification(with db: FMDatabase, model: CXDownloadModel) {
        guard let url  = model.url else { return }
        guard let rs = try? db.executeQuery("SELECT state FROM t_fileCaches WHERE url = ?;", values: [url]) else {
            return
        }
        var oldState: CXDownloadState?
        while rs.next() {
            oldState = CXDownloadState(rawValue: rs.long(forColumn: "state"))
        }
        if let oState = oldState, oldState != model.state, oState != .finish {
            NotificationCenter.default.post(name: CXDownloadConfig.stateChangeNotification, object: model)
        }
    }
    
    func deleteModel(by url: String) {
        guard tableCreated else { return }
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("DELETE FROM t_fileCaches WHERE url = ?;", values: [url])
            } catch let error {
                CXDLogger.log(message: "[\(url)] Deleting data occurs error: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
}

#endif
