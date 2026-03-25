// RealityCheck/Views/CardFormView.swift
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

    // MARK: - Preview value

    private var previewDisplayValue: String {
        switch type {
        case .manual:
            guard let v = Double(value) else { return "--" }
            return FormulaEngine.formatNumber(v)
        case .formula:
            switch formula {
            case .divide:
                guard let a = Double(inputA), let b = Double(inputB) else { return "--" }
                if b == 0 { return "∞" }
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

    private var previewAccentColor: Color {
        switch type {
        case .manual: return .auroraRed
        case .formula: return formula.accentColor
        }
    }

    private var canSave: Bool {
        !title.isEmpty && !unit.isEmpty && !contextLine.isEmpty
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            formPanel
                .frame(maxWidth: .infinity)

            Divider().opacity(0.1)

            previewPanel
                .frame(width: 200)
        }
        .navigationTitle(isEditing ? "Sửa Card" : "Tạo Card")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                GlassButton("Lưu", style: .primary, isDisabled: !canSave) { save() }
            }
        }
        .onAppear { loadCard() }
    }

    // MARK: - Form panel

    private var formPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Title + type
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Thông tin")
                    GlassField("Tiêu đề", text: $title)
                    segmentedTypePicker
                }

                // Conditional inputs
                if type == .manual {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Giá trị")
                        #if os(iOS)
                        GlassField("Số liệu", text: $value, keyboardType: .decimalPad)
                        #else
                        GlassField("Số liệu", text: $value)
                        #endif
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Công thức")
                        FormulaChip(selected: $formula)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Inputs")
                        formulaInputs
                    }
                }

                // Display
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Hiển thị")
                    GlassField("Đơn vị (ngày, tháng, triệu...)", text: $unit)
                    GlassField("Context line", text: $contextLine)
                }

                // Actions
                if isEditing {
                    HStack(spacing: 8) {
                        pinButton
                        deleteButton
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Segmented type picker

    private var segmentedTypePicker: some View {
        HStack(spacing: 0) {
            ForEach([CardType.manual, CardType.formula], id: \.self) { t in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { type = t }
                } label: {
                    Text(t == .manual ? "Manual" : "Formula")
                        .font(.system(size: 12, weight: type == t ? .semibold : .regular))
                        .foregroundStyle(type == t ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            type == t
                                ? RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Formula inputs

    @ViewBuilder
    private var formulaInputs: some View {
        if formula == .countdown {
            // Date picker with glass style
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                DatePicker("Ngày đích", selection: $targetDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassField()

            if previewDisplayValue != "--" {
                Text("→ \(previewDisplayValue) ngày còn lại")
                    .font(.caption)
                    .foregroundStyle(Color.auroraGreen.opacity(0.8))
                    .padding(.leading, 4)
            }
        } else {
            // A/B inputs
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("A")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                    GlassField("Tên (VD: Doanh số)", text: $inputALabel)
                    #if os(iOS)
                    GlassField("Giá trị", text: $inputA, keyboardType: .decimalPad)
                        .frame(width: 80)
                    #else
                    GlassField("Giá trị", text: $inputA)
                        .frame(width: 80)
                    #endif
                }
                HStack(spacing: 8) {
                    Text("B")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                    GlassField("Tên (VD: Mục tiêu)", text: $inputBLabel)
                    #if os(iOS)
                    GlassField("Giá trị", text: $inputB, keyboardType: .decimalPad)
                        .frame(width: 80)
                    #else
                    GlassField("Giá trị", text: $inputB)
                        .frame(width: 80)
                    #endif
                }
            }
        }
    }

    // MARK: - Pin / Delete buttons

    private var pinButton: some View {
        let isPinned = card?.isPinned ?? false
        return Button {
            if let card {
                withAnimation {
                    for c in (try? modelContext.fetch(FetchDescriptor<RealityCard>())) ?? [] where c.isPinned {
                        c.isPinned = false
                    }
                    card.isPinned = !isPinned
                    card.updatedAt = Date()
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
        } label: {
            Label(isPinned ? "Bỏ pin" : "Pin lên widget", systemImage: isPinned ? "pin.slash" : "pin")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .modifier(GlassSurfaceModifier(cornerRadius: 10, shadowRadius: 4))
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            if let card { modelContext.delete(card) }
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 14))
                .foregroundStyle(Color.auroraRed.opacity(0.7))
                .frame(width: 36, height: 36)
                .modifier(GlassSurfaceModifier(
                    accent: .auroraRed, accentOpacity: 0.08,
                    cornerRadius: 10, shadowRadius: 4
                ))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview panel

    private var previewPanel: some View {
        VStack(spacing: 14) {
            SectionLabel("Preview")

            WidgetPreviewView(
                displayValue: previewDisplayValue,
                unit: unit,
                contextLine: contextLine,
                accentColor: previewAccentColor
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: previewDisplayValue)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: previewAccentColor)

            // Live badge
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.auroraGreen)
                    .frame(width: 6, height: 6)
                    .shadow(color: .auroraGreen.opacity(0.8), radius: 4)
                Text("Live preview")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.auroraGreen.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.auroraGreen.opacity(0.1))
            .overlay(Capsule().strokeBorder(Color.auroraGreen.opacity(0.22), lineWidth: 1))
            .clipShape(Capsule())

            Spacer()
        }
        .padding(16)
    }

    // MARK: - Load / Save

    private func loadCard() {
        guard let card else { return }
        title = card.title
        type = card.type
        value = card.value.map { String($0) } ?? ""
        formula = card.formula ?? .divide
        inputA = card.inputA.map { String($0) } ?? ""
        inputALabel = card.inputALabel ?? ""
        inputB = card.inputB.map { String($0) } ?? ""
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

#if os(iOS)
#Preview("Tạo mới") {
    NavigationStack {
        CardFormView(card: nil)
    }
    .modelContainer(for: RealityCard.self, inMemory: true)
    .background(AuroraBackground())
    .preferredColorScheme(.dark)
}

#Preview("Chỉnh sửa") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RealityCard.self, configurations: config)
    let card = RealityCard(
        title: "Runway",
        type: .formula,
        formula: .divide,
        inputA: 300_000_000,
        inputALabel: "Tiết kiệm",
        inputB: 15_000_000,
        inputBLabel: "Chi phí / tháng",
        unit: "tháng",
        contextLine: "còn sống được nếu nghỉ việc"
    )
    container.mainContext.insert(card)
    return NavigationStack {
        CardFormView(card: card)
    }
    .modelContainer(container)
    .background(AuroraBackground())
    .preferredColorScheme(.dark)
}
#endif
