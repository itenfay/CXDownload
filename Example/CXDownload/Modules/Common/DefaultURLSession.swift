//
//  DefaultURLSession.swift
//  CXDownload_Example
//
//  Created by Tenfay on 2023/7/7.
//  Copyright © 2023 Tenfay. All rights reserved.
//

import Foundation

class DefaultURLSession: NSObject, URLSessionProtocol {
    
    typealias URLSessionCompletionHandler = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void
    
    private var urlSessionConfiguration: URLSessionConfiguration!
    private var urlSession: URLSession!
    private var dataTask: URLSessionDataTask?
    private var queue: OperationQueue!
    private var _completionHandler: URLSessionCompletionHandler?
    private var urlResponse: URLResponse?
    private var recvData: Data?
    
    init(urlSessionConfiguration: URLSessionConfiguration, queue: OperationQueue) {
        self.urlSessionConfiguration = urlSessionConfiguration
        self.queue = queue
        super.init()
        self.initializeURLSession()
        self.updataMaxConcurrentCount(5)
    }
    
    convenience override init() {
        self.init(urlSessionConfiguration: .default, queue: OperationQueue())
    }
    
    private func initializeURLSession() {
        urlSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: queue)
    }
    
    func updataMaxConcurrentCount(_ count: Int) {
        queue.maxConcurrentOperationCount = count
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        _completionHandler = completionHandler
        dataTask = urlSession.dataTask(with: request)
        return dataTask!
    }
    
}

extension DefaultURLSession: URLSessionDataDelegate {
    
    //func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    //    completionHandler(.useCredential, nil)
    //}
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        urlResponse = response
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        recvData = data
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            _completionHandler?(nil, nil, error)
            return
        }
        _completionHandler?(recvData, urlResponse, nil)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        _completionHandler?(nil, nil, error)
    }
    
}
