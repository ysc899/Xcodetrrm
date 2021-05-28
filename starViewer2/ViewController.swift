//
//  ViewController.swift
//  starViewer2
//
//  Created by 남상훈 on 2021/05/28.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    //====================
    // WebView 설정변수
    var webView: WKWebView!
    var popupWebView: WKWebView?
    //====================
    
    //====================
    // statusBar 설정변수
    var statusBarView: UIView!
    //====================
    
    //====================
    // Indicator 설정변수
    // Intro화면 종료시점 부터 최초 WebView 로딩시점까지 표시
    var activityIndicator: UIActivityIndicatorView!
    //====================
    
    //====================
    // custom statusBar를 생성하기 위한 override 함수
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //====================
    // 단말회전을 감지하기 위한 override 함수
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            // statusBar를 새로그림
            self.changeStatusBar()
        }
    }

    //====================
    // 최초 ViewController가 로딩되는 것을 확인하기 위한 override 함수
    override func viewDidLoad() {
        super.viewDidLoad()

        // statusBar를 새로그림
        changeStatusBar()
        
        let WEB_SERVER = "https://trms.seegenemedical.com/"
        let subPath = Keychain.load("isAutoLogin") == "YES" ? "mobileLogin.do" : "mobileMain.do"
        let urlPath = ("\(WEB_SERVER)\(subPath)")
     
        // 실행할 WebView의 설정을 등록
        setupWebView()
        
        // WebView에 실제 웹페이지를 로딩
        loadWebView(urlPath: urlPath)
        
        // 기존 WebView Cache 삭제
        deleteWebViewCache()
        
        // 로딩 Indicator 시작
        indicatorStart()
        
    }

    func setupWebView() {
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true                        // WebView내에서 javascript 사용을 허용
        preferences.javaScriptCanOpenWindowsAutomatically = true    // WebView내에서 javascript window.open 사용을 허용
        
        //====================
        // Event등록
        // Event 명: "fromWeb"
        // Event 방향 : Web -> WebView
        let contentController = WKUserContentController()
        contentController.add(self, name: "fromWeb")
        
        //====================
        // WebView초기값 및 Event를 WebView configuration에 등록
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = contentController

        //====================
        // fullsize WebView 생성
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        view.addSubview(webView)
    }
    
    func loadWebView(urlPath: String) {
        if let url = URL(string: urlPath) {
            let urlRequest = URLRequest.init(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
//            print("=====timeoutInterval=======>>> \(urlRequest.timeoutInterval)")
            webView.load(urlRequest)
        }
    }
    
    func deleteWebViewCache(){
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
    }
    
    func indicatorStart(){
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.large
        activityIndicator.isHidden = true

        view.addSubview(activityIndicator)
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func changeStatusBar(){
        
        let tag = 38482
        let keyWindow = UIApplication.shared.windows.first  // keyWindow 조회
        // 기존 tag값으로 생성된 statusBar가 존재하면 해당 statusBar를 조회함
        if let statusBar = keyWindow?.viewWithTag(tag){
            statusBarView = statusBar
        } else {
            // 아니면 새로운 statusBar를 생성
            guard let statusBarFrame = keyWindow?.windowScene?.statusBarManager?.statusBarFrame else {
                return
            }
            statusBarView = UIView(frame: statusBarFrame)
        }
       
        // 최초 statusBar가 CGRect 0,0으로 생성될 경우(모바일 가로모드에서 앱실행)
        // 세로모드로 전환해도 tag값으로 찾은 statusBar는 CGRect 0,0 이므로 custom statusBar가 표시되지 않음
        // 또는 세로모드를 가로모드로 전환시 statusBar의 CGRect의 크기가 짧게표시되는 경우가 있음.
        // 해서 매번 별도의 statusBar를 생성하여 생성된 CGRect를 실제 statusBar에 매핑함
        var statusBarViewTemp: UIView!
        guard let statusBarFrameTemp = keyWindow?.windowScene?.statusBarManager?.statusBarFrame else {
            return
        }
        statusBarViewTemp = UIView(frame: statusBarFrameTemp)
        
        // statusBar를 그려야 한다면 새로 statusBar의 CGRect를 생성하여 매핑
        if(statusBarViewTemp.layer.position != CGPoint(x:0, y:0)){
            print("statusBarViewTemp.layer.position 11 \(statusBarView.layer.position)")
            statusBarView.layer.position = statusBarViewTemp.layer.position
            statusBarView.layer.bounds = statusBarViewTemp.layer.bounds
            
            statusBarView.layer.zPosition = 99999
            statusBarView.backgroundColor = hexStringToUIColor("#BC1225", false)
        } else {
            // statusBar를 숨겨야 한다면 표시하지 않음
            print("statusBarViewTemp.layer.position 22 \(statusBarView.layer.position)")
            statusBarView.layer.zPosition = 0
            statusBarView.backgroundColor = hexStringToUIColor("#BC1225", true)
        }
        statusBarView.tag = tag
        keyWindow?.addSubview(statusBarView)
        
        setNeedsStatusBarAppearanceUpdate()
    }

    //====================
    // Hex Color("#BC1225")를 RGB color로 전환
    func hexStringToUIColor (_ hex:String, _ isTranslucent:Bool) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: isTranslucent ? CGFloat(0.0) : CGFloat(1.0)
        )
    }

}

extension ViewController: WKScriptMessageHandler {
    
    //====================
    // Web -> WebView로 전송된 Event를 수신하는 함수
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
       
