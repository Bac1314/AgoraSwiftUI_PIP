//
//  ContentView.swift
//  AgoraSwiftUIPiP
//
//  Created by BBC on 2024/8/22.
//

import SwiftUI
import AVKit

struct AgoraMainView: View {
    @StateObject var agoraVM : AgoraViewModel = AgoraViewModel()
    @State var channelName = ""
    var LocalUserRepresentView : PixelBufferRepresentable = PixelBufferRepresentable()
    var RemoteUserRepresentView : PixelBufferRepresentable = PixelBufferRepresentable()

    
    var body: some View {
        
        // MARK: JOIN CHANNEL
        if !agoraVM.joined {
            
            Image(systemName: "photo")
                .frame(width: 70, height: 70)
                .aspectRatio(1.0, contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                .font(.system(size: 60))
                .padding()
                .background(
                    LinearGradient(colors: [Color.black.opacity(0.5), Color.black, Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundStyle(Color.white.gradient)
                .cornerRadius(24)
                .shadow(radius: 5)
                .offset(y: -40)
            
            TextField("Enter Channel Name", text: $channelName)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.gray, lineWidth: 1.0)
                )
                .padding()
            
            Button(action: {
                Task {
                    try await agoraVM.agoraJoinChannel(channelName: channelName)
                }
            }, label: {
                Text("Join")
                    .bold()
                    .foregroundStyle(Color.white)
                    .padding()
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                    .background(
                        channelName.isEmpty ? Color.gray : Color.black
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

            })
            .disabled(channelName.isEmpty)
 
            
        }else {
            // MARK: Show Local User View
            HStack {
                LocalUserRepresentView
                RemoteUserRepresentView
            }
            .frame(maxWidth: .infinity, maxHeight: 350)
            .padding()
            .onAppear {
                agoraVM.SetupLocalView(localView: LocalUserRepresentView.videoView)
                agoraVM.SetupRemoteView(remoteView: RemoteUserRepresentView.videoView)
            }
            
            
            HStack {
                Button {
                    agoraVM.pipLocal = true
                    let _ = agoraVM.TogglePIP()
                } label: {
                    Text("PiP Local")
                        .padding(8)
                        .foregroundStyle(.white)
                        .background(Color.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(4)
                }
                
                Button {
                    agoraVM.pipLocal = false
                    let _ = agoraVM.TogglePIP()
                } label: {
                    Text("PiP Remote")
                        .padding(8)
                        .foregroundStyle(.white)
                        .background(Color.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(4)
                }


                Button(action: {
                    agoraVM.agorLeaveChannel()
                }, label: {
                    Text("Leave")
                        .padding(8)
                        .foregroundStyle(.white)
                        .background(Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(4)
                })
            }

        }
    }
}

#Preview {
    AgoraMainView()
}
