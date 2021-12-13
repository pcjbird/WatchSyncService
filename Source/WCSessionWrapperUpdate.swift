//
//  File.swift
//  AlexWatch
//
//  Created by Anton Belousov on 10/01/2019.
//  Copyright © 2019 kp. All rights reserved.
//

import Foundation
import WatchConnectivity

public class WCSessionWrapperUsingMessage: NSObject, IConnectivityService {
    var session: WCSession?
    var onReceiveHandler: (ISyncItem) -> () = {_ in }
    var onReachabilityChangeHandler:() -> () = {}
    var onCompanionAppInstalledChangeHandler:() -> () = {}
    public var parser: IApplicationContextParser!
    
    public func run() {
        if session?.activationState == .activated {
            return
        }
        if WCSession.isSupported() { //makes sure it's not an iPad or iPod
            let watchSession = WCSession.default
            watchSession.delegate = self
            watchSession.activate()
            #if os(iOS)
            if watchSession.isPaired && watchSession.isWatchAppInstalled {
                session = watchSession
            }
            #else
            session = watchSession
            #endif
        }
    }
    
    public func send(item: ISyncItem) {
        run()
        guard let session = self.session else {
            print(self, #function, #line, "there is no session")
            return
        }
        session.sendMessage(parser.encodeConextFrom(item), replyHandler: nil, errorHandler: nil)
    }
    
    public func onReceive(handler: @escaping (ISyncItem) -> ()) {
        onReceiveHandler = handler
    }
    
    public func onReachabilityChanged(handler: @escaping () -> ()) {
        onReachabilityChangeHandler = handler
    }
    
    public func onCompanionAppInstalledChanged(handler: @escaping () -> ()) {
        onCompanionAppInstalledChangeHandler = handler
    }
}

extension WCSessionWrapperUsingMessage: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        var errorMessage = ""
        if let error = error {
            errorMessage = ", error:\(error)"
        }
        print(self, #function, #line, "session activation did complete with state: \(activationState)\(errorMessage)")
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let item = parser.decodeItemFrom(applicationContext) {
            onReceiveHandler(item)
        }
    }
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let item = parser.decodeItemFrom(message) {
            onReceiveHandler(item)
        }
    }
    
    public func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        print(self, #function, #line, "sessionCompanionAppInstalledDidChange: \(session.isCompanionAppInstalled)")
        onCompanionAppInstalledChangeHandler()
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        print(self, #function, #line, "sessionReachabilityDidChange: \(session.isReachable)")
        onReachabilityChangeHandler()
    }
}
