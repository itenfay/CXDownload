//
//  HomeView.swift
//  CXDownload_Example
//
//  Created by chenxing on 2023/7/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

protocol HomeViewable: AnyObject {
    func refreshView()
    func reloadRows(atIndex index: Int)
    func updateView(model: DataModel, atIndex index: Int)
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
    
    func reloadRows(at index: Int) {
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    func getCell(at index: Int) -> UITableViewCell? {
        var cell: UITableViewCell?
        DispatchQueue.main.async {
            cell = self.tableView.cellForRow(at: IndexPath(item: index, section: 0))
        }
        return cell
    }
    
}
