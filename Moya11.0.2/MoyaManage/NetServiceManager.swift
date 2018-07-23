//
//  NetServiceManager.swift
//  NN110
//
//  Created by 陈亦海 on 2017/5/12.
//  Copyright © 2017年 陈亦海. All rights reserved.
//

import Foundation
import Moya
import Alamofire
import ReactiveSwift



// MARK: - Provider setup系统方法转换json数据

private func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data // fallback to original data if it can't be serialized.
    }
}

private func JSONResponseFormatter(_ data: Data) -> Dictionary<String, Any>? {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
       
        return dataAsJSON as? Dictionary<String, Any>
    } catch {
        return nil // fallback to original data if it can't be serialized.
    }
}

// MARK: - 默认的网络提示请求插件
let spinerPlugin = NetworkActivityPlugin { (state,target) in
    if state == .began {
        print("我开始请求")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    } else {
        
        print("我结束请求")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
    }
}

// MARK: - 自定义的网络提示请求插件
let myNetworkPlugin = MyNetworkActivityPlugin { (state,target) in
    
    let api = target as! NetAPIManager
    
    if state == .began {
        //        SwiftSpinner.show("Connecting...")
        
        
        
        if api.show {
            print("我可以在这里写加载提示")
            if !api.touch {
                print("我可以在这里写禁止用户操作，等待请求结束")
            }
//            SVPHUDTool.showHUD(api.touch,api.title)
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    } else {
        //        SwiftSpinner.show("request finish...")
        //        SwiftSpinner.hide()
        
        if api.show {
//           SVPHUDTool.dismiss()
        }
        
        print("我结束请求")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
    }
}




// MARK: - 设置请求头部信息
let myEndpointClosure = { (target: NetAPIManager) -> Endpoint in
    
    let sessionId =  ""
    let url = target.baseURL.appendingPathComponent(target.path).absoluteString
    
    let endpoint = Endpoint.init(url: url, sampleResponseClosure:  { .networkResponse(200, target.sampleData) }, method: target.method, task: target.task, httpHeaderFields: target.headers)

    return endpoint.adding(newHTTPHeaderFields: [
        "Content-Type" : "application/x-www-form-urlencoded",
        "COOKIE" : "JSESSIONID=\(sessionId)",
        "Accept": "application/json;application/octet-stream;text/html,text/json;text/plain;text/javascript;text/xml;application/x-www-form-urlencoded;image/png;image/jpeg;image/jpg;image/gif;image/bmp;image/*"
        ])
    
}

// MARK: - 设置请求头部信息
var endpointClosure = { (target: NetAPIManager) -> Endpoint in
    let sessionId =  ""
    let url = target.baseURL.appendingPathComponent(target.path).absoluteString
    var endpoint: Endpoint = Endpoint(
        url: url,
        sampleResponseClosure: {.networkResponse(200, target.sampleData)},
        method: target.method,
        task: target.task,
        httpHeaderFields: target.headers
    )
    return endpoint.adding(newHTTPHeaderFields: [
        "Content-Type" : "application/x-www-form-urlencoded",
        "COOKIE" : "JSESSIONID=\(sessionId)",
        "Accept": "application/json;application/octet-stream;text/html,text/json;text/plain;text/javascript;text/xml;application/x-www-form-urlencoded;image/png;image/jpeg;image/jpg;image/gif;image/bmp;image/*"
        ])

}

// MARK: - 设置请求超时时间
let requestClosure = { (endpoint: Endpoint, done: @escaping MoyaProvider<NetAPIManager>.RequestResultClosure) in
    
//    guard var request = endpoint.urlRequest else { return }
//    request.timeoutInterval = 30    //设置请求超时时间
//    done(.success(request))
    do {
        var request: URLRequest = try endpoint.urlRequest()
        request.timeoutInterval = 30    //设置请求超时时间
        done(.success(request))
    } catch  {
        print("错误了 \(error)")
    }
    
    
}

// MARK: - 设置请求超时时间
//let RxRequestClosure = { (endpoint: Endpoint<NetAPIManager>, done: @escaping ReactiveSwiftMoyaProvider<NetAPIManager>.RequestResultClosure) in
//
//    guard var request = endpoint.urlRequest else { return }
//
//    request.timeoutInterval = 40    //设置请求超时时间
//    done(.success(request))
//}

/// 关闭https认证

let serverTrustPolicies: [String: ServerTrustPolicy] = [

      "172.16.88.106": .pinCertificates(certificates: ServerTrustPolicy.certificates(), validateCertificateChain: true, validateHost: true),
      "insecure.expired-apis.com": .disableEvaluation

]

//performDefaultEvaluation：使用默认的server trust评估，允许我们控制是否验证challenge提供的host。
//pinCertificates：使用pinned certificates来验证server trust。如果pinned certificates匹配其中一个服务器证书，那么认为server trust是有效的。
//pinPublicKeys：使用pinned public keys来验证server trust。如果pinned public keys匹配其中一个服务器证书公钥，那么认为server trust是有效的。
//disableEvaluation：禁用所有评估，总是认为server trust是有效的。
//customEvaluation：使用相关的闭包来评估server trust的有效性，我们可以完全控制整个验证过程。但是要谨慎使用。

let configuration: URLSessionConfiguration = {
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
    return configuration

}()

let delegate: SessionDelegate = {
    let delegate = SessionDelegate()
    delegate.sessionDidReceiveChallenge = { session, challenge in
        //认证服务器证书
        if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodServerTrust {
            print("服务端证书认证！")
            let serverTrust:SecTrust = challenge.protectionSpace.serverTrust!
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)!
            let remoteCertificateData
                = CFBridgingRetain(SecCertificateCopyData(certificate))!
            let cerPath = Bundle.main.path(forResource: "tomcat", ofType: "cer")!
            let cerUrl = URL(fileURLWithPath:cerPath)
            let localCertificateData = try! Data(contentsOf: cerUrl)
            
            if (remoteCertificateData.isEqual(localCertificateData) == true) {
                
                let credential = URLCredential(trust: serverTrust)
                challenge.sender?.use(credential, for: challenge)
                return (URLSession.AuthChallengeDisposition.useCredential,
                        URLCredential(trust: challenge.protectionSpace.serverTrust!))
                
            } else {
                return (.cancelAuthenticationChallenge, nil)
            }
        }
            //认证客户端证书
        else if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodClientCertificate {
            print("客户端证书认证！")
            //获取客户端证书相关信息
            let identityAndTrust:IdentityAndTrust = extractIdentity();
            
            let urlCredential:URLCredential = URLCredential(
                identity: identityAndTrust.identityRef,
                certificates: identityAndTrust.certArray as? [AnyObject],
                persistence: URLCredential.Persistence.forSession);
            
            return (.useCredential, urlCredential);
        }
            // 其它情况（不接受认证）
        else {
            print("其它情况（不接受认证）")
            return (.cancelAuthenticationChallenge, nil)
        }
    }
    
    return delegate

}()

