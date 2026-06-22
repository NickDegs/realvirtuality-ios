import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authState: AuthState

    private enum Phase { case phone, code }
    @State private var phase: Phase = .phone
    @State private var dialCode = "+90"
    @State private var localNumber = ""
    @State private var code = ""

    private var fullPhone: String {
        dialCode + localNumber.filter(\.isNumber)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                    .padding(.top, 60)

                switch phase {
                case .phone: phoneSection
                case .code:  codeSection
                }

                if let error = authState.error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                guestSection
            }
            .padding(.bottom, 40)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: phase)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(Theme.accent)
            Text("Downify")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(phase == .phone ? "Telefon numaranızla giriş yapın"
                                 : "Telefona gelen kodu girin")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Phone step

    private var phoneSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                TextField("+90", text: $dialCode)
                    .frame(width: 64)
                    .multilineTextAlignment(.center)
                    .keyboardType(.phonePad)
                    .padding(14)
                    .glassInput()

                HStack(spacing: 10) {
                    Image(systemName: "phone").foregroundStyle(Theme.accent).frame(width: 18)
                    TextField("5XX XXX XX XX", text: $localNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                .padding(14)
                .glassInput()
            }
            .padding(.horizontal)

            Button {
                Task {
                    if await authState.sendSMSCode(phone: fullPhone) { phase = .code }
                }
            } label: {
                HStack(spacing: 8) {
                    if authState.isLoading { ProgressView().tint(.white).scaleEffect(0.85) }
                    Text("Kod Gönder").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.accent)
            .padding(.horizontal)
            .disabled(authState.isLoading || localNumber.filter(\.isNumber).count < 6)

            Text("Telefonuna SMS ile 6 haneli bir doğrulama kodu göndereceğiz.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Code step

    private var codeSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "key").foregroundStyle(Theme.accent).frame(width: 18)
                TextField("123456", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.title3.monospacedDigit())
            }
            .padding(14)
            .glassInput()
            .padding(.horizontal)

            Button {
                Task { await authState.verifySMSCode(phone: fullPhone, code: code) }
            } label: {
                HStack(spacing: 8) {
                    if authState.isLoading { ProgressView().tint(.white).scaleEffect(0.85) }
                    Text("Doğrula").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.accent)
            .padding(.horizontal)
            .disabled(authState.isLoading || code.filter(\.isNumber).count < 4)

            HStack(spacing: 16) {
                Button("Numarayı değiştir") {
                    code = ""; authState.error = nil; phase = .phone
                }
                Button("Kodu tekrar gönder") {
                    Task { _ = await authState.sendSMSCode(phone: fullPhone) }
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Guest

    private var guestSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Rectangle().fill(.separator).frame(height: 0.5)
                Text("veya").font(.caption).foregroundStyle(.secondary)
                Rectangle().fill(.separator).frame(height: 0.5)
            }
            .padding(.horizontal)

            Button {
                Task { await authState.loginAsGuest() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.dashed")
                    Text("Hesap olmadan devam et").fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(Theme.accent)
            .padding(.horizontal)
            .disabled(authState.isLoading)

            Text("Herkese açık içeriği hesap açmadan indirebilirsin.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}
