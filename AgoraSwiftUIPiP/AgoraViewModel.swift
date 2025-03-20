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
//    var localCustomRenderView: CustomPixelBufferRenderView? // For custom render
//    var remoteCustomRenderView: PixelBufferRenderView? // for custom render
    
//    // SDK RENDERING VIEWS
//    var localSDKRenderView: UIView?
//    var localSDKRenderView: CustomVideoSourcePreview = CustomVideoSourcePreview()
//    var remoteSDKRenderView: UIView? // FOr SDK RENDER
    
    // Custom Camera Capture & Render
    var localCustomRenderView: CustomPixelBufferRenderView? // For custom render
    var customCameraCapture: AgoraCameraSourcePush?
    var customTrackId: UInt32?

    
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
//        agoraKit.disableVideo()
//        agoraKit.disableAudio()
        
//        agoraKit.setParameters("{\"engine.video.enable_hw_decoder\":true}") // enable hardware decoding
//        agoraKit.setParameters("{\"che.video.enable_bg_hw_decodec\":true}") // enable hardware decoding
        

    }
    func agoraJoinChannel(channelName: String) async throws {
        agoraKit.joinChannel(byToken: nil, channelId: channelName, info: nil, uid: 0)
    }
    
    func agorLeaveChannel(){
        agoraKit.leaveChannel()
    }
    
    func SetupSelfCaptureRender() {
        // Start native camera capture
        customTrackId = agoraKit.createCustomVideoTrack()

        customCameraCapture = AgoraCameraSourcePush(delegate: self, videoView: localCustomRenderView!)
        customCameraCapture?.startCapture(ofCamera: .front)
    }
    
//    func SetupAgoraRenderLocalView(render: Bool) {
//        let videoCanvas = AgoraRtcVideoCanvas()
//        videoCanvas.uid = 0
//        videoCanvas.renderMode = .hidden
//        videoCanvas.view = render ? self.localSDKRenderView : nil
//        agoraKit.setupLocalVideo(videoCanvas)
//    }
//    
//    
//    func SetupAgoraRenderRemoteView(remoteUID: UInt, render: Bool) {
//        let videoCanvas = AgoraRtcVideoCanvas()
//        videoCanvas.uid = remoteUID
//        videoCanvas.renderMode = .hidden
//        videoCanvas.view = render ? self.remoteSDKRenderView : nil
//        agoraKit.setupRemoteVideo(videoCanvas)
//    }
//    
    

    func TogglePIP() -> Bool {
        // MARK: Apple PIP Setup
        videoCallController = AVPictureInPictureVideoCallViewController()
        videoCallController?.preferredContentSize = UIScreen.main.bounds.size
        videoCallController?.view.backgroundColor = .clear
        videoCallController?.modalPresentationStyle = .overFullScreen
        
        if let videoCallController = videoCallController, let sourceView = localCustomRenderView {
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
////        if let localView = localCustomRenderView, let pixelBuffer = videoFrame.pixelBuffer {
////            localView.renderVideoPixelBuffer(pixelBuffer: pixelBuffer, width: videoFrame.width, height: videoFrame.height)
////        }
//        return true
//    }
//
//    // Raw videoframes from remote users
//    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
////        if let remoteView = remoteCustomRenderView, let pixelBuffer = videoFrame.pixelBuffer {
////            remoteView.renderVideoPixelBuffer(pixelBuffer: pixelBuffer, width: videoFrame.width, height: videoFrame.height)
////        }
//        return true
//    }
//}

// MARK: APPLE PiP Delegate
extension AgoraViewModel: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard let vc = pictureInPictureController.contentSource?.activeVideoCallContentViewController, let pipSourceView = localCustomRenderView else { return }
        
        vc.view.addSubview(pipSourceView)
        pipSourceView.frame = vc.view.bounds
        
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        guard let pipSourceView = localCustomRenderView else { return }
        
        pipSourceView.removeFromSuperview()
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {

    }
}

extension AgoraViewModel: AgoraCameraSourcePushDelegate {
    // Callback to receive the custom video capture data
    func myVideoCapture(_ capture: AgoraCameraSourcePush, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        
        // Convert custom video data to AgoraVideoFrame
        let videoFrame = AgoraVideoFrame()
        videoFrame.format = AgoraVideoFormat.cvPixelNV12.rawValue

        // Push the AgoraVideoFrame to Agora Channel
        videoFrame.textureBuf = pixelBuffer
        videoFrame.rotation = Int32(rotation)
        // once we have the video frame, we can push to agora sdk
        let result = agoraKit.pushExternalVideoFrame(videoFrame, videoTrackId: UInt(customTrackId!))
        print("Bac's pushExternal result \(result)")
        
//        let outputVideoFrame = AgoraOutputVideoFrame()
//        outputVideoFrame.width = 720
//        outputVideoFrame.height = 1280
//        outputVideoFrame.pixelBuffer = pixelBuffer
//        outputVideoFrame.rotation = Int32(rotation)
//        localCustomRenderView?.renderFromVideoFrameData(videoData: outputVideoFrame)// Self render method
        
        // Render the custom video catpure data
        localCustomRenderView?.renderVideoPixelBuffer(pixelBuffer: pixelBuffer, width: 400, height: 640)
        
        
    }
    
    
}
