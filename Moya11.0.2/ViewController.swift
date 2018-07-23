//
//  ViewController.swift
//  Moya11.0.2
//
//  Created by 陈亦海 on 2018/7/23.
//  Copyright © 2018年 陈亦海. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Moya 用法
        _ = sendPostMyRequest("dologin", touch: false, show: true, titleString: "正在登录...", postDict: ["loginName" : "17707853456","password" : "111111"], success: { (response) in
            
            
            guard response != nil else {
                
                return
            }
            
            let responseDict = response!
            guard responseDict["resCode"] as! String == "0000" else {
                
                return
            }
            
            
          
            
           
            
            
            
            
            
        }) { (error) in
            
            
            print(error)
           
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//       _ = sendReactiveSwiftRequest("dologin", touch: false, show: true, titleString: "正在登录...", postDict: ["loginName" : "17707853456","password" : "111111"], success: { (dict) in
//
//        print("sendReactiveSwiftRequest   : \(dict)")
//
//        }) { (error) in
//
//        }
        
        
        _ = sendRxSwiftRequest("dologin", touch: false, show: true, titleString: "正在登录...", postDict: ["loginName" : "17707853456","password" : "111111"], success: { (dict) in
            
            print("sendRxSwiftRequest   : \(dict)")
            
        }) { (error) in
            
        }
    }

}

