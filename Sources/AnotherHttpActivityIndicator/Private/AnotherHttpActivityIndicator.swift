//
// The MIT License (MIT)
//
// Copyright (c) 2020 Effective Like ABoss, David Costa Gonçalves
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import AnotherSwiftCommonLib
import Combine
import Foundation

internal final class AnotherHttpActivityIndicator {
    
    private let network: NetworkProtocol
    private let lock = NSRecursiveLock()
    private var requestsProcessing = Set<UUID>()
    
    @Published
    private var _networkActivityStatus: NetworkActivityStatus = .stopped
    
    public init(network: NetworkProtocol) {
        self.network = network
    }
    
    private func add(request: NetworkRequest) {
        let process = { () -> Bool in
            self.lock.lock();
            self.requestsProcessing.insert(request.uniqueRequestId)
            let isEmpty = self.requestsProcessing.isEmpty
            self.lock.unlock()
            return isEmpty
        }
        
        if process() {
            _networkActivityStatus = .stopped
        } else {
            _networkActivityStatus = .running
        }
    }
    
    private func remove(request: NetworkRequest) {
        
        let process = { () -> Bool in
            self.lock.lock();
            self.requestsProcessing.remove(request.uniqueRequestId)
            let isEmpty = self.requestsProcessing.isEmpty
            self.lock.unlock()
            return isEmpty
        }
        
        if process() {
            _networkActivityStatus = .stopped
        } else {
            _networkActivityStatus = .running
        }
    }
    
}

// MARK: NetworkActivityProtocol
extension AnotherHttpActivityIndicator: NetworkActivityProtocol {
    
    var networkActivityStatus: Published<NetworkActivityStatus>.Publisher {
        return $_networkActivityStatus
    }
    
    public func requestData(request: NetworkRequest) -> AnyPublisher<Data, NetworkError> {
        add(request: request)
        let removeHandler = { [weak self] in
            self?.remove(request: request)
        }
        
        return network
            .requestData(request: request)
            .handleEvents(receiveCompletion: { _ in removeHandler() }, receiveCancel: { removeHandler() })
            .eraseToAnyPublisher()
    }
    
    public func requestJsonObject(request: NetworkRequest) -> AnyPublisher<[String: Any], NetworkError> {
        add(request: request)
        let removeHandler = { [weak self] in
            self?.remove(request: request)
        }
        
        return network
            .requestJsonObject(request: request)
            .handleEvents(receiveCompletion: { _ in removeHandler() }, receiveCancel: { removeHandler() })
            .eraseToAnyPublisher()
    }
    
    public func requestJsonArray(request: NetworkRequest) -> AnyPublisher<[Any], NetworkError> {
        add(request: request)
        let removeHandler = { [weak self] in
            self?.remove(request: request)
        }
        
        return network
            .requestJsonArray(request: request)
            .handleEvents(receiveCompletion: { _ in removeHandler() }, receiveCancel: { removeHandler() })
            .eraseToAnyPublisher()
    }
    
    public func requestDecodable<T: Decodable>(request: NetworkRequest) -> AnyPublisher<T, NetworkError> {
        add(request: request)
        let removeHandler = { [weak self] in
            self?.remove(request: request)
        }
        
        return network
            .requestDecodable(request: request)
            .handleEvents(receiveCompletion: { _ in removeHandler() }, receiveCancel: { removeHandler() })
            .eraseToAnyPublisher()
    }
    
}