let myManager = Manager(
    
    configuration: configuration,
    delegate:delegate,
    serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)

//    let configuration = URLSessionConfiguration.default
//    configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
//
//    let manager = Manager(configuration: configuration)
//    manager.startRequestsImmediately = false
//    return manager

)



let provider = MoyaProvider<NetAPIManager>(requestClosure: requestClosure,                manager:myManager)

let MyAPIProvider = MoyaProvider<NetAPIManager>(endpointClosure: myEndpointClosure,requestClosure: requestClosure, plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter),myNetworkPlugin])

//let RxAPIProvider = RsAPIProvider<NetAPIManager>(endpointClosure: endpointClosure,requestClosure: requestClosure, plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter),myNetworkPlugin])

//let RsAPIProvider = ReactiveSwiftMoyaProvider<NetAPIManager>(endpointClosure: myEndpointClosure,requestClosure: requestClosure,stubClosure: MoyaProvider.immediatelyStub, plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter),myNetworkPlugin])


// MARK: -取消所有请求
func cancelAllRequest() {
//    MyAPIProvider.manager.session.invalidateAndCancel()  //取消所有请求
    MyAPIProvider.manager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
        dataTasks.forEach { $0.cancel() }
        uploadTasks.forEach { $0.cancel() }
        downloadTasks.forEach { $0.cancel() }
    }
    
    //let sessionManager = Alamofire.SessionManager.default
    //sessionManager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
    //    dataTasks.forEach { $0.cancel() }
    //    uploadTasks.forEach { $0.cancel() }
    //    downloadTasks.forEach { $0.cancel() }
    //}

    
   
}



