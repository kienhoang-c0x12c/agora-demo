//
//  UIKitQuickstartViewController.swift
//  BroadcastStreaming
//
//  Created by Bradley Hoang on 14/06/2023.
//

import UIKit
import AgoraUIKit

class UIKitQuickstartViewController: UIViewController {
  
  // Fill the App ID of your project generated on Agora Console.
  let appId: String = "c16fc101b1bd482a8533831e5057ebff"
  
  // Fill the temp token generated on Agora Console.
  let token: String? = "007eJxTYKiXPMbPJCziVjVTfvOO8Mkvbyl8sFqkIBLnt9Bn/zTX3QsUGJINzdKSDQ0MkwyTUkwsjBItTI2NLYwNU00NTM1Tk9LSfHd1pjQEMjIEcAgwMTJAIIjPBNTJwAAASwcbZg=="
  
  // Fill the channel name.
  let channelName: String = "c1"
  
  // Create the view object.
  var agoraView: AgoraVideoViewer!
  
  
  
  override func viewDidLoad() {
      super.viewDidLoad()

      initializeAndJoinChannel()
  }

  override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      agoraView.exit()
  }

  
  func initializeAndJoinChannel(){

      agoraView = AgoraVideoViewer(
          connectionData: AgoraConnectionData(
              appId: appId,
              rtcToken: token
          )
      )
      agoraView.fills(view: self.view)

      agoraView.join(
          channel: channelName,
          with: token,
          as: .broadcaster
      )
  }

}
