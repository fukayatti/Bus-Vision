//
//  MenuBarView.swift
//  Bus Vision
//
//  Created by 深谷悠喜 on 2025/06/06.
//

import SwiftUI
import ServiceManagement
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var busDataModel: BusDataModel
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー部分
            headerSection
            
            // メインコンテンツ
            mainContentSection
            
            // フッター部分
            footerSection
        }
        .background(Color(.windowBackgroundColor))
        .frame(width: 360)
        .background(TouchBarHostingView(busDataModel: busDataModel))
        .background(TouchBarHostingView(busDataModel: busDataModel))
    }
    
    // ヘッダーセクション
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // アプリアイコンとタイトル
                HStack(spacing: 8) {
                    Image(systemName: "bus.fill")
                        .font(.title2)
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Bus-Vision")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // リフレッシュボタン
                Button(action: {
                    busDataModel.fetchBusData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(busDataModel.isLoading ? .secondary : .blue)
                        .rotationEffect(.degrees(busDataModel.isLoading ? 360 : 0))
                        .animation(busDataModel.isLoading ?
                                 Animation.linear(duration: 1).repeatForever(autoreverses: false) :
                                 .default, value: busDataModel.isLoading)
                }
                .buttonStyle(.plain)
                .disabled(busDataModel.isLoading)
                .help("最新データを取得")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // 更新時刻とルート情報
            if let busInfo = busDataModel.busInfo {
                VStack(spacing: 6) {
                    Text("最終更新: \(busInfo.updateTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !busInfo.stopFrom.isEmpty && !busInfo.stopTo.isEmpty {
                        HStack(spacing: 8) {
                            Text(busInfo.stopFrom)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(busInfo.stopTo)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.1))
                                .foregroundColor(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            Divider()
        }
    }
    
    // メインコンテンツセクション
    private var mainContentSection: some View {
        VStack(spacing: 0) {
            if busDataModel.isLoading {
                loadingView
            } else if let busInfo = busDataModel.busInfo {
                if busInfo.hasData {
                    busInfoView(busInfo)
                } else {
                    noDataView(busInfo.errorMessage ?? "接近情報なし")
                }
            } else if let error = busDataModel.lastError {
                errorView(error)
            }
        }
        .padding(.vertical, 16)
    }
    
    // フッターセクション
    private var footerSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            // 自動起動設定
            HStack {
                Image(systemName: "power")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Toggle("ログイン時に自動起動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        toggleLaunchAtLogin(newValue)
                    }
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // アクションボタン
            HStack(spacing: 12) {
                Button(action: {
                    if let url = URL(string: "https://mc.bus-vision.jp/ibako/view/approach.html?stopCdFrom=69&stopCdTo=76") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "safari")
                            .font(.caption)
                        Text("ブラウザで開く")
                            .font(.subheadline)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                        Text("終了")
                            .font(.subheadline)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // ローディングビュー
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("最新データを取得中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
    }
    
    // バス情報ビュー
    private func busInfoView(_ busInfo: BusApproachInfo) -> some View {
        VStack(spacing: 16) {
            // 接近状況（メイン情報）
            if !busInfo.approachInfo.isEmpty {
                HStack(spacing: 12) {
                    Circle()
                        .fill(getStatusColor(busInfo.approachInfo))
                        .frame(width: 12, height: 12)
                        .shadow(color: getStatusColor(busInfo.approachInfo).opacity(0.5), radius: 3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(busInfo.approachInfo)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(getStatusColor(busInfo.approachInfo))
                        
                        if !busInfo.delayInfo.isEmpty {
                            Text(busInfo.delayInfo)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(getStatusColor(busInfo.approachInfo).opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getStatusColor(busInfo.approachInfo).opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            
            // 行き先と路線情報
            if !busInfo.destinationInfo.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(busInfo.destinationInfo)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    if !busInfo.routeInfo.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "route")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(busInfo.routeInfo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // 時刻情報
            if !busInfo.passTimeInfo.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.teal)
                    
                    Text(busInfo.passTimeInfo)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.teal.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)
            }
            
            // 現在位置情報
            if !busInfo.currentLocation.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(busInfo.currentLocation)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if !busInfo.relativePosition.isEmpty {
                            Text(busInfo.relativePosition)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // データなしビュー
    private func noDataView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(.yellow)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
    }
    
    // エラービュー
    private func errorView(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.title3)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("接続エラー")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
    }
    
    // 状況に応じた色を返す関数（見やすい色に変更）
    private func getStatusColor(_ approachInfo: String) -> Color {
        if approachInfo.contains("あと") && approachInfo.contains("分") {
            return .green // 接近中 - 鮮やかな緑
        } else if approachInfo.contains("発車予定") {
            return .teal // 発車前 - オレンジではなくティールに変更
        } else {
            return .blue // その他 - 青
        }
    }
    
    // 自動起動設定の切り替え
    private func toggleLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("自動起動設定の変更に失敗しました: \(error)")
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(BusDataModel())
}