func blockHander(theBlock:@escaping (String)->()) {
    theBlock("myBlock")
}

// MARK: -创建一个Moya请求
public func sendMyRequest(_ name: String, touch:Bool? = true, show: Bool? = true, titleString: String? = nil, postDict: Dictionary<String, Any>? = nil,
                 success:@escaping (Dictionary<String, Any>?)->(),
                 failure:@escaping (MoyaError)->()) -> Cancellable? {
    
    let request = MyAPIProvider.request(.request(APIName:name,isTouch: touch!, body:postDict ,isShow: show!, title: titleString)) { result in
    
//        do {
//            let response = try result.dematerialize()
////            let value = try response.mapNSArray()
////            print("maya 原生 \(value)")
//            
//            
//            
//        } catch {
//            
//            
//        }
    

    
        switch result {
        case let .success(moyaResponse):
            
            
//            do {
//                let any = try moyaResponse.mapJSON()
//                let string = try moyaResponse.mapString()
                let data =  moyaResponse.data
                let statusCode =  moyaResponse.statusCode
                print("MyAPIProvider ： \(data) ---  ----- \(statusCode)")
                
                guard !data.isEmpty else{
//                     MyDDLog("data数据为空 ")
                    success(nil)
                    return
                }
                
//                let dict =  APIMessage.gzipBase64Data(withAny: data)
                let dict = JSONResponseFormatter(data)
                print("解密后的数据 ：\(dict ?? [:]) ")
                success((dict))
                

//            } catch {
//
//                MyDDLog(error)
//            }
            
           
            
        case let .failure(error):
            
            print(error)
            failure(error)
        }
    }
    
    return request
}

// MARK: -创建一个Moya请求
public func sendPostMyRequest(_ name: String, touch:Bool? = true, show: Bool? = true, titleString: String? = nil, postDict: Dictionary<String, Any>? = nil,
                          success:@escaping (Dictionary<String, Any>?)->(),
                          failure:@escaping (MoyaError)->()) -> Cancellable? {
    
    let request = MyAPIProvider.request(.postRequest(APIName:name,isTouch: touch!, body:postDict ,isShow: show!, title: titleString)) { result in
        
        //        do {
        //            let response = try result.dematerialize()
        ////            let value = try response.mapNSArray()
        ////            print("maya 原生 \(value)")
        //
        //
        //
        //        } catch {
        //
        //
        //        }
        
        
        
        switch result {
        case let .success(moyaResponse):
            
            
     
            
            let data =  moyaResponse.data
            let statusCode =  moyaResponse.statusCode
//            MyDDLog("MyAPIProvider ： \(data) ---  ----- \(statusCode)")
            
            let response  = moyaResponse.response
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: response?.allHeaderFields as! [String : String], for: (response?.url)!)
            print("response cookies: \(cookies) ")
            
            guard !data.isEmpty else{
//                MyDDLog("data数据为空 ")
                success(nil)
                return
            }
            
            guard statusCode == 200 else{
//                MyDDLog("非200 错误返回来 ")
                success(nil)
                return
            }
            
            let dict =  JSONResponseFormatter(data)
            print("解密后的数据 ：\(dict ?? [:]) ")
            success(dict)
            
            
         
            
            
            
        case let .failure(error):
            
            print(error)
            failure(error)
        }
    }
    
    return request
}

