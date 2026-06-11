//
//  ProfileView.swift
//  matiapu
//

import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.gray)
                        VStack(alignment: .leading) {
                            Text(viewModel.profile?.displayName ?? "読み込み中...")
                                .font(.headline)
                            Text("登録地域: \(viewModel.profile?.registeredArea ?? "-")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                    Button("ログアウト", role: .destructive) {
                        viewModel.signOut()
                    }
                }
            }
            .navigationTitle("アカウント")
            .task {
                await viewModel.loadProfile()
            }
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel(authRepository: MockAuthRepository()))
}
