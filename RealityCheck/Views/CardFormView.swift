import SwiftUI
import SwiftData
import WidgetKit

struct CardFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let card: RealityCard?

    @State private var title: String = ""
    @State private var type: CardType = .manual
    @State private var value: String = ""
    @State private var formula: FormulaType = .divide
    @State private var inputA: String = ""
    @State private var inputALabel: String = ""
    @State private var inputB: String = ""
    @State private var inputBLabel: String = ""
    @State private var targetDate: Date = Date()
    @State private var unit: String = ""
    @State private var contextLine: String = ""

    private var isEditing: Bool { card != nil }

    private var previewDisplayValue: String {
        switch type {
        case .manual:
            guard let v = Double(value) else { return "--" }
            return FormulaEngine.formatNumber(v)
        case .formula:
            switch formula {
            case .divide:
                guard let a = Double(inputA), let b = Double(inputB), b != 0 else { return "--" }
                return FormulaEngine.formatNumber(a / b)
            case .count:
                guard let a = Double(inputA), let b = Double(inputB) else { return "--" }
                return "\(Int(a))/\(Int(b))"
            case .subtract:
                guard let a = Double(inputA), let b = Double(inputB) else { return "--" }
                return FormulaEngine.formatNumber(a - b)
            case .countdown:
                let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                return "\(max(0, days))"
            }
        }
    }

    var body: some View {
        Form {
            Section("Thông tin") {
                TextField("Tiêu đề", text: $title)
                Picker("Loại", selection: $type) {
                    Text("Manual").tag(CardType.manual)
                    Text("Formula").tag(CardType.formula)
                }
                .pickerStyle(.segmented)
            }

            if type == .manual {
                Section("Giá trị") {
                    TextField("Giá trị", text: $value)
                        .keyboardType(.decimalPad)
                }
            } else {
                Section("Formula") {
                    Picker("Công thức", selection: $formula) {
                        Text("Chia (A ÷ B)").tag(FormulaType.divide)
                        Text("Đếm (A / B)").tag(FormulaType.count)
                        Text("Trừ (A − B)").tag(FormulaType.subtract)
                        Text("Countdown").tag(FormulaType.countdown)
                    }

                    if formula == .countdown {
                        DatePicker("Ngày đích", selection: $targetDate, displayedComponents: .date)
                    } else {
                        TextField("Tên Input A", text: $inputALabel)
                        TextField("Giá trị A", text: $inputA)
                            .keyboardType(.decimalPad)
                        TextField("Tên Input B", text: $inputBLabel)
                        TextField("Giá trị B", text: $inputB)
                            .keyboardType(.decimalPad)
                    }
                }
            }

            Section("Hiển thị") {
                TextField("Đơn vị (ngày, tháng, triệu...)", text: $unit)
                TextField("Context line", text: $contextLine)
            }

            Section("Preview") {
                HStack {
                    Spacer()
                    WidgetPreviewView(
                        displayValue: previewDisplayValue,
                        unit: unit,
                        contextLine: contextLine
                    )
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(isEditing ? "Sửa Card" : "Tạo Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Lưu") { save() }
                    .disabled(title.isEmpty || unit.isEmpty || contextLine.isEmpty)
            }
        }
        .onAppear { loadCard() }
    }

    private func loadCard() {
        guard let card else { return }
        title = card.title
        type = card.type
        value = card.value.map { "\($0)" } ?? ""
        formula = card.formula ?? .divide
        inputA = card.inputA.map { "\($0)" } ?? ""
        inputALabel = card.inputALabel ?? ""
        inputB = card.inputB.map { "\($0)" } ?? ""
        inputBLabel = card.inputBLabel ?? ""
        targetDate = card.targetDate ?? Date()
        unit = card.unit
        contextLine = card.contextLine
    }

    private func save() {
        if let card {
            card.title = title
            card.type = type
            card.value = Double(value)
            card.formula = type == .formula ? formula : nil
            card.inputA = Double(inputA)
            card.inputALabel = inputALabel.isEmpty ? nil : inputALabel
            card.inputB = Double(inputB)
            card.inputBLabel = inputBLabel.isEmpty ? nil : inputBLabel
            card.targetDate = formula == .countdown ? targetDate : nil
            card.unit = unit
            card.contextLine = contextLine
            card.updatedAt = Date()
        } else {
            let newCard = RealityCard(
                title: title,
                type: type,
                formula: type == .formula ? formula : nil,
                value: Double(value),
                inputA: Double(inputA),
                inputALabel: inputALabel.isEmpty ? nil : inputALabel,
                inputB: Double(inputB),
                inputBLabel: inputBLabel.isEmpty ? nil : inputBLabel,
                targetDate: formula == .countdown ? targetDate : nil,
                unit: unit,
                contextLine: contextLine
            )
            modelContext.insert(newCard)
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
