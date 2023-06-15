//
//  StreamMediaViewController.swift
//  BroadcastStreaming
//
//  Created by Bradley Hoang on 15/06/2023.
//

import UIKit
import AVFoundation
import AgoraRtcKit

class StreamMediaViewController: UIViewController {
  
  var mediaPlayerBtn: UIButton!
  var mediaProgressView: UIProgressView!
  
  // The main entry point for Video SDK
  var agoraEngine: AgoraRtcEngineKit!
  // By default, set the current user role to broadcaster to both send and receive streams.
  var userRole: AgoraClientRole = .broadcaster
  
  // Update with the App ID of your project generated on Agora Console.
  let appID = "c16fc101b1bd482a8533831e5057ebff"
  // Update with the temporary token generated in Agora Console.
  var token = "007eJxTYBDTNHlT57VDf1d1y5vT5Ve4Wj5MTlx485Olc5bw4maeto8KDMmGZmnJhgaGSYZJKSYWRokWpsbGFsaGqaYGpuapSWlpwnLdKQ2BjAzvLCczMjJAIIjPBNTJwAAAItMeWA=="
  // Update with the channel name you used to generate the token in Agora Console.
  var channelName = "c1"
  
  
  // The video feed for the local user is displayed here
  var localView: UIView!
  // The video feed for the remote user is displayed here
  var remoteView: UIView!
  // Click to join or leave a call
  var joinButton: UIButton!
  // Choose to be broadcaster or audience
  var role: UISegmentedControl!
  // Track if the local user is in a call
  var joined: Bool = false
  
