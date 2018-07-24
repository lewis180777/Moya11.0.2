####Moya简介

**Moya** 是你的 app 中缺失的网络层。不用再去想在哪儿（或者如何）安放网络请求，Moya 替你管理。

**Moya**有几个比较好的特性:

* 编译时检查正确的API端点访问.

* 使你定义不同端点枚举值对应相应的用途更加明晰.

* 提高测试地位从而使单元测试更加容易.

Swift我们用**Alamofire**来做网络库.而[Moya](https://github.com/Moya/Moya)在Alamofire的基础上又封装了一层,如下流程图说明**Moya**的简单工作流程图:
![简单流程图](http://upload-images.jianshu.io/upload_images/49368-4bf918cee5f14d1f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

** Moya**的官方下载地址[点我强大的Moya](https://github.com/Moya/Moya),有具体的使用方法在demo里面有说明。

本文主要介绍一下**Moya**的用法
* 设置请求头部信息
* 设置超时时间
* 自定义插件
* 自签名证书

注意：以下所出现的**NetAPIManager**跟官网上demo的** GitHub**是一样类型的文件，都是这个enum实现一个协议TargetType，点进去可以看到TargetType定义了我们发送一个网络请求所需要的东西，什么baseURL，parameter，method等一些计算性属性，我们要做的就是去实现这些东西，当然有带默认值的我们可以不去实现，但是设置头部信息跟超时时间就要修改这些系统默认设置了。

为了看得更加清楚，贴上**NetAPIManager**文件的内容
```
//
//  NetAPIManager.swift
//  NN110
//
//  Created by 陈亦海 on 2017/5/12.
//  Copyright © 2017年 陈亦海. All rights reserved.
//

import Foundation
import Moya


enum NetAPIManager {
case Show
case upload(bodyData: Data)
case download
case request(isTouch: Bool, body: Dictionary<String, Any>? ,isShow: Bool)
}


extension NetAPIManager: TargetType {
var baseURL: URL {//服务器地址

switch self {
case .request( _, _, _):
return URL(string: "https://www.pmphmall.com")!
default:
return URL(string: "https://httpbin.org")!
}


}

var path: String {//具体某个方法的路径
switch self {
case .Show:
return ""
case .upload(_):
return ""
case .request(_, _, _):
return "/app/json.do"
case .download:
return ""
}
}

var method: Moya.Method {//请求的方法 get或者post之类的
switch self {
case .Show:
return .get
case .request(_, _, _):
return .post
default:
return .post
}
}

var parameters: [String: Any]? {//请求的get post给服务器的参数
switch self {
case .Show:
return nil
case .request(_, _, _):
return ["msg":"H4sIAAAAAAAAA11SSZJFIQi7EqPAEgTvf6TP62W7sMoSQhKSWDrs6ZUKVWogLwYV7RjHFBZJlNlzloN6LVqID4a+puxqRdUKVNLwE1TRcZIC/fjF2rPotuXmb84r1gMXbiASZIZbhQdKEewJlz41znDkujCHuQU3dU7G4/PmVRnwArMLXukBv0J23XVahNO3VX35wlgce6TLUzzgPQJFuHngAczl6VhaNXpmRLxJBlMml6gdLWiXxTdO7I+iEyC7XuTirCQXOk4dotgArgkH/InxVjfNTnE/uY46++hyAiLFuFL4cv1Z8WH5DgB2GnvFXMh5gm53Tr13vqqrEYtcdXfkNsMwKB+9sAQ77grNJmquFWOhfXA/DELlMB0KKFtHOc/ronj1ml+Z7qas82L3VWiCVQ+HEitjTVzoFw8RisFN/jJxBY4awvq427McXqnyrfCsl7oeEU6wYgW9yJtj1lOkx0ELL5Fw4z071NaVzRA9ebxWXkFyothgbB445cpRmTC+//F73r1kOyQ3lTpec12XNDR00nnq5/YmJItW3+w1z27lSOLqgVctrxG4xdL9WVPdkH1tkiZ/pUKBGhADAAA="]
default:
return nil

}
}

var sampleData: Data { //编码转义
return "{}".data(using: String.Encoding.utf8)!
}

var task: Task { //一个请求任务事件

switch self {


case let .upload(data):
return .upload(.multipart([MultipartFormData(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")]))

default:
return .request

}

}

var parameterEncoding: ParameterEncoding {//编码的格式
switch self {
case .request(_, _, _):
return URLEncoding.default
default:
return URLEncoding.default
}

}
//以下两个参数是我自己写，用来控制网络加载的时候是否允许操作，跟是否要显示加载提示，这两个参数在自定义插件的时候会用到
var touch: Bool { //是否可以操作

switch self {
case .request(let isTouch, _, _):
return isTouch
default:
return false
}

}

var show: Bool { //是否显示转圈提示

switch self {
case .request( _, _,let isShow):
return isShow
default:
return false
}

}


}

```

##如何设置**Moya**请求头部信息
头部信息的设置在开发过程中很重要，如服务器生成的token，用户唯一标识等
我们直接上代码，不说那么多理论的东西，哈哈

```
// MARK: - 设置请求头部信息
let myEndpointClosure = { (target: NetAPIManager) -> Endpoint<NetAPIManager> in


let url = target.baseURL.appendingPathComponent(target.path).absoluteString
let endpoint = Endpoint<NetAPIManager>(
url: url,
sampleResponseClosure: { .networkResponse(200, target.sampleData) },
method: target.method,
parameters: target.parameters,
parameterEncoding: target.parameterEncoding
)

//在这里设置你的HTTP头部信息
return endpoint.adding(newHTTPHeaderFields: [
"Content-Type" : "application/x-www-form-urlencoded",
"ECP-COOKIE" : ""
])

}
```

##如何设置请求超时时间
```
// MARK: - 设置请求超时时间
let requestClosure = { (endpoint: Endpoint<NetAPIManager>, done: @escaping MoyaProvider<NetAPIManager>.RequestResultClosure) in

guard var request = endpoint.urlRequest else { return }

request.timeoutInterval = 30    //设置请求超时时间
done(.success(request))
}
```

##自定义插件
自定义插件必须**PluginType**协议的两个方法willSend与didReceive

```
//
//  MyNetworkActivityPlugin.swift
//  NN110
//
//  Created by 陈亦海 on 2017/5/10.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation
import Result
import Moya


/// Network activity change notification type.
public enum MyNetworkActivityChangeType {
case began, ended
}

/// Notify a request's network activity changes (request begins or ends).
public final class MyNetworkActivityPlugin: PluginType {



public typealias MyNetworkActivityClosure = (_ change: MyNetworkActivityChangeType, _ target: TargetType) -> Void
let myNetworkActivityClosure: MyNetworkActivityClosure

public init(newNetworkActivityClosure: @escaping MyNetworkActivityClosure) {
self.myNetworkActivityClosure = newNetworkActivityClosure
}

// MARK: Plugin

/// Called by the provider as soon as the request is about to start
public func willSend(_ request: RequestType, target: TargetType) {
myNetworkActivityClosure(.began,target)
}

/// Called by the provider as soon as a response arrives, even if the request is cancelled.
public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
myNetworkActivityClosure(.ended,target)
}
}

```
####使用自定义插件方法
```
// MARK: - 自定义的网络提示请求插件
let myNetworkPlugin = MyNetworkActivityPlugin { (state,target) in
if state == .began {
//        SwiftSpinner.show("Connecting...")

let api = target as! NetAPIManager
if api.show {
print("我可以在这里写加载提示")
}

if !api.touch {
print("我可以在这里写禁止用户操作，等待请求结束")
}

print("我开始请求\(api.touch)")

UIApplication.shared.isNetworkActivityIndicatorVisible = true
} else {
//        SwiftSpinner.show("request finish...")
//        SwiftSpinner.hide()
print("我结束请求")
UIApplication.shared.isNetworkActivityIndicatorVisible = false

}
}

```
#自签名证书
在16年的WWDC中，Apple已表示将从2017年1月1日起，**所有新提交的App必须强制性应用HTTPS协议来进行网络请求。**默认情况下非HTTPS的网络访问是禁止的并且不能再通过简单粗暴的向Info.plist中添加NSAllowsArbitraryLoads
设置绕过ATS(App Transport Security)的限制（否则须在应用审核时进行说明并很可能会被拒）。所以还未进行相应配置的公司需要尽快将升级为HTTPS的事项提上进程了。本文将简述HTTPS及配置数字证书的原理并以配置实例和出现的问题进行说明，希望能对你提供帮助。(比心~)
![](http://upload-images.jianshu.io/upload_images/1644286-54496771bcca464d.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
HTTPS：
简单来说，HTTPS就是HTTP协议上再加一层加密处理的SSL协议,即HTTP安全版。相比HTTP，HTTPS可以保证内容在传输过程中不会被第三方查看、及时发现被第三方篡改的传输内容、防止身份冒充，从而更有效的保证网络数据的安全。
HTTPS客户端与服务器交互过程：
1、 客户端第一次请求时，服务器会返回一个包含公钥的数字证书给客户端；
2、 客户端生成对称加密密钥并用其得到的公钥对其加密后返回给服务器；
3、 服务器使用自己私钥对收到的加密数据解密，得到对称加密密钥并保存；
4、 然后双方通过对称加密的数据进行传输。
![](http://upload-images.jianshu.io/upload_images/1644286-757b5df7d56bc86f.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
数字证书：
在HTTPS客户端与服务器第一次交互时，服务端返回给客户端的数字证书是让客户端验证这个数字证书是不是服务端的，证书所有者是不是该服务器，确保数据由正确的服务端发来，没有被第三方篡改。数字证书可以保证数字证书里的公钥确实是这个证书的所有者(Subject)的，或者证书可以用来确认对方身份。证书由公钥、证书主题(Subject)、数字签名(digital signature)等内容组成。其中数字签名就是证书的防伪标签，目前使用最广泛的SHA-RSA加密。
证书一般分为两种：
1. 一种是向权威认证机构购买的证书，服务端使用该种证书时，因为苹果系统内置了其受信任的签名根证书，所以客户端不需额外的配置。为了证书安全，在证书发布机构公布证书时，证书的指纹算法都会加密后再和证书放到一起公布以防止他人伪造数字证书。而证书机构使用自己的私钥对其指纹算法加密，可以用内置在操作系统里的机构签名根证书来解密，以此保证证书的安全。
2. 另一种是自己制作的证书，即自签名证书。好处是不需要花钱购2买，但使用这种证书是不会受信任的，所以**需要我们在代码中将该证书配置为信任证书.**

自签名证书具体实现:
我们在使用自签名证书来实现HTTPS请求时，因为不像机构颁发的证书一样其签名根证书在系统中已经内置了，所以我们需要在App中内置自己服务器的签名根证书来验证数字证书。首先将服务端生成的.cer格式的根证书添加到项目中，注意在添加证书要一定要记得勾选要添加的targets。**这里有个地方要注意**：苹果的ATS要求服务端必须支持TLS 1.2或以上版本；必须使用支持前向保密的密码；证书必须使用SHA-256或者更好的签名hash算法来签名，如果证书无效，则会导致连接失败。由于我在生成的根证书时签名hash算法低于其要求，在配置完请求时一直报*NSURLErrorServerCertificateUntrusted* = -1202错误，希望大家可以注意到这一点。

那么如何在Moya中使用自签名的证书来实现HTTPS网络请求呢，请期待下回我专门分享......需要自定义一个Manager管理
#综合使用的方法如下
##定义一个公用的**Moya**请求服务对象
```
let MyAPIProvider = MoyaProvider<NetAPIManager>(endpointClosure: myEndpointClosure,requestClosure: requestClosure, plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter),myNetworkPlugin])

// MARK: -创建一个Moya请求
func sendRequest(_ postDict: Dictionary<String, Any>? = nil,
success:@escaping (Dictionary<String, Any>)->(),
failure:@escaping (MoyaError)->()) -> Cancellable? {

let request = MyAPIProvider.request(.Show) { result in    
switch result {
case let .success(moyaResponse):


do {
let any = try moyaResponse.mapJSON()
let data =  moyaResponse.data
let statusCode =  moyaResponse.statusCode
MyLog("\(data) --- \(statusCode) ----- \(any)")

success(["":""])


} catch {

}



case let .failure(error):

print(error)
failure(error)
}
}

return request
}
```

##取消所有的Moya请求
```
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
```

####完毕，待续更高级的用法...
