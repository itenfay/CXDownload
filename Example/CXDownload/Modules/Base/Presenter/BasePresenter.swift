//
//  BasePresenter.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/7.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import Foundation

protocol Presenter: AnyObject {
    func loadData()
}

class BasePresenter: NSObject, Presenter {
    
    func loadData() {}
    
}
