import SwiftUI

struct ProfileSupportSection: View {
    @Bindable var viewModel: ProfileViewModel

    @Environment(\.openURL) private var openURL

    var body: some View {
        Section(Strings.Profile.supportSection) {
            Button {
                if let mailtoURL = viewModel.requestFeedback() {
                    openURL(mailtoURL) { accepted in
                        if !accepted { viewModel.mailtoDidFail() }
                    }
                }
            } label: {
                SettingsLabel(
                    title: Strings.Profile.feedback,
                    systemImage: "envelope",
                    tint: .brandPrimary
                )
            }

            Link(destination: Config.reviewURL) {
                SettingsLabel(
                    title: Strings.Profile.rateApp,
                    systemImage: "star",
                    tint: .brandAccent,
                    isExternal: true
                )
            }
        }
        .alert(Strings.Feedback.errorTitle, isPresented: $viewModel.isShowingMailUnavailable) {
            Button(Strings.Common.ok, role: .cancel) { }
        } message: {
            Text(verbatim: Strings.Feedback.errorMessage(email: Config.supportEmail))
        }
        .sheet(isPresented: $viewModel.isShowingMailComposer) {
            MailComposeView(
                recipient: FeedbackComposer.recipient,
                subject: FeedbackComposer.subject,
                body: viewModel.feedbackBody
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    List {
        ProfileSupportSection(viewModel: AppContainer.preview.makeProfileViewModel())
    }
}
