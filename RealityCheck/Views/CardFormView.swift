// RealityCheck/Views/CardFormView.swift
import SwiftUI
import SwiftData

struct CardFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let card: RealityCard?

    @State private var viewModel: CardFormViewModel

    init(card: RealityCard?) {
        self.card = card
        _viewModel = State(initialValue: CardFormViewModel(card: card))
    }

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel
        VStack(spacing: 0) {
            previewPanel
            formPanel
        }
        .navigationTitle(viewModel.isEditing ? String(localized: "card.form.title.edit") : String(localized: "card.form.title.create"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "card.form.action.cancel")) { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "card.form.action.save")) { viewModel.save(card: card, context: modelContext, dismiss: dismiss) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canSave)
            }
        }
    }

    // MARK: - Form panel

    private var formPanel: some View {
        @Bindable var vm = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Title + type
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(String(localized: "card.form.section.info"))
                    GlassField(String(localized: "card.form.field.title"), text: $vm.title)
                    segmentedTypePicker
                }

                // Conditional inputs
                if viewModel.type == .manual {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(String(localized: "card.form.section.value"))
                        GlassField(String(localized: "card.form.field.value"), text: $vm.value, keyboardType: .decimalPad)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(String(localized: "card.form.section.formula"))
                        FormulaChip(selected: $vm.formula)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(String(localized: "card.form.section.inputs"))
                        formulaInputs
                    }
                }

                // Display
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(String(localized: "card.form.section.display"))
                    GlassField(String(localized: "card.form.field.unit"), text: $vm.unit)
                    GlassField(String(localized: "card.form.field.context"), text: $vm.contextLine)
                }

                // Actions
                if viewModel.isEditing {
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
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { viewModel.type = t }
                } label: {
                    Text(t == .manual ? String(localized: "card.form.type.manual") : String(localized: "card.form.type.formula"))
                        .font(.system(size: 12, weight: viewModel.type == t ? .semibold : .regular))
                        .foregroundStyle(viewModel.type == t ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            viewModel.type == t
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
        @Bindable var vm = viewModel
        if viewModel.formula == .countdown {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                DatePicker(String(localized: "card.form.field.target.date"), selection: $vm.targetDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassField()

            if viewModel.previewDisplayValue != "--" {
                Text("card.form.countdown.remaining \(viewModel.previewDisplayValue)")
                    .font(.caption)
                    .foregroundStyle(Color.auroraGreen.opacity(0.8))
                    .padding(.leading, 4)
            }
        } else {
            @Bindable var vm = viewModel
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("A")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                    GlassField(String(localized: "card.form.field.label.a"), text: $vm.inputALabel)
                    GlassField(String(localized: "card.form.field.value.placeholder"), text: $vm.inputA, keyboardType: .decimalPad)
                        .frame(width: 80)
                }
                HStack(spacing: 8) {
                    Text("B")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                    GlassField(String(localized: "card.form.field.label.b"), text: $vm.inputBLabel)
                    GlassField(String(localized: "card.form.field.value.placeholder"), text: $vm.inputB, keyboardType: .decimalPad)
                        .frame(width: 80)
                }
            }
        }
    }

    // MARK: - Pin / Delete buttons

    private var pinButton: some View {
        let isPinned = card?.isPinned ?? false
        return Button {
            if let card { viewModel.togglePin(card, context: modelContext) }
        } label: {
            Label(isPinned ? String(localized: "card.form.action.unpin") : String(localized: "card.form.action.pin"), systemImage: isPinned ? "pin.slash" : "pin")
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
            if let card { viewModel.delete(card, context: modelContext, dismiss: dismiss) }
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
            SectionLabel(String(localized: "card.form.preview.section"))

            WidgetPreviewView(
                displayValue: viewModel.previewDisplayValue,
                unit: viewModel.unit,
                contextLine: viewModel.contextLine,
                accentColor: viewModel.previewAccentColor
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.previewDisplayValue)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.previewAccentColor)

            HStack(spacing: 5) {
                Circle()
                    .fill(Color.auroraGreen)
                    .frame(width: 6, height: 6)
                    .shadow(color: .auroraGreen.opacity(0.8), radius: 4)
                Text("card.form.preview.label")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.auroraGreen.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.auroraGreen.opacity(0.1))
            .overlay(Capsule().strokeBorder(Color.auroraGreen.opacity(0.22), lineWidth: 1))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}
