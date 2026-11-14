import SwiftUI

/// 手动添加尼康相机凭据视图
/// 用于摆脱"每连接一台新相机都要重新编译 App"的痛点：
/// 用户只需输入相机的 DeviceID 与 Nonce（可从 tools/extract_pklg_credentials.py 抓包提取，
/// 或直接点击「自动反解」按钮从 DeviceID 逆向求解），保存后即可免配对直连，永久保存。
public struct AddCameraManuallyView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var coordinator = CameraSyncCoordinator.shared

    @State private var name: String = ""
    @State private var deviceIDString: String = ""
    @State private var nonceString: String = ""
    @State private var isDefault: Bool = false
    @State private var errorMessage: String?
    @State private var solverMessage: String?
    @State private var isSolving: Bool = false

    public init() {}

    public var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("相机名称 (如 NIKON Z 8)", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("DeviceID (如 0x12345678)", text: $deviceIDString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)

                    TextField("Nonce (如 0x87654321)", text: $nonceString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)

                    Toggle("设为默认自动连接相机", isOn: $isDefault)
                } header: {
                    Text("相机凭据信息")
                } footer: {
                    Text("DeviceID 与 Nonce 为 4 字节整数，支持十六进制（带 0x 前缀）或十进制输入。\n\n如何获取：① 若相机已连过官方 SnapBridge，可先只填 DeviceID，点击下方「自动反解 Nonce」；② 若无法自动反解，可用 tools/extract_pklg_credentials.py 从蓝牙抓包提取。")
                }

                Section {
                    Button {
                        solveNonce()
                    } label: {
                        HStack {
                            if isSolving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text("自动反解 Nonce")
                        }
                    }
                    .disabled(deviceIDString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSolving)

                    if let msg = solverMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(msg.contains("成功") || msg.contains("已") ? .green : .orange)
                    }
                } header: {
                    Text("自动凭据反解")
                } footer: {
                    Text("基于 SnapBridge 官方首次配对时用「Unix 毫秒时间戳作为 Java Random 种子」生成 8 字节凭据的机制，从相机广播暴露的前 4 字节 DeviceID 逆向求解后 4 字节 Nonce。已连过 SnapBridge 的相机成功率极高。")
                }

                Section {
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                            Text("保存相机")
                            Spacer()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("手动添加相机")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// 从 DeviceID 自动反解 Nonce 并填入输入框
    private func solveNonce() {
        guard let devID = CameraSyncCoordinator.parseDeviceIDString(deviceIDString) else {
            solverMessage = "DeviceID 无法解析，请先输入合法的 4 字节十六进制或十进制整数"
            return
        }
        guard devID != 0 else {
            solverMessage = "DeviceID 不能为 0"
            return
        }

        isSolving = true
        solverMessage = "正在反解 Nonce..."

        // 放在后台线程执行，避免 65536 次 LCG 反解阻塞 UI
        DispatchQueue.global(qos: .userInitiated).async {
            let candidates = SnapBridgeIdSolver.candidatesFor(targetDevice: devID)
            DispatchQueue.main.async {
                isSolving = false
                if let best = candidates.first {
                    self.nonceString = String(format: "0x%08X", best.nonce)
                    solverMessage = "反解成功！共找到 \(candidates.count) 个候选，已填入最可能的 Nonce: 0x\(String(format: "%08X", best.nonce))"
                } else {
                    solverMessage = "未能从该 DeviceID 反解出 Nonce。若相机从未连过 SnapBridge，可直接进行全新配对，无需 Nonce；或使用抓包工具手动提取。"
                }
            }
        }
    }

    private func save() {
        var errMsg = ""
        let cam = coordinator.addCameraManually(
            name: name,
            deviceIDString: deviceIDString,
            nonceString: nonceString,
            isDefault: isDefault,
            errorMessage: &errMsg
        )
        if cam != nil {
            dismiss()
        } else {
            errorMessage = errMsg
        }
    }
}
