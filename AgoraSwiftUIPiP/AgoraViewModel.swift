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
    
    @Published var pipLocal : Bool = true // To PiP local or remote
    var localView: PixelBufferRenderView?
    var remoteView: PixelBufferRenderView?
    
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
        agoraKit.setVideoFrameDelegate(self) // IMPORTANT: Agora Setup Raw Video Delegate
        agoraKit.enableVideo()
    
        
//        // MARK:Check if you can use camera while app is in background
//        let captureSession = AVCaptureSession()
//        // Configure the capture session.
//        captureSession.beginConfiguration()
//        if captureSession.isMultitaskingCameraAccessSupported {
//            // Enable use of the camera in multitasking modes.
//            captureSession.isMultitaskingCameraAccessEnabled = true
//            print("Bac's isMultitaskingCameraAccessEnabled is true")
//        }else {
//            print("Bac's isMultitaskingCameraAccessEnabled is false")
//
//        }
//        captureSession.commitConfiguration()


    }
    func agoraJoinChannel(channelName: String) async throws {
        agoraKit.joinChannel(byToken: nil, channelId: channelName, info: nil, uid: 0)
    }
    
    func agorLeaveChannel(){
        agoraKit.leaveChannel()
    }
    
    func SetupLocalView(localView: PixelBufferRenderView){
        self.localView = localView        
    }
    
    func SetupRemoteView(remoteView: PixelBufferRenderView){
        self.remoteView = remoteView
    }
    //////////////////////
    

    func TogglePIP() -> Bool {
        // MARK: Apple PIP Setup
        videoCallController = AVPictureInPictureVideoCallViewController()
        videoCallController?.preferredContentSize = UIScreen.main.bounds.size
        videoCallController?.view.backgroundColor = .clear
        videoCallController?.modalPresentationStyle = .overFullScreen
        
        if let videoCallController = videoCallController, let sourceView = pipLocal ? localView : remoteView {
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


// MARK: Agora callbacks to get the raw video data from local user and remote users
extension AgoraViewModel: AgoraVideoFrameDelegate {
    // Raw videoframe from local user
    func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
        if let localView = localView, let pixelBuffer = videoFrame.pixelBuffer {
            localView.renderVideoPixelBuffer(pixelBuffer: pixelBuffer, width: videoFrame.width, height: videoFrame.height)
        }
        
        return true
    }

    // Raw videoframes from remote users
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        if let remoteView = remoteView, let pixelBuffer = videoFrame.pixelBuffer {
            remoteView.renderVideoPixelBuffer(pixelBuffer: pixelBuffer, width: videoFrame.width, height: videoFrame.height)
        }
        return true
    }
}

// MARK: APPLE PiP Delegate
extension AgoraViewModel: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard let vc = pictureInPictureController.contentSource?.activeVideoCallContentViewController, let pipSourceView = pipLocal ? localView : remoteView else { return }
        
        vc.view.addSubview(pipSourceView)
        pipSourceView.frame = vc.view.bounds
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard let pipSourceView = pipLocal ? localView : remoteView else { return }
        
        pipSourceView.removeFromSuperview()
//        backgroundView.addSubview(pipSourceView)
    }
}
