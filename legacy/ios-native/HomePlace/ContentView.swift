import SwiftUI

struct ContentView: View {
    @State private var started = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("HomePlace")
                    .font(.headline)
                    .foregroundStyle(.tint)
                Text("Your HomePlace, on your phone")
                    .font(.largeTitle.bold())
                Text("Connect securely to the HomePlace server you host.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Get started") {
                    started = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
            .navigationDestination(isPresented: $started) {
                ServerAddressView()
            }
        }
    }
}

private struct ServerAddressView: View {
    @State private var address = ""

    var body: some View {
        Form {
            Section {
                TextField("Server address", text: $address, prompt: Text("home.example.net"))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
            } header: {
                Text("Connect to HomePlace")
            } footer: {
                Text("Enter an HTTPS domain, local hostname, or local IP address.")
            }
            Button("Continue") {}
                .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .navigationTitle("Server")
    }
}
