//
//  NetAPIManager.swift
//  NN110
//
//  Created by 陈亦海 on 2017/5/12.
//  Copyright © 2017年 陈亦海. All rights reserved.
//

import Foundation
import Moya


let json_BODY_REUEST = "com.ailk.gx.mapp.model.req.%@Request"

let json_TEMP = "{\"@class\":\"com.ailk.gx.mapp.model.GXCDatapackage\",\"header\":{%@},\"body\":%@}"

let json_HEADER = "\"@class\":\"com.ailk.gx.mapp.model.GXCHeader\",\"bizCode\":\"%@\",\"identityId\":null,\"respCode\":null,\"respMsg\":null,\"mode\":\"1\",\"sign\":null"


#if DEBUG
//    let HOSTURL = "http://221.7.181.199:19303"
//    let HOSTWEBURL = "http://221.7.181.199:19303"
    let HOSTURL = "http://221.7.181.199:19301"
    let HOSTWEBURL = "http://221.7.181.199:19301"

#else
    let HOSTURL = "http://221.7.181.199:19303"
    let HOSTWEBURL = "http://221.7.181.199:19303"
//    let HOSTURL = "http://221.7.181.199:19301"
//    let HOSTWEBURL = "http://221.7.181.199:19301"
#endif


enum NetAPIManager {
    case Show
    case uploadGif(Data, description: String)
    case upload(bodyData: Data)
    case download
    case request(APIName: String ,isTouch: Bool, body: Dictionary<String, Any>? ,isShow: Bool,title: String?)
    case postRequest(APIName: String ,isTouch: Bool, body: Dictionary<String, Any>? ,isShow: Bool,title: String?)
}


extension NetAPIManager: TargetType {
    var headers: [String : String]? {
        
        let sessionId =  ""
        
        return [
            "Content-Type" : "application/x-www-form-urlencoded;charset=UTF-8",
            "COOKIE" :  "JSESSIONID=\(sessionId)",
            "Accept": "application/json;application/octet-stream;text/html,text/json;text/plain;text/javascript;text/xml;application/x-www-form-urlencoded;image/png;image/jpeg;image/jpg;image/gif;image/bmp;image/*"
        ]
    }
    
    var baseURL: URL {
        
        switch self {
        case .postRequest(_, _, _, _, _):
            #if DEBUG
                return URL(string: HOSTURL)!
            #else
                return URL(string: HOSTURL)!
            #endif
        case .request(_, _, _, _, _):
             #if DEBUG
                return URL(string: "http://ws.gx10010.com/mobileservice")!
             #else
                return URL(string: "http://ws.gx10010.com/mobileservice")!
             #endif
        case .Show:
            #if DEBUG
                return URL(string: "http://10.37.242.23:8080")!
            #else
                return URL(string: "http://ws.gx10010.com/mobileservice")!
            #endif

        default:
            #if DEBUG
                return URL(string: "http://133.0.191.9:24311/mobile-service")!
            #else
                return URL(string: "http://ws.gx10010.com/mobileservice")!
            #endif
        }
        
        
    }
    
    var path: String {
        switch self {
        case .Show:
            return "dologin"  //登录
        case .upload(_):
            return ""
        case .request(_,_, _, _, _):
            return "/mapp/json.do"
        case .postRequest(let apiName, _, _, _, _):
            return "mobile/" + apiName
        case .download:
            return ""
        case .uploadGif(_, let _):
            return ""
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .Show:
            return .post
        case .request(_,_, _, _, _):
            return .post
        case .postRequest(_,_, _, _, _):
            return .post
        default:
            return .post
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .Show:
            let jsonDic = ["loginName": "Yihai","password": "123456"] as [String: Any]
            return jsonDic
            
        case .postRequest(_, _, let postDict, _, _):
            return postDict
            
        case .request(let apiName, _, let postDict, _, _):
            
//            let myClass = NSClassFromString("_iAide."+apiName) as! APIBasicClass.Type
//
//            let postString = myClass.getRequest(postDict)
//            //加密
//            let md5String = APIMessage.desHexString(postString, withEncrypt: true)
//            //压缩
//            let gzipString = APIMessage.getBase64String(md5String)
            
            let jsonDic = ["msg":"gzipString as Any"] as [String: Any]
            return jsonDic
            
        default:
            return nil
        
        }
    }
    
