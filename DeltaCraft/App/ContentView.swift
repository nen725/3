import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("倒计时", systemImage: "timer") }
            AccountsView()
                .tabItem { Label("账号", systemImage: "person.2") }
            ProfitView()
                .tabItem { Label("收益", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
    }
}
