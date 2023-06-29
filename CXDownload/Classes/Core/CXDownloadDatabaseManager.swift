//
//  CXDownloadDatabaseManager.swift
//  CXDownload
//
//  Created by chenxing on 2023/6/28.
//

import UIKit
import FMDB

class CXDownloadDatabaseManager: NSObject {
    
    @objc public static let shared = CXDownloadDatabaseManager()
    
    private var dbQueue: FMDatabaseQueue!
    
    private override init() {
        super.init()
        self.createTable()
    }
    
    func createTable() {
        let path = CXDFileUtils.cachePath(withPathComponent: "dl.db")?.cxd_appendingPathComponent("x.f").cxd_path
        
        // Create db queue using path.
        dbQueue = FMDatabaseQueue(path: path)
        
        dbQueue.inDatabase { db in
            let sql = "CREATE TABLE IF NOT EXISTS x();"
            do {
                try db.executeUpdate(sql, values: nil)
                CXDLogger.log(message: "Creating table is OK.", level: .info)
            } catch {
                CXDLogger.log(message: "Creating table is failed.: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
}
