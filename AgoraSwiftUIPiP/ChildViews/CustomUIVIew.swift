//
//  CustomUIVIew.swift
//  AgoraSwiftUIPiP
//
//  Created by BBC on 2024/8/23.
//

import Foundation
import SwiftUI
import AgoraRtcKit

struct CustomUIVIew : UIViewRepresentable {
    let videoView = UIView()

    
    func makeUIView(context: Context) -> some UIView {    
        videoView.backgroundColor = .blue
        return videoView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
      
    }
    
}