  var mediaPlayer: AgoraRtcMediaPlayerProtocol? // Instance of the media player
  var isMediaPlaying: Bool = false
  var mediaDuration: Int = 0
  // In a real world app, you declare the media location variable with an empty string
  // and update it when a user chooses a media file from a local or remote source.
  var mediaLocation = "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4"
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initViews()
    initializeAgoraEngine()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    leaveChannel()
    DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
  }
  
  func joinChannel() async {
    if await !self.checkForPermissions() {
      showMessage(title: "Error", text: "Permissions were not granted")
      return
    }
    
    let option = AgoraRtcChannelMediaOptions()
    
    // Set the client role option as broadcaster or audience.
    if self.userRole == .broadcaster {
      option.clientRoleType = .broadcaster
      setupLocalVideo(false)
    } else {
      option.clientRoleType = .audience
      option.audienceLatencyLevel = .lowLatency
    }
    // For a live streaming scenario, set the channel profile as liveBroadcasting.
    option.channelProfile = .liveBroadcasting
    // Join the channel with a temp token. Pass in your token and channel name here
    let result = agoraEngine.joinChannel(
      byToken: token, channelId: channelName, uid: 0, mediaOptions: option,
      joinSuccess: { (channel, uid, elapsed) in }
    )
    // Check if joining the channel was successful and set joined Bool accordingly
    if result == 0 {
      joined = true
      showMessage(title: "Success", text: "Successfully joined the channel as \(self.userRole)")
    }
  }
  
  func leaveChannel() {
    agoraEngine.stopPreview()
    let result = agoraEngine.leaveChannel(nil)
    // Check if leaving the channel was successful and set joined Bool accordingly
    if (result == 0) { joined = false }
    
    // Destroy the media player
    agoraEngine.destroyMediaPlayer(mediaPlayer)
    mediaPlayer = nil
    
  }
  
  
  func initializeAgoraEngine() {
    let config = AgoraRtcEngineConfig()
    // Pass in your App ID here.
    config.appId = appID
    // Use AgoraRtcEngineDelegate for the following delegate parameter.
    agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
  }
  
  func setupLocalVideo(_ forMediaPlayer: Bool) {
    // Enable the video module
    agoraEngine.enableVideo()
    let videoCanvas = AgoraRtcVideoCanvas()
    videoCanvas.view = localView
    videoCanvas.renderMode = .hidden
    videoCanvas.mirrorMode = .auto
    videoCanvas.uid = 0
    
    // Pass the AgoraRtcVideoCanvas object to the engine so that it renders the local video.
    if (forMediaPlayer) {
      videoCanvas.sourceType = .mediaPlayer
      videoCanvas.mediaPlayerId = mediaPlayer!.getMediaPlayerId()
    } else {
      // Start the local video preview
      agoraEngine.startPreview()
    }
    
    // Set the local video view
    agoraEngine.setupLocalVideo(videoCanvas)
  }
  
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    remoteView.frame = CGRect(x: 20, y: 50, width: 350, height: 330)
    localView.frame = CGRect(x: 20, y: 400, width: 350, height: 330)
  }
  
  func initViews() {
    // Initializes the remote video view. This view displays video when a remote host joins the channel.
    remoteView = UIView()
    self.view.addSubview(remoteView)
    // Initializes the local video window. This view displays video when the local user is a host.
    localView = UIView()
    self.view.addSubview(localView)
    //  Button to join or leave a channel
    joinButton = UIButton(type: .system)
    joinButton.frame = CGRect(x: 140, y: 700, width: 100, height: 50)
    joinButton.setTitle("Join", for: .normal)
    
    joinButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
    self.view.addSubview(joinButton)
    
    // Selector to be the host or the audience
    role = UISegmentedControl(items: ["Broadcast", "Audience"])
    role.frame = CGRect(x: 20, y: 740, width: 350, height: 40)
    role.selectedSegmentIndex = 0
    role.addTarget(self, action: #selector(roleAction), for: .valueChanged)
    self.view.addSubview(role)
    
    mediaPlayerBtn = UIButton(type: .system)
    mediaPlayerBtn.frame = CGRect(x: 100, y:550, width:200, height:50)
    mediaPlayerBtn.setTitle("Open Media File", for: .normal)
    
    mediaPlayerBtn.addTarget(self, action: #selector(mediaPlayerBtnClicked), for: .touchUpInside)
    self.view.addSubview(mediaPlayerBtn)
    
    
    mediaProgressView = UIProgressView()
    mediaProgressView.frame = CGRect(x: 50, y:600, width:300, height:50)
    
    self.view.addSubview(mediaProgressView)
    
  }
  
  @objc func mediaPlayerBtnClicked(sender: UIButton!) {
    // Initialize the mediaPlayer and open a media file
    if (mediaPlayer == nil) {
      // Create an instance of the media player
      mediaPlayer = agoraEngine.createMediaPlayer(with: self)
      // Open the media file
      mediaPlayer!.open(mediaLocation, startPos: 0)
      
      mediaPlayerBtn.isEnabled = false
      mediaPlayerBtn.setTitle("Opening Media File...", for: .normal)
      return
    }
    
    // Set up the local video container to handle the media player output
    // or the camera stream, alternately.
    isMediaPlaying = !isMediaPlaying
    // Set the stream publishing options
    updateChannelPublishOptions(isMediaPlaying)
    // Display the stream locally
    setupLocalVideo(isMediaPlaying)
    
    let state: AgoraMediaPlayerState = mediaPlayer!.getPlayerState()
    if (isMediaPlaying) { // Start or resume playing media
      if (state == .openCompleted) {
        mediaPlayer!.play()
      } else if (state == .paused) {
        mediaPlayer!.resume()
      }
      mediaPlayerBtn.setTitle("Pause Playing Media", for: .normal)
    } else {
      if (state == .playing) {
        // Pause media file
        mediaPlayer!.pause()
        mediaPlayerBtn.setTitle("Resume Playing Media", for: .normal)
      }
    }
  }
  
  
  @objc func buttonAction(sender: UIButton!) {
    if !joined {
      sender.isEnabled = false
      Task {
        await joinChannel()
        sender.isEnabled = true
      }
    } else {
      leaveChannel()
    }
  }
  
  func checkForPermissions() async -> Bool {
    var hasPermissions = await self.avAuthorization(mediaType: .video)
    // Break out, because camera permissions have been denied or restricted.
    if !hasPermissions { return false }
    hasPermissions = await self.avAuthorization(mediaType: .audio)
    return hasPermissions
  }
  
  func avAuthorization(mediaType: AVMediaType) async -> Bool {
    let mediaAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
    switch mediaAuthorizationStatus {
    case .denied, .restricted: return false
    case .authorized: return true
    case .notDetermined:
      return await withCheckedContinuation { continuation in
        AVCaptureDevice.requestAccess(for: mediaType) { granted in
          continuation.resume(returning: granted)
        }
      }
    @unknown default: return false
    }
  }
  
  @objc func roleAction(sender: UISegmentedControl!) {
    self.userRole = sender.selectedSegmentIndex == 0 ? .broadcaster : .audience
  }
  
  
  func showMessage(title: String, text: String, delay: Int = 2) -> Void {
    let deadlineTime = DispatchTime.now() + .seconds(delay)
    DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
      let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
      self.present(alert, animated: true)
      alert.dismiss(animated: true, completion: nil)
    })
  }
  
  func updateChannelPublishOptions(_ publishMediaPlayer: Bool) {
    let channelOptions: AgoraRtcChannelMediaOptions = AgoraRtcChannelMediaOptions()
    
    channelOptions.publishMediaPlayerAudioTrack = publishMediaPlayer
    channelOptions.publishMediaPlayerVideoTrack = publishMediaPlayer
    channelOptions.publishMicrophoneTrack = !publishMediaPlayer
    channelOptions.publishCameraTrack = !publishMediaPlayer
    if (publishMediaPlayer) { channelOptions.publishMediaPlayerId = Int(mediaPlayer!.getMediaPlayerId()) }
    
    agoraEngine.updateChannel(with: channelOptions)
  }
  
}