// MARK: -创建一个ReactiveSwiftMoyaProvider请求
func sendReactiveSwiftRequest(_ name: String, touch:Bool? = true, show: Bool? = true, titleString: String? = nil, postDict: Dictionary<String, Any>? = nil,
                              success:@escaping (Dictionary<String, Any>)->(),
                              failure:@escaping (MoyaError)->()) -> Disposable? {

    let request = MyAPIProvider.reactive.request(.postRequest(APIName:name,isTouch: touch!, body:postDict ,isShow: show!, title: titleString)).start { event in
        switch event {
        case let .value(response):
             do {
                let any = try response.mapJSON()
                let string = try response.mapString()

                print("ReactiveSwift  : \(any) --- \(string)")
                
                success(any as! Dictionary<String, Any>)
             }
             catch {

            }

        case let .failed(error):
            print(error)
            failure(error)
        default:
            break
        }
    }

//    request.dispose()   释放信号

    return request
}


// MARK: -创建一个RxSwiftMoyaProvider请求
func sendRxSwiftRequest(_ name: String, touch:Bool? = true, show: Bool? = true, titleString: String? = nil, postDict: Dictionary<String, Any>? = nil,
                              success:@escaping (Dictionary<String, Any>)->(),
                              failure:@escaping (MoyaError)->()) -> Disposable? {




    let request = MyAPIProvider.rx.request(.postRequest(APIName:name,isTouch: touch!, body:postDict ,isShow: show!, title: titleString)).subscribe { event in
        switch event {
        case let .success(response):

            do {
                let any = try response.mapJSON()
                let string = try response.mapString()

                print("RxSwift  : \(any) --- \(string)")
                
                success(any as! Dictionary<String, Any> )
            }
            catch {
                 print("错误了")
            }

        case let .error(error):
            print(error)
            
            failure(error as! MoyaError)
        
        }
    }


    return request as? Disposable
}

// MARK: -Alamofire原生用法
func sendAlamofireRequest(){
        //POST request
    let postsEndpoint: String = "http://ny.gx10010.com/mobile-service/mapp/json_in_plain.do"
    let jsonDic = ["msg":"{\"@class\":\"com.ailk.gx.mapp.model.GXCDatapackage\",\"header\":{\"@class\":\"com.ailk.gx.mapp.model.GXCHeader\",\"bizCode\":\"cg0004\",\"identityId\":null,\"respCode\":null,\"respMsg\":null,\"mode\":\"1\",\"sign\":null},\"body\":{\n  \"expand\" : null,\n  \"@class\" : \"com.ailk.gx.mapp.model.req.CG0004Request\",\n  \"phoneNo\" : \"13213451345\"\n}}"]
    Alamofire.request(postsEndpoint, method: .post, parameters: jsonDic, encoding: URLEncoding.default,headers:[
        "Content-Type" : "application/x-www-form-urlencoded",
        "COOKIE" : "",
        "Accept": "application/json;application/octet-stream;text/html,text/json;text/plain;text/javascript;text/xml;application/x-www-form-urlencoded;image/png;image/jpeg;image/jpg;image/gif;image/bmp;image/*"
        ]).responseJSON { response in
            //do something with response

            print("Alamofire 原生 \(response)")
        }.responseString { (responseString) in
             print("Alamofire 原生 \(responseString)")
    }
}


func configureAlamofireManager() {
    let manager = Manager.default
    manager.delegate.sessionDidReceiveChallenge = { session, challenge in
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            disposition = URLSession.AuthChallengeDisposition.useCredential
            credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        } else {
            if challenge.previousFailureCount > 0 {
                disposition = .cancelAuthenticationChallenge
            } else {
                credential = manager.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                
                if credential != nil {
                    disposition = .useCredential
                }
            }
        }
        return (disposition, credential)
    }
}

