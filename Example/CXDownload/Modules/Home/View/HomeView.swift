//
//  HomeView.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/7.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import UIKit

protocol HomeViewable: AnyObject {
    func refreshView()
    func reloadRow(atIndex index: Int)
    func updateViewCell(atIndex index: Int)
}

class HomeView: BaseView {
    
    private var tableView: UITableView!
    
    override var frame: CGRect {
        didSet {
            tableView?.frame = CGRect(origin: CGPoint(x: 0, y: kNavigaH),
                                      size: CGSize(width: frame.width, height: frame.height - kNavigaH - kTabBarH))
        }
    }
    
    override func setup() {
        buildView()
    }
    
    func buildView() {
        tableView = UITableView(frame: .zero)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.register(UINib(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: "HomeTableViewCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        addSubview(tableView)
    }
    
    func setTableDelegate(_ delegate: (UITableViewDelegate & UITableViewDataSource)?) {
        tableView.delegate = delegate
        tableView.dataSource = delegate
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    func reloadRow(at index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    func getTableViewCell(forRow item: Int) -> UITableViewCell? {
        return tableView.cellForRow(at: IndexPath(item: item, section: 0))
    }
    
}
