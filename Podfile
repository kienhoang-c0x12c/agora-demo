platform :ios, '14.0'

workspace 'AgoraDemo.xcworkspace'

project 'BroadcastStreaming/BroadcastStreaming.xcodeproj'

def use_agora
  pod 'AgoraRtcEngine_iOS'
end

target 'BroadcastStreaming' do
  project 'BroadcastStreaming/BroadcastStreaming.xcodeproj'
  use_frameworks!

  use_agora
end
