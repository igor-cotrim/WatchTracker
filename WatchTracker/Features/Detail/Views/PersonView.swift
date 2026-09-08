import SwiftUI

/// A cast member's page, reached by tapping a face in `DetailCastSection`.
struct PersonView: View {
    let personId: Int
    let personName: String

    /// Reached from the cast carousel inside `MediaDetailView`, which does not carry the
    /// container itself — so this screen reads it the same way the detail screen does.
    @Environment(AppContainer.self) private var container
    @State private var viewModel: PersonViewModel?
    @State private var isBiographyExpanded = false

    /// `viewModel` stays injectable so tests can drive the screen from a mock; production
    /// leaves it nil and the container builds one on first appearance.
    init(personId: Int, personName: String, viewModel: PersonViewModel? = nil) {
        self.personId = personId
        self.personName = personName
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        content
            // The name is already on screen behind the navigation bar, so the title starts
            // out of the way and slides in as the header scrolls past.
            .navigationTitle(viewModel?.person?.name ?? personName)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                let viewModel = viewModel ?? container.makePersonViewModel()
                self.viewModel = viewModel
                guard viewModel.person == nil else { return }
                await viewModel.load(id: personId)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            loaded(viewModel)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 400)
        }
    }

    private func loaded(_ viewModel: PersonViewModel) -> some View {
        ScrollView {
            if viewModel.isLoading && viewModel.person == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 400)
            } else if let person = viewModel.person {
                VStack(alignment: .leading, spacing: 20) {
                    header(person)
                    biography(person)
                    credits(person)
                }
                .padding(.vertical)
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) {
                    await viewModel.load(id: personId)
                }
            }
        }
    }

    // MARK: - Sections

    private func header(_ person: PersonDetail) -> some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: person.profileURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .empty where person.profileURL != nil:
                    SkeletonView()
                default:
                    placeholder
                }
            }
            .frame(width: 110, height: 110)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: person.name)
                    .font(.title2.bold())

                if let department = person.knownForDepartment {
                    Text(verbatim: department)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let birthplace = person.placeOfBirth {
                    Label(birthplace, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func biography(_ person: PersonDetail) -> some View {
        if let bio = person.displayBiography {
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Person.biography)
                    .font(.headline)

                Text(verbatim: bio)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(isBiographyExpanded ? nil : 5)

                Button(isBiographyExpanded ? Strings.Person.readLess : Strings.Person.readMore) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isBiographyExpanded.toggle()
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(Color.brandAccent)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func credits(_ person: PersonDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Person.appearsIn)
                .font(.headline)
                .padding(.horizontal)

            if person.credits.isEmpty {
                Text(Strings.Person.noCredits)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(person.credits) { credit in
                        NavigationLink {
                            MediaDetailView(mediaType: credit.mediaType, mediaId: credit.tmdbId)
                        } label: {
                            PersonCreditCard(credit: credit)
                        }
                        .buttonStyle(PressedButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color(.systemGray3))
            }
    }
}