    var sampleData: Data {
       return "{}".data(using: String.Encoding.utf8)!
    }
    
    var task: Task {
        switch self {

        case let .uploadGif(data, description):
            let gifData = MultipartFormData(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")
            let multipartData = [gifData]
            let urlParameters = ["description": description]
            
            return .uploadCompositeMultipart(multipartData, urlParameters: urlParameters)
            
            // **********  两种方式都可以  ********** //
            
//            let gifData = MultipartFormData(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")
//            let descriptionData = MultipartFormData(provider: .data(description.data(using: .utf8)!), name: "description")
//            let multipartData = [gifData, descriptionData]
//            
//            return .uploadMultipart(multipartData)
        
        case .upload(let data):
        return .uploadMultipart([MultipartFormData(provider: .data(data), name: "file", fileName: "gif.gif", mimeType: "image/gif")])
        case  .Show:
            let jsonDic = ["loginName": "13811111111","password": "08065030"] as [String: Any]
            return .requestParameters(parameters: jsonDic, encoding: URLEncoding.default)
        case  .postRequest(_, _, let postDict, _, _):
            return .requestParameters(parameters: postDict!, encoding: URLEncoding.default)
        case  .request(let apiName, _, let postDict, _, _):
//
//            let myClass = NSClassFromString("_iAide."+apiName) as! APIBasicClass.Type
//            var postString = myClass.getRequest(postDict) as String
//
//            postString = postString.replacingOccurrences(of: "\n", with: "")
//
//            //加密
//            let md5String = APIMessage.desHexString(postString, withEncrypt: true) as String
//            //压缩
//            let gzipString = APIMessage.getBase64String(md5String) as String
            
            let jsonDic = ["msg":"gzipString"] as [String: Any]

   
            return .requestParameters(parameters: jsonDic, encoding: URLEncoding.default)
            
        default:
            let string = "{\"@class\":\"com.ailk.gx.mapp.model.GXCDatapackage\",\"header\":{\"@class\":\"com.ailk.gx.mapp.model.GXCHeader\",\"bizCode\":\"cg0004\",\"identityId\":null,\"respCode\":null,\"respMsg\":null,\"mode\":\"1\",\"sign\":null},\"body\":{\n  \"expand\" : null,\n  \"@class\" : \"com.ailk.gx.mapp.model.req.CG0004Request\",\n  \"phoneNo\" : \"13213451345\"\n}}"
            
            let jsonDic = ["msg":string]
            let data = try? JSONSerialization.data(withJSONObject: jsonDic, options: [])
            return .requestData(data!)

       }

     }
    
    var parameterEncoding: ParameterEncoding {
        switch self {
        case .request(_,_, _, _, _):
            return URLEncoding.default
        default:
            return URLEncoding.default
        }
        
    }
    

    var touch: Bool { //是否可以操作 默认是可以的
        
        switch self {
        case .request(_,let isTouch, _, _, _):
            return isTouch
        case .postRequest(_,let isTouch, _, _, _):
            return isTouch
        default:
            return true
        }
        
    }
    
    var show: Bool { //是否显示转圈提示
        
        switch self {
        case .request( _, _, _, let isShow, _):
            return isShow
        case .postRequest( _, _, _, let isShow, _):
            return isShow
        default:
            return false
        }
        
    }
    
    var title: String? { //转圈提示语句
        
        switch self {
        case .postRequest(_, _, _, _, let hudTitle):
            return hudTitle
        case .request(_, _, _, _, let hudTitle):
            return hudTitle
        default:
            return nil
        }
        
    }

    
    
}