extension StreamMediaViewController: AgoraRtcEngineDelegate {
  // Callback called when a new host joins the channel
  func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    let videoCanvas = AgoraRtcVideoCanvas()
    videoCanvas.uid = uid
    videoCanvas.renderMode = .hidden
    videoCanvas.view = remoteView
    agoraEngine.setupRemoteVideo(videoCanvas)
  }
}

extension StreamMediaViewController: AgoraRtcMediaPlayerDelegate {
  func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
    if (state == .openCompleted) {
      // Media file opened successfully
      DispatchQueue.main.async {[weak self] in
        guard let weakself = self else { return }
        weakself.showMessage(title: "Media Player", text: "Media file opened successfully")
      }
      mediaDuration = mediaPlayer!.getDuration()
      // Update the UI
      DispatchQueue.main.async {[weak self] in
        guard let weakself = self else { return }
        weakself.mediaPlayerBtn.setTitle("Play Media File", for: .normal)
        weakself.mediaPlayerBtn.isEnabled = true
        weakself.mediaProgressView.progress = 0
      }
    } else if (state == .playBackAllLoopsCompleted) {
      isMediaPlaying = false
      // Media file finished playing
      DispatchQueue.main.async {[weak self] in
        guard let weakself = self else { return }
        weakself.mediaPlayerBtn.setTitle("Load Media File", for: .normal)
        // Restore camera and microphone streams
        weakself.setupLocalVideo(false)
        weakself.updateChannelPublishOptions(false)
      }
      // Clean up
      agoraEngine.destroyMediaPlayer(mediaPlayer)
      mediaPlayer = nil
    }
  }
  
  func agoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedToPosition position: Int) {
    if (mediaDuration > 0) {
      let result = (Float(position) / Float(mediaDuration))
      DispatchQueue.main.async {[weak self] in
        guard let weakself = self else { return }
        weakself.mediaProgressView.progress = result
      }
    }
  }
}
