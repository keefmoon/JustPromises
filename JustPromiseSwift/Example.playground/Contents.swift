//: Playground - noun: a place where people can play

import Foundation
import PlaygroundSupport
import JustPromiseSwift

PlaygroundPage.current.needsIndefiniteExecution = true

let session = URLSession(configuration: .default)

// MARK: Request Builder Methods

let foursquareBaseURL = "https://api.foursquare.com/v2/"
let foursquareApiClientId = "ED233ZBBNC2IF4VHMAKE1CTARX44OJOGKRTAW34ISQLPT0HE"
let foursquareApiClientSecret = "OYPK3LZEXLSDQE1IG4RM5JXBX1D54W0PUCXFJL4CHLCIKU4H"

// MARK: Request Builder

func createFoursquareRequest(withQuery query: String) -> URLRequest {
    
    let urlString = "\(foursquareBaseURL)/venues/search?client_id=\(foursquareApiClientId)&client_secret=\(foursquareApiClientSecret)&v=20130815&ll=40.7,-74&query=\(query)"
    
    let url = URL(string: urlString)!
    return URLRequest(url: url)
}

// MARK: Example of Wrapping Async APIs

enum DownloadError: Error {
    case noResponseData
}

func downloadJSON(with request: URLRequest) -> Promise<Data> {
    
    return Promise<Data> { promise in
        
        let fetchDataTask = session.dataTask(with: request) { (data, response, error) in
            
            print("Before: \(promise): State: \(promise.futureState)")
            
            switch (data, error) {
                
            case (let data?, _):
                promise.futureState = .result(data)
                
            case (nil, let error?):
                promise.futureState = .error(error)
                
            case (nil, nil):
                promise.futureState = .error(DownloadError.noResponseData)
            }
            
            print("After: \(promise): State: \(promise.futureState)")
        }
        fetchDataTask.resume()
    }
}

enum ParseError: Error {
    case dataNotAJSONObject
}

func parseJSONDataToDictionary(from downloadPromise: Promise<Data>) -> Promise<[String: AnyObject]> {
    
    return Promise<[String: AnyObject]> { promise in
        
        switch downloadPromise.futureState {
            
        case .unresolved:
            return promise.futureState = .unresolved
            
        case .cancelled:
            return promise.futureState = .cancelled
            
        case .error(let error):
            return promise.futureState = .error(error)
            
        case .result(let downloadedData):
            
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: downloadedData, options: []) as? [String: AnyObject] {
                    promise.futureState = .result(parsedJSON)
                } else {
                    promise.futureState = .error(ParseError.dataNotAJSONObject)
                }
            } catch {
                promise.futureState = .error(error)
            }
        }
    }
}

// MARK: Use Promises to Search for restaurants

let request = createFoursquareRequest(withQuery: "sushi")

downloadJSON(with: request).await().continuation { downloadPromise -> Promise<[String:AnyObject]> in
    
    return parseJSONDataToDictionary(from: downloadPromise)

}.continuationOnMainQueue { parsedPromise in
    
    guard let restaurantInfo = parsedPromise.futureState.result else {
        print("There was a problem getting the information")
        return
    }
    
    print("Result: \(restaurantInfo)")
    PlaygroundPage.current.finishExecution()
}
