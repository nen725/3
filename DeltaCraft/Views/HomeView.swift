import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var showStart = false
    @State private var showItems = false
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            Group {
                if let timer = store.activeTimer {
                    timerView(timer)
                } else {
                    idleView
                }
            }
            .navigationTitle("制造倒计时")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory = true
                    } label: {
                        Label("历史", systemImage: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showItems = true
                    } label: {
                        Label("物品", systemImage: "shippingbox")
                    }
                }
            }
            .sheet(isPresented: $showStart) { StartTimerView() }
            .sheet(isPresented: $showItems) { ItemsView() }
            .sheet(isPresented: $showHistory) { HistoryView() }
        }
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "timer")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("还没有正在进行的制造")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button {
                showStart = true
            } label: {
                Label("开始倒计时", systemImage: "play.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func timerView(_ timer: ActiveTimer) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = timer.targetDate.timeIntervalSince(context.date)
            VStack(spacing: 20) {
                Text(timer.itemName)
                    .font(.title2.bold())

                if remaining <= 0 {
                    Text("已到时间")
                        .font(.headline)
                        .foregroundStyle(.red)
                    VStack(spacing: 12) {
                        Button("完成") { store.completeTimer() }
                            .buttonStyle(.borderedProminent)
                        Button("完成并重新开始") { store.completeAndRestart() }
                            .buttonStyle(.bordered)
                        Button("稍后提醒") { store.snoozeTimer() }
                            .buttonStyle(.bordered)
                    }
                } else {
                    Text(Format.duration(remaining))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    HStack(spacing: 12) {
                        Button("标记完成") { store.completeTimer() }
                            .buttonStyle(.bordered)
                        Button("取消倒计时", role: .destructive) { store.cancelTimer() }
                            .buttonStyle(.bordered)
                    }
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
}

struct StartTimerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var hours = 8
    @State private var minutes = 0
    @State private var customName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("从物品清单选择") {
                    if store.craftItems.isEmpty {
                        Text("还没有物品，先到「物品」里添加")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.craftItems) { item in
                        Button {
                            store.startTimer(itemName: item.name, duration: item.durationSeconds)
                            dismiss()
                        } label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text(Format.duration(item.durationSeconds))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("自定义时长") {
                    Stepper(value: $hours, in: 0...72) {
                        Text("小时：\(hours)")
                    }
                    Stepper(value: $minutes, in: 0...55, step: 5) {
                        Text("分钟：\(minutes)")
                    }
                    TextField("制造名称（可选）", text: $customName)
                    Button("开始") {
                        let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalName = name.isEmpty ? "自定义制造" : name
                        let duration = TimeInterval(hours * 3600 + minutes * 60)
                        store.startTimer(itemName: finalName, duration: duration)
                        dismiss()
                    }
                    .disabled(hours == 0 && minutes == 0)
                }
            }
            .navigationTitle("开始倒计时")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct ItemsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.craftItems) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                            Text("已完成 \(store.countFor(itemName: item.name)) 次")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Format.duration(item.durationSeconds))
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("制造物品")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddItemView() }
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            store.deleteItem(id: store.craftItems[i].id)
        }
    }
}

struct AddItemView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var hours = 8
    @State private var minutes = 0

    var body: some View {
        NavigationStack {
            Form {
                TextField("物品名称", text: $name)
                Stepper(value: $hours, in: 0...72) {
                    Text("小时：\(hours)")
                }
                Stepper(value: $minutes, in: 0...55, step: 5) {
                    Text("分钟：\(minutes)")
                }
            }
            .navigationTitle("添加物品")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.addItem(name: name, hours: hours, minutes: minutes)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (hours == 0 && minutes == 0))
                }
            }
        }
    }
}

struct HistoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView("还没有完成记录", systemImage: "clock")
                } else {
                    List(store.history) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.itemName)
                            Text(entry.completedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("完成历史")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("清空", role: .destructive) { store.clearHistory() }
                        .disabled(store.history.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
