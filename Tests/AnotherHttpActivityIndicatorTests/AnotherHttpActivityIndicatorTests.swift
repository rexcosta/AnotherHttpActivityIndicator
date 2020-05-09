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
import XCTest
@testable import AnotherHttpActivityIndicator

final class AnotherHttpActivityIndicatorTests: XCTestCase {
    
    func testOneRequest() {
        let fakeNet = EmptyNetwork()
        let network = AnotherHttpActivityIndicator(network: fakeNet)
        
        let request = NetworkRequest(
            timeout: 3,
            url: "www.example.com"
        )
        
        let expectation = XCTestExpectation(description: "Expectation for \(request.timeout)")
        var cancelables = Set<AnyCancellable>()
        
        var path = [NetworkActivityStatus]()
        
        network.networkActivityStatus.sink { value in
            path.append(value)
        }.store(in: &cancelables)
        
        network
            .requestData(request: request)
            .sinkToResult { result in
                switch result {
                case .success(_):
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
        }.store(in: &cancelables)
        
        wait(for: [expectation], timeout: 10.0)
        
        let expectedPath: [NetworkActivityStatus] = [.stopped, .running, .stopped]
        XCTAssertEqual(path, expectedPath)
    }
    
    func testTwoRequests() {
        let fakeNet = EmptyNetwork()
        let network = AnotherHttpActivityIndicator(network: fakeNet)
        
        let request1 = NetworkRequest(
            timeout: 3,
            url: "www.example.com"
        )
        
        let request2 = NetworkRequest(
            timeout: 5,
            url: "www.example.com"
        )
        
        let expectationRequest1 = XCTestExpectation(description: "Expectation for \(request1.timeout)")
        let expectationRequest2 = XCTestExpectation(description: "Expectation for \(request2.timeout)")
        var cancelables = Set<AnyCancellable>()
        
        var path = [NetworkActivityStatus]()
        
        network.networkActivityStatus.sink { value in
            path.append(value)
        }.store(in: &cancelables)
        
        network
            .requestData(request: request1)
            .sinkToResult { result in
                switch result {
                case .success(_):
                    expectationRequest1.fulfill()
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
        }.store(in: &cancelables)
        
        network
            .requestData(request: request2)
            .sinkToResult { result in
                switch result {
                case .success(_):
                    expectationRequest2.fulfill()
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
        }.store(in: &cancelables)
        
        wait(for: [expectationRequest1, expectationRequest2], timeout: 10.0)
        
        let expectedPath: [NetworkActivityStatus] = [
            .stopped, // Initial State
            .running, // First task start running
            .running, // Second task start running
            .running, // First task finish running, first will end first because we have a 3s
            .stopped  // Second task finish running
        ]
        XCTAssertEqual(path, expectedPath)
    }
    
    func testMultipleRequests() {
        let fakeNet = EmptyNetwork()
        let network = AnotherHttpActivityIndicator(network: fakeNet)
        
        let requests: [NetworkRequest] = [
            NetworkRequest(timeout: 4, url: "www.example.com"),
            NetworkRequest(timeout: 6, url: "www.example.com"),
            NetworkRequest(timeout: 2, url: "www.example.com"),
            NetworkRequest(timeout: 8, url: "www.example.com")
        ]
        
        var cancelables = Set<AnyCancellable>()
        var path = [NetworkActivityStatus]()
        
        network.networkActivityStatus.sink { value in
            path.append(value)
        }.store(in: &cancelables)
        
        let expectations = requests.map { request -> XCTestExpectation in
            
            let expectation = XCTestExpectation(description: "Expectation for \(request.timeout)")
            network
                .requestData(request: request)
                .sinkToResult { result in
                    switch result {
                    case .success(_):
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
            }.store(in: &cancelables)
            
            return expectation
        }
        
        wait(for: expectations, timeout: 20.0)
        
        let expectedPath: [NetworkActivityStatus] = [
            .stopped, // Initial State
            .running, // First task start running
            .running, // Second task start running
            .running, // Third task start running
            .running, // Forth task start running
            .running, // Third task finish running - 2s
            .running, // First task start running - 4s
            .running, // Second task start running - 6s
            .stopped  // Forth task  finish running - 8s
        ]
        XCTAssertEqual(path, expectedPath)
    }

    static var allTests = [
        ("testOneRequest", testOneRequest),
        ("testTwoRequests", testTwoRequests),
        ("testMultipleRequests", testMultipleRequests),
    ]
    
}
