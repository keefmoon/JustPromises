![](JustPromises_logo.jpg)

A lightweight and thread-safe implementation of Promises & Futures in both Objective-C and Swift 3 for iOS, macOS, watchOS and tvOS.

#Overview

A Promise represents the future value of an asynchronous task. It can be intended as an object that acts as a proxy for a result that is initially unknown, usually because the computation of its value is yet incomplete.

Asynchronous tasks can succeed, fail or be cancelled and the resolution is reflected to the promise object.

Promises are useful to standardize the API of asynchronous operations. They help both to clean up asynchronous code paths and simplify error handling.

##Installing via Cocoapods

To import just the Swift version of JustPromises, in your Podfile:
```
pod 'JustPromises'
```

## Swift 3

Just Promises has been completely re-built from the ground up for Swift 3. [Further details in the Swift specific README](README_Swift.md)

## Objective-C

The legacy Objective-C version is still available. [Further details in the Objective-C specific README](README_ObjC.md)



## Other implementations

These are some third-party libraries mainly used by the community.

- [PromiseKit](http://promisekit.org/)
- [Bolts-iOS](https://github.com/BoltsFramework/Bolts-iOS) (not only promises)
- [RXPromise](https://github.com/couchdeveloper/RXPromise)


## Contributing

We've been adding things ONLY as they are needed, so please feel free to either bring up suggestions or to submit pull requests with new GENERIC functionalities.

Don't bother submitting any breaking changes or anything without unit tests against it. It will be declined.

## Licence

JustPromises is released under the Apache 2.0 License.

- Just Eat iOS team

