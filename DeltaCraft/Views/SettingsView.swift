import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var didLoad = false
    @State private var snoozeMinutes = 10
    @State private var scheme = ""
    @State private var appStoreURL = ""
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var backupDocument: BackupDocument?
    @State private var showConfirmRestore = false
    @State private var importMessage = ""
    @State private var showImportResult = false

    var body: some View {
        NavigationStack {
            Form {
                Section("跳转到三角洲行动") {
                    Button {
                        commit()
                        openDeltaApp()
                    } label: {
                        Label("打开三角洲行动 App", systemImage: "arrow.up.right.square")
                    }
                    TextField("URL Scheme（可选）", text: $scheme)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("App Store 链接", text: $appStoreURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("稍后提醒") {
                    Stepper(value: $snoozeMinutes, in: 1...60) {
                        Text("\(snoozeMinutes) 分钟后再次提醒")
                    }
                }

                Section("历史记录") {
                    Text("共完成 \(store.history.count) 次制造")
                    Button("清空历史", role: .destructive) { store.clearHistory() }
                        .disabled(store.history.isEmpty)
                }

                Section("数据备份") {
                    Button {
                        if let data = store.exportData() {
                            backupDocument = BackupDocument(data: data)
                            showExporter = true
                        }
                    } label: {
                        Label("导出备份", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showConfirmRestore = true
                    } label: {
                        Label("从备份恢复", systemImage: "square.and.arrow.down")
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "1.0")
                }
            }
            .navigationTitle("设置")
            .onAppear(perform: load)
            .onDisappear { commit() }
            .fileExporter(
                isPresented: $showExporter,
                document: backupDocument,
                contentType: .json,
                defaultFilename: "特勤处助手备份"
            ) { _ in }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    importMessage = store.importData(from: url) ? "恢复成功" : "恢复失败：无法读取该文件"
                case .failure(let error):
                    importMessage = "导入失败：\(error.localizedDescription)"
                }
                showImportResult = true
            }
            .confirmationDialog("恢复会覆盖当前数据，确定吗？", isPresented: $showConfirmRestore, titleVisibility: .visible) {
                Button("恢复", role: .destructive) { showImporter = true }
                Button("取消", role: .cancel) {}
            }
            .alert("导入结果", isPresented: $showImportResult) {
                Button("好", role: .cancel) {}
            } message: {
                Text(importMessage)
            }
        }
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        snoozeMinutes = store.settings.snoozeMinutes
        scheme = store.settings.deltaAppScheme
        appStoreURL = store.settings.deltaAppStoreURL
    }

    private func commit() {
        store.settings.snoozeMinutes = snoozeMinutes
        store.settings.deltaAppScheme = scheme
        store.settings.deltaAppStoreURL = appStoreURL
        store.save()
    }

    private func openDeltaApp() {
        let trimmed = scheme.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let url = URL(string: trimmed), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }
        if let url = URL(string: appStoreURL.trimmingCharacters(in: .whitespacesAndNewlines)) {
            UIApplication.shared.open(url)
        }
    }
}
