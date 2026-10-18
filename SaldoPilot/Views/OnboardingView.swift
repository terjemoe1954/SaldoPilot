import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var selectedPage = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.16), Color.indigo.opacity(0.08), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button("Skip", action: onFinish)
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                TabView(selection: $selectedPage) {
                    OnboardingPage(
                        systemImage: "gauge.with.dots.needle.33percent",
                        tint: .blue,
                        title: "See what you actually have left",
                        message: "SaldoPilot brings income, expenses and upcoming payments together in one clear overview."
                    )
                    .tag(0)

                    OnboardingPage(
                        systemImage: "sparkles",
                        tint: .indigo,
                        title: "Register faster",
                        message: "Smart category suggestions learn from your previous entries while leaving you in control."
                    )
                    .tag(1)

                    OnboardingPage(
                        systemImage: "lock.shield.fill",
                        tint: .green,
                        title: "Your finances stay private",
                        message: "Your records are stored in your private iCloud account and can be backed up whenever you choose."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if selectedPage < 2 {
                        withAnimation {
                            selectedPage += 1
                        }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(primaryButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .padding(.top, 8)
        }
        .interactiveDismissDisabled()
    }

    private var primaryButtonTitle: LocalizedStringKey {
        selectedPage < 2 ? "Next" : "Get started"
    }
}

private struct OnboardingPage: View {
    let systemImage: String
    let tint: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: systemImage)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 148, height: 148)
                    .background(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 38, style: .continuous)
                    )
                    .shadow(color: tint.opacity(0.24), radius: 20, y: 10)
                    .accessibilityHidden(true)

                VStack(spacing: 14) {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(message)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
            }
            .padding(.vertical, 20)
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
