//
//  AgoraViewModel.swift
//  AgoraSwiftUIPiP
//
//  Created by BBC on 2024/8/22.
//

import Foundation
import AgoraRtcKit
import AVKit
import AVFoundation

class AgoraViewModel: NSObject, ObservableObject {
    
    
    // MARK: AGORA PROPERTIES
    final var agoraKit: AgoraRtcEngineKit = AgoraRtcEngineKit()
    final var agoraAppID = ""
    @Published var joined: Bool = false
    @Published var localUID: UInt = 0
    @Published var remoteUIDs: [UInt] = []
        
//    // CUSTOM RENDERING VIEWS
//    var localCustomRenderView: PixelBufferRenderView? // For custom render
//    var remoteCustomRenderView: PixelBufferRenderView? // for custom render 
    
    // SDK RENDERING VIEWS
    var localSDKRenderView: UIView?
    var remoteSDKRenderView: UIView? // FOr SDK RENDER
    
    // MARK: APPLE PiP PROPERTIES
    private var videoCallController: AVPictureInPictureVideoCallViewController?
    private var pipController: AVPictureInPictureController?
        
    override init(){
        super.init()
        
        // MARK: Agora Initialization
        let config = AgoraRtcEngineConfig()
        config.appId = agoraAppID
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit.setChannelProfile(.liveBroadcasting)
        agoraKit.setClientRole(.broadcaster)
//        agoraKit.setVideoFrameDelegate(self) // IMPORTANT: Agora Setup Raw Video Delegate
        agoraKit.enableVideo()
        
        agoraKit.setParameters("{\"engine.video.enable_hw_decoder\":true}") // enable hardware decoding

    }
    func agoraJoinChannel(channelName: String) async throws {
        agoraKit.joinChannel(byToken: nil, channelId: channelName, info: nil, uid: 0)
    }
    
    func agorLeaveChannel(){
        agoraKit.leaveChannel()
    }
    
    
    func SetupAgoraRenderLocalView() {
//        self.localSDKRenderView = localView
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = self.localSDKRenderView
        agoraKit.setupLocalVideo(videoCanvas)
    }
    
    
    func SetupAgoraRenderRemoteView(remoteUID: UInt, render: Bool) {
//        self.remoteSDKRenderView = remoteView
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = remoteUID
        videoCanvas.renderMode = .hidden
        videoCanvas.view = render ? self.remoteSDKRenderView : nil
        agoraKit.setupRemoteVideo(videoCanvas)
    }
    
    

    func TogglePIP() -> Bool {
        // MARK: Apple PIP Setup
        videoCallController = AVPictureInPictureVideoCallViewController()
        videoCallController?.preferredContentSize = UIScreen.main.bounds.size
        videoCallController?.view.backgroundColor = .clear
        videoCallController?.modalPresentationStyle = .overFullScreen
        
        if let videoCallController = videoCallController, let sourceView = remoteSDKRenderView {
//        if let videoCallController = videoCallController, let sourceView = pipLocal ? localView : remoteView {
            pipController = AVPictureInPictureController(contentSource: .init(activeVideoCallSourceView: sourceView, contentViewController: videoCallController))
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
            pipController?.delegate = self // Setup Apple PiP Delegate
            pipController?.setValue(1, forKey: "controlsStyle")
        }
        
        guard let pipController = pipController else { return false }
        
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
        
        return true
    }
    
}

// MARK: Main Agora callbacks
extension AgoraViewModel: AgoraRtcEngineDelegate {
    // When local user joined
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        joined = true
        localUID = uid
        print("Joined channel success uid is \(uid)")
    }
    
    // Local user leaves
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        joined = false
    }
    
    // When remote user joins
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        remoteUIDs.append(uid)
    }
    
    // When remote user leaves
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        remoteUIDs.removeAll(where: {$0 == uid})
    }
}


//// MARK: Agora callbacks to get the raw video data from local user and remote users
//extension AgoraViewModel: AgoraVideoFrameDelegate {
//    // Raw videoframe from local user
//    func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
//        if let localView = localCustomRenderView, let pixelBuffer = videoFrame.pixelBuffer {
//            localView.renderVideoPixelBuffer(pixelBuffer: pixelBuffer, width: videoFrame.width, height: videoFrame.height)
//        }
//        
//        return true
//    }
//
//    // Raw videoframes from remote users
//    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
//        if let remoteView = remoteCustomRenderView, let pixelBuffer = videoFrame.pixelBuffer {
//            remoteView.renderVideoPixelBuffer(pixelBuffer: pixelBuffer, width: videoFrame.width, height: videoFrame.height)
//        }
//        return true
//    }
//}

// MARK: APPLE PiP Delegate
extension AgoraViewModel: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard let vc = pictureInPictureController.contentSource?.activeVideoCallContentViewController, let pipSourceView = remoteSDKRenderView else { return }
        
        vc.view.addSubview(pipSourceView)
        pipSourceView.frame = vc.view.bounds
        
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard let pipSourceView = remoteSDKRenderView else { return }
        
        pipSourceView.removeFromSuperview()
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        
        // When app enters background, SDK stops rendering automatically
        // You need to stop the render, then resetup the rendering
        if let remoteUID = remoteUIDs.first {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                SetupAgoraRenderRemoteView(remoteUID: remoteUID, render: false) // stop render
                SetupAgoraRenderRemoteView(remoteUID: remoteUID, render: true) // start render
            }
        }
    }
}