//客户端,服务端证书双向认证
func twoAlamofireManager() {
    //认证相关设置
    let manager = SessionManager.default
    manager.delegate.sessionDidReceiveChallenge = { session, challenge in
        //认证服务器证书
        if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodServerTrust {
            print("服务端证书认证！")
            let serverTrust:SecTrust = challenge.protectionSpace.serverTrust!
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)!
            let remoteCertificateData
                = CFBridgingRetain(SecCertificateCopyData(certificate))!
            let cerPath = Bundle.main.path(forResource: "tomcat", ofType: "cer")!
            let cerUrl = URL(fileURLWithPath:cerPath)
            let localCertificateData = try! Data(contentsOf: cerUrl)
            
            if (remoteCertificateData.isEqual(localCertificateData) == true) {
                
                let credential = URLCredential(trust: serverTrust)
                challenge.sender?.use(credential, for: challenge)
                return (URLSession.AuthChallengeDisposition.useCredential,
                        URLCredential(trust: challenge.protectionSpace.serverTrust!))
                
            } else {
                return (.cancelAuthenticationChallenge, nil)
            }
        }
            //认证客户端证书
        else if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodClientCertificate {
            print("客户端证书认证！")
            //获取客户端证书相关信息
            let identityAndTrust:IdentityAndTrust = extractIdentity();
            
            let urlCredential:URLCredential = URLCredential(
                identity: identityAndTrust.identityRef,
                certificates: identityAndTrust.certArray as? [AnyObject],
                persistence: URLCredential.Persistence.forSession);
            
            return (.useCredential, urlCredential);
        }
            // 其它情况（不接受认证）
        else {
            print("其它情况（不接受认证）")
            return (.cancelAuthenticationChallenge, nil)
        }
    }
    
   
}

//客户端证书单向认证
func alamofireManager() {
     //自签名网站地址
    let selfSignedHosts = ["192.168.1.112", "www.hangge.com"]
    //认证相关设置
    let manager = SessionManager.default
    manager.delegate.sessionDidReceiveChallenge = { session, challenge in
        //认证服务器（这里不使用服务器证书认证，只需地址是我们定义的几个地址即可信任）
        if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodServerTrust
            && selfSignedHosts.contains(challenge.protectionSpace.host) {
            print("服务器认证！")
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            return (.useCredential, credential)
        }
            //认证客户端证书
        else if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodClientCertificate {
            print("客户端证书认证！")
            //获取客户端证书相关信息
            let identityAndTrust:IdentityAndTrust = extractIdentity();
            
            let urlCredential:URLCredential = URLCredential(
                identity: identityAndTrust.identityRef,
                certificates: identityAndTrust.certArray as? [AnyObject],
                persistence: URLCredential.Persistence.forSession);
            
            return (.useCredential, urlCredential);
        }
            // 其它情况（不接受认证）
        else {
            print("其它情况（不接受认证）")
            return (.cancelAuthenticationChallenge, nil)
        }
    }
    
    
}

//获取客户端证书相关信息
func extractIdentity() -> IdentityAndTrust {
    var identityAndTrust:IdentityAndTrust!
    var securityError:OSStatus = errSecSuccess
    
    let path: String = Bundle.main.path(forResource: "mykey", ofType: "p12")!
    let PKCS12Data = NSData(contentsOfFile:path)!
    let key : NSString = kSecImportExportPassphrase as NSString
    let options : NSDictionary = [key : "123456"] //客户端证书密码
    //create variable for holding security information
    //var privateKeyRef: SecKeyRef? = nil
    
    var items : CFArray?
    
    securityError = SecPKCS12Import(PKCS12Data, options, &items)
    
    if securityError == errSecSuccess {
        let certItems:CFArray = (items as CFArray?)!;
        let certItemsArray:Array = certItems as Array
        let dict:AnyObject? = certItemsArray.first;
        if let certEntry:Dictionary = dict as? Dictionary<String, AnyObject> {
            // grab the identity
            let identityPointer:AnyObject? = certEntry["identity"];
            let secIdentityRef:SecIdentity = (identityPointer as! SecIdentity?)!
            print("\(String(describing: identityPointer))  :::: \(secIdentityRef)")
            // grab the trust
            let trustPointer:AnyObject? = certEntry["trust"]
            let trustRef:SecTrust = trustPointer as! SecTrust
            print("\(String(describing: trustPointer))  :::: \(trustRef)")
            // grab the cert
            let chainPointer:AnyObject? = certEntry["chain"]
            identityAndTrust = IdentityAndTrust(identityRef: secIdentityRef,
                                                trust: trustRef, certArray:  chainPointer!)
        }
    }
    return identityAndTrust;
}

//定义一个结构体，存储认证相关信息
struct IdentityAndTrust {
    var identityRef:SecIdentity
    var trust:SecTrust
    var certArray:AnyObject
}
