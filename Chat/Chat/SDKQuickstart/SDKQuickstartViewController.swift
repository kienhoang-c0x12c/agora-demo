//
//  SDKQuickstartViewController.swift
//  Chat
//
//  Created by Bradley Hoang on 19/06/2023.
//

import UIKit
import AgoraChat

class SDKQuickstartViewController: UIViewController {
  // Defines UI views.
  var userIdField, tokenField, remoteUserIdField, textField: UITextField!
  var loginButton, logoutButton, sendButton: UIButton!
  var logView: UITextView!
  
  func createField(placeholder: String?) -> UITextField {
    let field = UITextField()
    field.layer.borderWidth = 0.5
    field.placeholder = placeholder
    return field
  }
  
  func createButton(title: String?, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }
  
  func createLogView() -> UITextView {
    let logTextView = UITextView()
    logTextView.isEditable = false
    return logTextView
  }
  
  func initViews() {
    // Creates UI controls.
    userIdField = createField(placeholder: "User Id")
    self.view.addSubview(userIdField)
    tokenField = createField(placeholder: "Token")
    self.view.addSubview(tokenField)
    remoteUserIdField = createField(placeholder: "Remote User Id")
    self.view.addSubview(remoteUserIdField)
    textField = createField(placeholder: "Input text message")
    self.view.addSubview(textField)
    loginButton = createButton(title: "Login", action: #selector(loginAction))
    self.view.addSubview(loginButton)
    logoutButton = createButton(title: "Logout", action: #selector(logoutAction))
    self.view.addSubview(logoutButton)
    sendButton = createButton(title: "Send", action: #selector(sendAction) )
    self.view.addSubview(sendButton)
    logView = createLogView()
    self.view.addSubview(logView)
    // Replaces <#Input Your UserId#> and <#Input Your Token#> with your own user ID and token generated in Agora Console.
    self.userIdField.text = "id_2"
    self.tokenField.text = "007eJxTYPjZFLdpf/0DAV2uw38+8M0pMF+wRbhD2mmvB88M/SkLrgoqMCQbmqUlGxoYJhkmpZhYGCVamBobWxgbppoamJqnJqWlBRRPSGkIZGQ4f8SehZGBlYERCEF8FQYz81TjJNM0A12D1CRTXUPD1FRdi2QzE10TS8Mk4+SkNIOUlGQAWXQnfQ=="
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    // Defines layout UI controls.
    let fullWidth = self.view.frame.width
    userIdField.frame = CGRect(x: 30, y: 50, width: fullWidth - 60, height: 30)
    tokenField.frame = CGRect(x: 30, y: 100, width: fullWidth - 60, height: 30)
    loginButton.frame = CGRect(x: 30, y: 150, width: 80, height: 30)
    logoutButton.frame = CGRect(x: 230, y: 150, width: 80, height: 30)
    remoteUserIdField.frame = CGRect(x: 30, y: 200, width: fullWidth - 60, height: 30)
    textField.frame = CGRect(x: 30, y: 250, width: fullWidth - 60, height: 30)
    sendButton.frame = CGRect(x: 30, y: 300, width: 80, height: 30)
    logView.frame = CGRect(x: 30, y: 350, width: fullWidth - 60, height: self.view.frame.height - 350 - 50)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initViews()
    initChatSDK()
  }
  
  func initChatSDK() {
    // Replaces <#Agora App Key#> with your own App Key.
    // Initializes the Agora Chat SDK.
    let options = AgoraChatOptions(appkey: "61983441#1148008")
    options.isAutoLogin = false // Disables auto login.
    options.enableConsoleLog = true
    AgoraChatClient.shared.initializeSDK(with: options)
    // Adds the chat delegate to receive messages.
    AgoraChatClient.shared.chatManager?.add(self, delegateQueue: nil)
  }
  
  // Outputs running logs.
  func printLog(_ log: Any...) {
    DispatchQueue.main.async {
      self.logView.text.append(
        DateFormatter.localizedString(from: Date.now, dateStyle: .none, timeStyle: .medium)
        + ":  " + String(reflecting: log) + "\r\n"
      )
      self.logView.scrollRangeToVisible(NSRange(location: self.logView.text.count, length: 1))
    }
  }
}

extension SDKQuickstartViewController {
  
  // Logs in with the token.
  @objc func loginAction() {
    guard let userId = self.userIdField.text,
          let token = self.tokenField.text else {
      self.printLog("userId or token is empty")
      return;
    }
    let err = AgoraChatClient.shared.login(withUsername: userId, agoraToken: token)
    if err == nil {
      self.printLog("login success")
    } else {
      self.printLog("login failed:\(err?.errorDescription ?? "")")
    }
  }
  
  // Logs out.
  @objc func logoutAction() {
    AgoraChatClient.shared.logout(false) { err in
      if err == nil {
        self.printLog("logout success")
      }
    }
  }
}

extension SDKQuickstartViewController: AgoraChatManagerDelegate  {
  // Sends a text message.
  @objc func sendAction() {
    guard let remoteUser = remoteUserIdField.text,
          let text = textField.text,
          let currentUserName = AgoraChatClient.shared.currentUsername else {
      self.printLog("Not login or remoteUser/text is empty")
      return
    }
    let msg = AgoraChatMessage(
      conversationId: remoteUser, from: currentUserName,
      to: remoteUser, body: .text(content: text), ext: nil
    )
    AgoraChatClient.shared.chatManager?.send(msg, progress: nil) { msg, err in
      if let err = err {
        self.printLog("send msg error.\(err.errorDescription)")
      } else {
        self.printLog("send msg success")
      }
    }
  }
  func messagesDidReceive(_ aMessages: [AgoraChatMessage]) {
    for msg in aMessages {
      switch msg.swiftBody {
      case let .text(content):
        self.printLog("receive text msg,content: \(content)")
      default:
        break
      }
    }
  }
}
