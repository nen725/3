import SwiftUI

struct AccountsView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.accounts) { account in
                    NavigationLink(value: account) {
                        VStack(alignment: .leading) {
                            Text(account.name)
                            Text("\(account.currencies.count) 种货币 · \(account.rentals.count) 条出租记录")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for i in offsets {
                        store.deleteAccount(id: store.accounts[i].id)
                    }
                }
            }
            .navigationTitle("账号")
            .navigationDestination(for: Account.self) { account in
                AccountDetailView(accountID: account.id)
            }
            .overlay {
                if store.accounts.isEmpty {
                    ContentUnavailableView("还没有账号", systemImage: "person.2", description: Text("点右上角添加一个账号"))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddAccountView() }
        }
    }
}

struct AddAccountView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("账号名称", text: $name)
            }
            .navigationTitle("添加账号")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.addAccount(name: name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
