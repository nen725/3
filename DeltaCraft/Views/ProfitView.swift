import SwiftUI

struct ProfitView: View {
    @Environment(AppStore.self) private var store
    @State private var apiURL = ""
    @State private var webURL = ""
    @State private var didLoad = false
    @State private var showWeb = false
    @State private var apiResult = ""
    @State private var isLoading = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("网页入口") {
                    TextField("网址（https://...）", text: $webURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("在应用内打开网页") {
                        commit()
                        if validURL(webURL) != nil {
                            showWeb = true
                        } else {
                            showError = true
                        }
                    }
                    .disabled(validURL(webURL) == nil)
                }

                Section("API 入口") {
                    TextField("API 地址", text: $apiURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button {
                        query()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("查询")
                        }
                    }
                    .disabled(validURL(apiURL) == nil)
                }

                if !apiResult.isEmpty {
                    Section("结果") {
                        Text(apiResult)
                            .font(.system(.footnote, design: .monospaced))
                    }
                }
            }
            .navigationTitle("收益查询")
            .onAppear(perform: load)
            .sheet(isPresented: $showWeb) {
                if let url = validURL(webURL) {
                    SafariView(url: url)
                }
            }
            .alert("无法打开", isPresented: $showError) {
                Button("好", role: .cancel) {}
            } message: {
                Text("请检查网址是否正确。")
            }
        }
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        apiURL = store.settings.apiURL
        webURL = store.settings.webURL
    }

    private func commit() {
        store.settings.apiURL = apiURL
        store.settings.webURL = webURL
        store.save()
    }

    private func validURL(_ s: String) -> URL? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let url = URL(string: t), let scheme = url.scheme, !scheme.isEmpty else { return nil }
        return url
    }

    private func query() {
        commit()
        guard let url = validURL(apiURL) else { return }
        isLoading = true
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let text = String(data: data, encoding: .utf8) ?? "（非文本结果）"
                await MainActor.run {
                    apiResult = text
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    apiResult = "查询失败：\(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
