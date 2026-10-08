import SwiftUI

struct AccountDetailView: View {
    @Environment(AppStore.self) private var store
    let accountID: UUID

    @State private var showAddCurrency = false
    @State private var showAddRental = false
    @State private var editingCurrency: Currency?
    @State private var editingRental: RentalRecord?

    private var account: Account? {
        store.accounts.first { $0.id == accountID }
    }

    var body: some View {
        Group {
            if let account {
                List {
                    Section("货币") {
                        ForEach(account.currencies) { currency in
                            HStack {
                                Text(currency.name)
                                Spacer()
                                Text(Format.compact(currency.amount))
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { editingCurrency = currency }
                        }
                        .onDelete { offsets in
                            for i in offsets {
                                store.deleteCurrency(accountID: accountID, currencyID: account.currencies[i].id)
                            }
                        }
                        Button {
                            showAddCurrency = true
                        } label: {
                            Label("添加货币", systemImage: "plus")
                        }
                    }

                    Section("出租记录") {
                        ForEach(account.rentals) { rental in
                            Button {
                                editingRental = rental
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rental.rentDate, style: .date)
                                    HStack {
                                        Text("出租时：\(Format.compact(rental.havocAtRent))")
                                        Spacer()
                                        Text("收入：\(Format.compact(rental.rentalIncome))")
                                            .foregroundStyle(.green)
                                    }
                                    .font(.subheadline)
                                }
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets {
                                store.deleteRental(accountID: accountID, rentalID: account.rentals[i].id)
                            }
                        }
                        Button {
                            showAddRental = true
                        } label: {
                            Label("添加出租记录", systemImage: "plus")
                        }
                    }
                }
                .navigationTitle(account.name)
            } else {
                ContentUnavailableView("账号不存在", systemImage: "questionmark.circle")
            }
        }
        .sheet(isPresented: $showAddCurrency) { CurrencyEditView(accountID: accountID) }
        .sheet(item: $editingCurrency) { currency in
            CurrencyEditView(accountID: accountID, currency: currency)
        }
        .sheet(isPresented: $showAddRental) { RentalEditView(accountID: accountID) }
        .sheet(item: $editingRental) { rental in
            RentalEditView(accountID: accountID, rental: rental)
        }
    }
}

struct CurrencyEditView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: UUID
    var currency: Currency?

    @State private var name: String
    @State private var amountText: String

    init(accountID: UUID, currency: Currency? = nil) {
        self.accountID = accountID
        self.currency = currency
        _name = State(initialValue: currency?.name ?? "")
        _amountText = State(initialValue: currency.map { Format.rawNumber($0.amount) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("货币名称（如：哈夫币 / 三角卷）", text: $name)
                TextField("数量（可用 k / m，如 1.2m）", text: $amountText)
                    .keyboardType(.default)
            }
            .navigationTitle(currency == nil ? "添加货币" : "编辑货币")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amount = Format.parseAmount(amountText) else { return }
                        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let currency {
                            store.updateCurrency(accountID: accountID, currencyID: currency.id, name: finalName, amount: amount)
                        } else {
                            store.addCurrency(accountID: accountID, name: finalName, amount: amount)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Format.parseAmount(amountText) == nil)
                }
            }
        }
    }
}

struct RentalEditView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let accountID: UUID
    var rental: RentalRecord?

    @State private var date: Date
    @State private var havocText: String
    @State private var incomeText: String

    init(accountID: UUID, rental: RentalRecord? = nil) {
        self.accountID = accountID
        self.rental = rental
        _date = State(initialValue: rental?.rentDate ?? Date())
        _havocText = State(initialValue: rental.map { Format.rawNumber($0.havocAtRent) } ?? "")
        _incomeText = State(initialValue: rental.map { Format.rawNumber($0.rentalIncome) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("出租日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                TextField("出租时哈夫币数量（可用 k / m）", text: $havocText)
                    .keyboardType(.default)
                TextField("出租收入（可用 k / m）", text: $incomeText)
                    .keyboardType(.default)
            }
            .navigationTitle(rental == nil ? "添加出租记录" : "编辑出租记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let havoc = Format.parseAmount(havocText),
                              let income = Format.parseAmount(incomeText) else { return }
                        if let rental {
                            store.updateRental(accountID: accountID, rentalID: rental.id, date: date, havoc: havoc, income: income)
                        } else {
                            store.addRental(accountID: accountID, date: date, havoc: havoc, income: income)
                        }
                        dismiss()
                    }
                    .disabled(Format.parseAmount(havocText) == nil || Format.parseAmount(incomeText) == nil)
                }
            }
        }
    }
}
