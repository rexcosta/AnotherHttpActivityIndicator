# AnotherHttpActivityIndicator

A decorator arround NetworkActivityPortocol.
Can be used to update the UI or UIApplication.shared.isNetworkActivityIndicatorVisible  

 Ex:
 ```swift
 let yourNetwork: NetworkProtocol = YourNetwork()
 let network: NetworkActivityProtocol = AnotherMockHttpClient(..., network: yourNetwork)
 
 network.networkActivityStatus.sink { [weak activityIndicator] value in
     switch value {
     case .running:
         activityIndicator.show()
     
     case .stopped:
         activityIndicator.hide()
     }
 }.store(in: &cancelables)
```
