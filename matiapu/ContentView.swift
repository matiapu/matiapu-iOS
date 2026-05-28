//
//  ContentView.swift
//  matiapu
//
//  Created by 石田湊 on 2026/05/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 1. マップ画面（ホーム）
            MapMockView()
                .tabItem {
                    Label("マップ", systemImage: "map")
                }
            
            // 2. 悩みスワイプ画面
            SwipeMockView()
                .tabItem {
                    Label("共感", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
                }
            
            // 3. 投稿画面
            PostMockView()
                .tabItem {
                    Label("投稿", systemImage: "plus.circle.fill")
                }
            
            // 4. アカウント・設定画面
            ProfileMockView()
                .tabItem {
                    Label("アカウント", systemImage: "person.crop.circle")
                }
        }
        // タブの選択時の色（アプリのテーマカラーに合わせて変更可能）
        .tint(.blue)
    }
}

// MARK: - 以下は各画面の仮UI（後日別ファイルに切り出します）

struct MapMockView: View {
    var body: some View {
            GoogleMapView()
    }
}


struct SwipeMockView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                // カードの仮UI
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(radius: 5)
                        .frame(width: 320, height: 450)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            Text("匿名ユーザー")
                                .font(.headline)
                        }
                        
                        Text("インフラ・道路")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        
                        Text("夜道が暗くて危ないです...")
                            .font(.body)
                        
                        Spacer()
                    }
                    .padding(30)
                }
                
                Spacer()
                
                Text("右スワイプで共感 / 左でスキップ")
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }
            .navigationTitle("地域の声")
        }
    }
}

struct PostMockView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                    .padding()
                
                Button("カメラを起動して撮影") {
                    // 後日カメラ起動処理を実装
                }
                .buttonStyle(.borderedProminent)
                
                Text("写真と一緒に地域の課題を投稿します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("投稿する")
        }
    }
}

struct ProfileMockView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text("ユーザー名")
                                .font(.headline)
                            Text("登録地域: 東京都 調布市")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    NavigationLink("ユーザー名変更", destination: Text("変更画面"))
                    NavigationLink("いいねした投稿", destination: Text("履歴画面"))
                    NavigationLink("マッチングした政策", destination: Text("マッチング画面"))
                }
                
                Section {
                    Button("ログアウト", role: .destructive) { }
                }
            }
            .navigationTitle("アカウント")
        }
    }
}

#Preview {
    ContentView()
}
