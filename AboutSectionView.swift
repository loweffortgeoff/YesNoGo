import SwiftUI

// MARK: - App Info Model

struct LowEffortApp: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let appStoreID: String
    let slug: String?

    init(name: String, iconName: String, appStoreID: String, slug: String? = nil) {
        self.name = name
        self.iconName = iconName
        self.appStoreID = appStoreID
        self.slug = slug
    }

    var appStoreURL: URL? {
        let urlSlug = slug ?? name.lowercased().replacingOccurrences(of: " ", with: "-")
        return URL(string: "https://apps.apple.com/app/\(urlSlug)/id\(appStoreID)")
    }
}

// MARK: - App Catalog

enum LowEffortApps {
    static let elapseD = LowEffortApp(name: "Elapse(D)", iconName: "elapseddark", appStoreID: "6755078545")
    static let yesNoGo = LowEffortApp(name: "Yes? No? Go!", iconName: "yesnogoglass", appStoreID: "6754826659", slug: "yes-no-go")
    static let tasked = LowEffortApp(name: "Task(ed)", iconName: "taskeddark2", appStoreID: "6755186421")
    static let aislewise = LowEffortApp(name: "AisleWise", iconName: "aislewisenewdark", appStoreID: "6755057084")

    static let all: [LowEffortApp] = [
        elapseD, yesNoGo, tasked, aislewise
    ]
}

// MARK: - About Section View

struct AboutSectionView: View {
    /// The bundle identifier prefix to exclude the current app from "Other Apps"
    /// Pass your app's name (e.g., "Task(ed)") to exclude it from the list
    let currentAppName: String?

    /// Optional custom list of apps to display. If nil, shows all apps except current.
    let appsToShow: [LowEffortApp]?

    init(currentAppName: String? = nil, appsToShow: [LowEffortApp]? = nil) {
        self.currentAppName = currentAppName
        self.appsToShow = appsToShow
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private var otherApps: [LowEffortApp] {
        if let appsToShow = appsToShow {
            return appsToShow
        }

        guard let currentAppName = currentAppName else {
            return LowEffortApps.all
        }

        return LowEffortApps.all.filter { $0.name != currentAppName }
    }

    var body: some View {
        Group {
            // MARK: - We Also Make Section
            Section {
                ForEach(otherApps) { app in
                    OtherAppRow(app: app)
                }
            } header: {
                Text(L10n.string("about.section.we_also_make", fallback: "We Also Make"))
            }

            // MARK: - About Section
            Section {
                // Version & Build
                HStack {
                    Text(L10n.string("about.version.label", fallback: "Version"))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(L10n.format("about.version.value_format", fallback: "%@ (%@)", appVersion, buildNumber))
                        .foregroundStyle(.secondary)
                }

                // Company Website
                Link(destination: URL(string: "https://www.loweffortapps.dev")!) {
                    HStack {
                        Text(L10n.string("about.link.company_website", fallback: "Company Website"))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Substack
                Link(destination: URL(string: "https://loweffortgeoff.substack.com/")!) {
                    HStack {
                        Text(L10n.string("about.link.substack", fallback: "Read My Substack"))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Privacy Policy
                Link(destination: URL(string: "https://www.loweffortapps.dev/privacy-policy")!) {
                    HStack {
                        Text(L10n.string("about.link.privacy", fallback: "Privacy Policy"))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(L10n.string("about.section.about", fallback: "About"))
            }
        }
    }
}

// MARK: - Other App Row

struct OtherAppRow: View {
    let app: LowEffortApp

    var body: some View {
        Button(action: openAppStore) {
            HStack(spacing: 12) {
                Image(app.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(app.name)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openAppStore() {
        guard let url = app.appStoreURL else { return }

        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Form {
            AboutSectionView(currentAppName: "Task(ed)")
        }
        .navigationTitle(L10n.string("settings.nav.title", fallback: "Settings"))
    }
}