        if message.name == "fromWeb" {
            do{
                if let json = (message.body as! String).data(using: String.Encoding.utf8){
                    if let jsonData = try JSONSerialization.jsonObject(with: json, options: .allowFragments) as? [String:AnyObject]{
                        let actionType = jsonData["actionType"] as! String
                        
                        // Event의 actionType이 "setLoginInfo" 이면
                        // 자동로그인여부, 사용자ID, 사용자PWD를 iphone keychain에 저장
                        if(actionType == "setLoginInfo") {
                            NSLog("=====> setLoginInfo")
                            if Keychain.save(key: "isAutoLogin", data: "YES") != noErr {NSLog("=====> save to keychain error: isAutoLogin")}
                            if Keychain.save(key: "uid", data: jsonData["uid"] as! String) != noErr {NSLog("=====> save to keychain error: uid")}
                            if Keychain.save(key: "upwd", data: jsonData["upwd"] as! String) != noErr {NSLog("=====> save to keychain error: upwd")}
                        }
                        // Event의 actionType이 "clearLoginInfo" 이면
                        // 자동로그인여부, 사용자ID, 사용자PWD를 iphone keychain에서 삭제
                        else if(actionType == "clearLoginInfo"){
                            NSLog("=====> clearLoginInfo")
                            if Keychain.save(key: "isAutoLogin", data: "NO") != noErr {NSLog("=====> save to keychain error: isAutoLogin")}
                            if Keychain.save(key: "uid", data: "") != noErr {NSLog("=====> save to keychain error: uid")}
                            if Keychain.save(key: "upwd", data: "") != noErr {NSLog("=====> save to keychain error: upwd")}
                        }
                    }
                }
            }catch {
                print(error.localizedDescription)
            }
           
        }
    }
}

extension ViewController: WKUIDelegate {
    
    //====================
    // 팝업 WebView를 실행시키는 함수
    // window.open
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        popupWebView = WKWebView(frame: view.bounds, configuration: configuration)
        popupWebView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popupWebView!.navigationDelegate = self
        popupWebView!.uiDelegate = self
        view.addSubview(popupWebView!)
        return popupWebView!
    }
    
    //====================
    // 팝업 WebView를 닫는 함수
    // window.close
    func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
        popupWebView = nil
    }
    
    //====================
    // HTTP 오류표시 팝업 함수
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error){
        
        var errMsg : String = ""
        let nserr = error as NSError
        if nserr.code == -1022 {
            errMsg = "error NSURLErrorAppTransportSecurityRequiresSecureConnection"
        }
        else if  nserr.code == 102 {
            //======================
            // 파일 다운로드 이후 발생오류 코드를 기준으로
            // 다운로드 완료메시지로 표기
            errMsg = "파일 다운로드 완료"
            //======================
        } else if let err = error as? URLError {
          switch(err.code) {  //  Exception no longer occurs
          case .cancelled:
            errMsg = "error Cancelled"
          case .cannotFindHost:
            errMsg = "error CannotFindHost"
          case .notConnectedToInternet:
            errMsg = "error NoInternet"
          case .resourceUnavailable:
            errMsg = "error resourceUnavailable"
          case .timedOut:
            errMsg = "error timedOut"
          default:
            errMsg =  String(describing: err.code)
          }
        }
      
        let alertController = UIAlertController(title: "씨젠의료재단", message: errMsg, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "확인", style: .cancel) { _ in
        }
        alertController.addAction(alertAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    //====================
    // WKWebView는  javascript:alert(),  javascript:confirm() 함수를 직접 구현해야 함
    // alert 함수
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
         let alertController = UIAlertController(title: "씨젠의료재단", message: message, preferredStyle: .alert)
         let alertAction = UIAlertAction(title: "확인", style: .cancel) { _ in
             completionHandler()
         }
         alertController.addAction(alertAction)
         DispatchQueue.main.async {
             self.present(alertController, animated: true, completion: nil)
         }
     }
}

extension ViewController: WKNavigationDelegate {
    //====================
    // 웹페이지 로딩 시작함수
    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    
    //====================
    // 웹페이지 로딩 완료함수
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        // 로딩 indicator 정지처리
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        
        // 자동로그인 설정일 경우
        // mobileLogin.do 페이지 로딩을 완료했다면
        // keychain에 저장된 사용자ID, 사용자PWD를 이용하여
        // javascript:setLoginInfo('uid','upwd')를 호출하여 자동로그인 처리함
        if(Keychain.load("isAutoLogin") == "YES" && String(describing: webView.url).contains("mobileLogin.do")){
            if let uid = Keychain.load("uid"), let upwd = Keychain.load("upwd") {
                let inJS = ("setLoginInfo('\(uid)', '\(upwd)')")
                webView.evaluateJavaScript(inJS) { (result, error) in
                    if result != nil {
                        print("result......... \(String(describing: result))")
                    }else{
                        print("Object : \(String(describing: result))")
                    }
                }
            }
            
        }
    }
    
    //====================
    // 파일 다운로드 함수
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let url = navigationResponse.response.url
        let attachFilename: String = navigationResponse.response.suggestedFilename ?? ""
        
        // 첨부파일이 .pdf, .hwp 이면 다운로드 처리
        if(attachFilename.contains(".pdf") || attachFilename.contains(".hwp") ){
            FileDownloader.loadFileAsyncAttatch(url: url!, filename: attachFilename) { (path, error) in
                print("PDF File downloaded to : \(path!)")
            }
            decisionHandler(.cancel)
        }else{
            decisionHandler(.allow)
        }
    }
}

