//
//  BusDataModel.swift
//  Bus Vision
//
//  Created by 深谷悠喜 on 2025/06/06.
//

import Foundation
import SwiftUI

struct BusApproachInfo {
    let updateTime: String
    let stopFrom: String
    let stopTo: String
    let hasData: Bool
    let errorMessage: String?
    
    // 最も近い時間のバス情報詳細
    let approachInfo: String
    let routeInfo: String
    let destinationInfo: String
    let passTimeInfo: String
    let delayInfo: String
    let currentLocation: String
    let relativePosition: String
}

@MainActor
class BusDataModel: ObservableObject {
    @Published var busInfo: BusApproachInfo?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var timer: Timer?
    
    private let busURL = "https://mc.bus-vision.jp/ibako/view/approach.html?stopCdFrom=69&stopCdTo=76"
    
    init() {
        fetchBusData()
        startAutoUpdate()
    }
    
    deinit {
        Task { @MainActor in
            timer?.invalidate()
        }
    }
    
    func fetchBusData() {
        isLoading = true
        lastError = nil
        
        Task {
            do {
                let busInfo = try await scrapeBusData()
                await MainActor.run {
                    self.busInfo = busInfo
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func startAutoUpdate() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchBusData()
            }
        }
    }
    
    private func scrapeBusData() async throws -> BusApproachInfo {
        guard let url = URL(string: busURL) else {
            throw NSError(domain: "BusDataModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "無効なURL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let htmlString = String(data: data, encoding: .utf8) ?? ""
        
        // HTMLをパースしてバス情報を抽出
        let updateTime = extractUpdateTime(from: htmlString)
        let stopInfo = extractStopInfo(from: htmlString)
        let hasData = !htmlString.contains("該当する接近情報はありません")
        
        if hasData {
            // 最初のバス情報（最も近い時間）のみを抽出
            let firstBusInfo = extractFirstBusInfo(from: htmlString)
            
            return BusApproachInfo(
                updateTime: updateTime,
                stopFrom: stopInfo.from,
                stopTo: stopInfo.to,
                hasData: hasData,
                errorMessage: nil,
                approachInfo: firstBusInfo.approach,
                routeInfo: firstBusInfo.route,
                destinationInfo: firstBusInfo.destination,
                passTimeInfo: firstBusInfo.passTime,
                delayInfo: firstBusInfo.delay,
                currentLocation: firstBusInfo.currentLocation,
                relativePosition: firstBusInfo.relativePosition
            )
        } else {
            return BusApproachInfo(
                updateTime: updateTime,
                stopFrom: stopInfo.from,
                stopTo: stopInfo.to,
                hasData: false,
                errorMessage: "該当する接近情報はありません",
                approachInfo: "",
                routeInfo: "",
                destinationInfo: "",
                passTimeInfo: "",
                delayInfo: "",
                currentLocation: "",
                relativePosition: ""
            )
        }
    }
    
    private func extractUpdateTime(from html: String) -> String {
        let pattern = #"<span id="updateTime">([^<]+)</span>"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        return "不明"
    }
    
    private func extractStopInfo(from html: String) -> (from: String, to: String) {
        var fromStop = "茨城高専前"
        var toStop = "勝田駅前"
        
        // stopNmFromTitle を抽出
        let fromPattern = #"<span id="stopNmFromTitle">([^<]+)</span>"#
        if let regex = try? NSRegularExpression(pattern: fromPattern),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            fromStop = String(html[range])
        }
        
        // stopNmToTitle を抽出
        let toPattern = #"<span id="stopNmToTitle">([^<]+)</span>"#
        if let regex = try? NSRegularExpression(pattern: toPattern),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            toStop = String(html[range])
        }
        
        return (from: fromStop, to: toStop)
    }
    
    private func extractFirstBusInfo(from html: String) -> (approach: String, route: String, destination: String, passTime: String, delay: String, currentLocation: String, relativePosition: String) {
        var approachInfo = ""
        var routeInfo = ""
        var destinationInfo = ""
        var passTimeInfo = ""
        var delayInfo = ""
        var currentLocation = ""
        var relativePosition = ""
        
        // 最初のapproachDataブロックを抽出
        let approachDataPattern = #"<div class="approachData">.*?</div>\s*</div>\s*</div>"#
        if let regex = try? NSRegularExpression(pattern: approachDataPattern, options: .dotMatchesLineSeparators),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range, in: html) {
            let firstBusBlock = String(html[range])
            
            // 接近情報を抽出（あと3分で到着予定 など）
            let approachPattern = #"<div id="approachInfo" class="approachCaption">\s*([^<]+)\s*</div>"#
            if let approachRegex = try? NSRegularExpression(pattern: approachPattern),
               let approachMatch = approachRegex.firstMatch(in: firstBusBlock, range: NSRange(firstBusBlock.startIndex..., in: firstBusBlock)),
               let approachRange = Range(approachMatch.range(at: 1), in: firstBusBlock) {
                approachInfo = String(firstBusBlock[approachRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // 路線情報を抽出
            let routePattern = #"<span id="routeNm">([^<]+)</span>"#
            if let routeRegex = try? NSRegularExpression(pattern: routePattern),
               let routeMatch = routeRegex.firstMatch(in: firstBusBlock, range: NSRange(firstBusBlock.startIndex..., in: firstBusBlock)),
               let routeRange = Range(routeMatch.range(at: 1), in: firstBusBlock) {
                routeInfo = String(firstBusBlock[routeRange])
            }
            
            // 行き先情報を抽出
            let destPattern = #"<span id="destNm"[^>]*>([^<]+)</span>"#
            if let destRegex = try? NSRegularExpression(pattern: destPattern),
               let destMatch = destRegex.firstMatch(in: firstBusBlock, range: NSRange(firstBusBlock.startIndex..., in: firstBusBlock)),
               let destRange = Range(destMatch.range(at: 1), in: firstBusBlock) {
                destinationInfo = String(firstBusBlock[destRange])
            }
            
            // 発着時刻情報を抽出
            let passTimePattern = #"<span id="passTimeInfo" class="passTimeInfo"[^>]*>([^<]+)</span>"#
            if let passTimeRegex = try? NSRegularExpression(pattern: passTimePattern),
               let passTimeMatch = passTimeRegex.firstMatch(in: firstBusBlock, range: NSRange(firstBusBlock.startIndex..., in: firstBusBlock)),
               let passTimeRange = Range(passTimeMatch.range(at: 1), in: firstBusBlock) {
                passTimeInfo = String(firstBusBlock[passTimeRange])
            }
            
            // 遅延情報を抽出
            let delayPattern = #"<span id="passInfo" class="passInfoText"[^>]*>([^<]+)</span>"#
            if let delayRegex = try? NSRegularExpression(pattern: delayPattern),
               let delayMatch = delayRegex.firstMatch(in: firstBusBlock, range: NSRange(firstBusBlock.startIndex..., in: firstBusBlock)),
               let delayRange = Range(delayMatch.range(at: 1), in: firstBusBlock) {
                delayInfo = String(firstBusBlock[delayRange])
            }
            
            // 現在位置を抽出（停留所名）
            let locationPattern = #"<span id="stopNmPass" class="detailStop"[^>]*>([^<]+)</span>"#
            if let locationRegex = try? NSRegularExpression(pattern: locationPattern),
               let locationMatch = locationRegex.firstMatch(in: firstBusBlock, range: NSRange(firstBusBlock.startIndex..., in: firstBusBlock)),
               let locationRange = Range(locationMatch.range(at: 1), in: firstBusBlock) {
                currentLocation = String(firstBusBlock[locationRange])
            }
            
            // 相対位置を抽出（5個前 など）
            let relativePattern = #"<span id="beforeFromInfo-pass" class="beforeFrom"[^>]*>([^<]+)</span>"#
            if let relativeRegex = try? NSRegularExpression(pattern: relativePattern),
               let relativeMatch = relativeRegex.firstMatch(in: firstBusBlock, range: NSRange(firstBusBlock.startIndex..., in: firstBusBlock)),
               let relativeRange = Range(relativeMatch.range(at: 1), in: firstBusBlock) {
                relativePosition = String(firstBusBlock[relativeRange])
            }
        }
        
        return (
            approach: approachInfo,
            route: routeInfo,
            destination: destinationInfo,
            passTime: passTimeInfo,
            delay: delayInfo,
            currentLocation: currentLocation,
            relativePosition: relativePosition
        )
    }
}