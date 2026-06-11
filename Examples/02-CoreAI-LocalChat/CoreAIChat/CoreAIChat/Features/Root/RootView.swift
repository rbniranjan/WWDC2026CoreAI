import SwiftUI

struct RootView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var modelLibraryViewModel = ModelLibraryViewModel()
    @State private var selection: AppNavigation = .chat

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(AppNavigation.allCases) { item in
                    Button {
                        selection = item
                    } label: {
                        Label(item.title, systemImage: item.systemImage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selection == item ? Color.accentColor : Color.primary)
                    .listRowBackground(selection == item ? Color.accentColor.opacity(0.12) : Color.clear)
                }
            }
            .navigationTitle("CoreAIChat")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selection {
                case .chat:
                    ChatView(viewModel: chatViewModel)
                case .models:
                    ModelListView(viewModel: modelLibraryViewModel)
                case .settings:
                    SettingsView(viewModel: modelLibraryViewModel)
                }
            }
        }
        .task {
            await modelLibraryViewModel.load()
            await chatViewModel.refreshActiveModel()
        }
        .onChange(of: modelLibraryViewModel.activeModelID) {
            Task {
                await chatViewModel.refreshActiveModel()
            }
        }
    }
}
