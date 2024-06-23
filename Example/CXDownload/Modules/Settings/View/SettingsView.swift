//
//  SettingsView.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/7.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import UIKit
import CXDownload

protocol SettingsViewable: AnyObject {
    
}

class SettingsView: BaseView {
    
    var maxConcurrentCountWarningAction: (() -> Void)?
    var maxConcurrentCountUpdatingAction: ((Int) -> Void)?
    var cellularAccessAllowingAction: ((Bool) -> Void)?
    var clearButtonAction: (() -> Void)?
    
    override func setup() {
        buildView()
    }
    
    func buildView() {
        let paddingX: CGFloat = 30
        let paddingY: CGFloat = 50
        
        let textField = UITextField(frame: CGRect(x: paddingX, y: paddingY, width: kScreenW - 2*paddingX, height: 44))
        let leftView = UILabel(frame: CGRect(x: 0, y: 0, width: textField.bounds.width - 40, height: textField.bounds.height))
        leftView.text = " 设置下载最大并发数(上限5):"
        leftView.textColor = .white
        textField.leftView = leftView
        textField.leftViewMode = .always
        textField.text = "\(UserDefaults.standard.integer(forKey: CXDownloadConfig.maxConcurrentCountKey))"
        textField.textColor = .yellow
        textField.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        textField.backgroundColor = .lightGray
        textField.textAlignment = .center
        textField.returnKeyType = .done
        textField.keyboardType = .numbersAndPunctuation
        textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        textField.addTarget(self, action: #selector(done), for: .editingDidEndOnExit)
        textField.tag = 10
        textField.layer.cornerRadius = 10
        addSubview(textField)
        
        let cellularAccessLabel = UILabel(frame: CGRect(x: paddingX, y: textField.frame.maxY + 20, width: kScreenW - 2*paddingX, height: 44))
        cellularAccessLabel.text = " 是否允许蜂窝网络下载"
        cellularAccessLabel.textColor = .white
        cellularAccessLabel.textAlignment = .left
        cellularAccessLabel.isUserInteractionEnabled = true
        cellularAccessLabel.backgroundColor = .lightGray
        cellularAccessLabel.layer.masksToBounds = true
        cellularAccessLabel.layer.cornerRadius = 10
        addSubview(cellularAccessLabel)
        
        let cellularAccessSwitch = UISwitch(frame: CGRect(x: cellularAccessLabel.frame.width - 60, y: 6.5, width: 0, height: 0))
        cellularAccessSwitch.isOn = UserDefaults.standard.bool(forKey: CXDownloadConfig.allowsCellularAccessKey)
        cellularAccessSwitch.addTarget(self, action: #selector(cellularAccessSwitchOnClick(_:)), for: .valueChanged)
        cellularAccessLabel.addSubview(cellularAccessSwitch)
        
        let clearButton = UIButton(type: .custom)
        clearButton.frame = CGRect(x: paddingX, y: cellularAccessLabel.frame.maxY + 20, width: kScreenW - 2*paddingX, height: 50)
        clearButton.backgroundColor = .gray
        clearButton.setTitle("清除缓存", for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        clearButton.addTarget(self, action: #selector(clearButtonOnClick), for: .touchUpInside)
        clearButton.layer.cornerRadius = 10
        addSubview(clearButton)
    }
    
    @objc func textFieldEditingChanged(_ textField: UITextField) {
        let textLength = textField.text?.count ?? 0
        if textLength > 1 {
            let substring = String(textField.text!.prefix(1))
            print(":: substring=\(substring)")
            textField.text = substring
        } else if textLength == 1 {
            let characterSet = CharacterSet(charactersIn: "12345").inverted
            let filtered = textField.text!.components(separatedBy: characterSet).joined(separator: "")
            print(":: filtered=\(filtered)")
            if filtered != textField.text {
                textField.text = "1"
                maxConcurrentCountWarningAction?()
            }
        }
    }
    
    @objc func done() {
        guard let textField = viewWithTag(10) as? UITextField else { return }
        updateMaxConcurrentCount(with: textField)
    }
    
    private func updateMaxConcurrentCount(with textField: UITextField) {
        if textField.text == "" { textField.text = "1" }
        
        // The old concurrent count.
        let oldCount = UserDefaults.standard.integer(forKey: CXDownloadConfig.maxConcurrentCountKey)
        
        // The new concurrent count.
        let newCount: Int = Int(textField.text ?? "1") ?? 0
        
        if oldCount != newCount {
            maxConcurrentCountUpdatingAction?(newCount)
        }
    }
    
    @objc func cellularAccessSwitchOnClick(_ aSwitch: UISwitch) {
        cellularAccessAllowingAction?(aSwitch.isOn)
    }
    
    @objc func clearButtonOnClick() {
        clearButtonAction?()
    }
    
}
