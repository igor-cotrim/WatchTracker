import SwiftUI

struct ProfileAccountSection: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        Section {
            Button(Strings.Profile.signOut, role: .destructive) {
                Task { await viewModel.signOut() }
            }

            Button(role: .destructive) {
                viewModel.isShowingDeleteConfirm = true
            } label: {
                HStack {
                    Text(Strings.Profile.deleteAccount)
                    if viewModel.isDeleting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isDeleting)
        } header: {
            Text(Strings.Profile.accountSection)
        } footer: {
            Text(Strings.Profile.dangerZoneFooter)
        }
        .alert(Strings.Profile.deleteAccountConfirmTitle, isPresented: $viewModel.isShowingDeleteConfirm) {
            Button(Strings.Common.cancel, role: .cancel) { }
            Button(Strings.Profile.deleteAccountConfirmButton, role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
        } message: {
            Text(Strings.Profile.deleteAccountConfirmMessage)
        }
        .alert(Strings.Profile.deleteAccountErrorTitle, isPresented: $viewModel.isShowingDeleteError) {
            Button(Strings.Common.ok, role: .cancel) { }
        } message: {
            Text(verbatim: viewModel.deleteError ?? "")
        }
    }
}

#Preview {
    List {
        ProfileAccountSection(viewModel: AppContainer.preview.makeProfileViewModel())
    }
}
