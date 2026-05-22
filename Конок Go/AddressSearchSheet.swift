//
//  AddressSearchSheet.swift
//  Конок Go
//

import SwiftUI
import MapKit

// MARK: - Private Delegate (NSObject required for MKLocalSearchCompleterDelegate)

private class SearchDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var onResults: ([MKLocalSearchCompletion]) -> Void = { _ in }
    var onFinished: () -> Void = { }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            self?.onResults(completer.results)
            self?.onFinished()
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.onFinished()
        }
    }
}

// MARK: - Search Completer (@Observable, no NSObject, no @Published issues)

@Observable
final class SearchCompleter {
    var results: [MKLocalSearchCompletion] = []
    var isSearching: Bool = false

    private let mkCompleter = MKLocalSearchCompleter()
    private let delegate = SearchDelegate()

    init() {
        mkCompleter.resultTypes = [.address, .pointOfInterest]
        mkCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.5283, longitude: 72.7985),
            span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
        )
        delegate.onResults = { [weak self] completions in
            self?.results = completions
        }
        delegate.onFinished = { [weak self] in
            self?.isSearching = false
        }
        mkCompleter.delegate = delegate
    }

    func update(query: String) {
        if query.isEmpty {
            results = []
            isSearching = false
        } else {
            isSearching = true
            mkCompleter.queryFragment = query
        }
    }
}

// MARK: - Address Search Sheet

struct AddressSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager

    @State private var completer = SearchCompleter()
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool

    private let orange = Color(red: 254/255, green: 134/255, blue: 5/255)

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack {
                Button("Закрыть") { dismiss() }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(orange)

                Spacer()

                Text("Адрес доставки")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Text("Закрыть")
                    .font(.system(size: 16, weight: .medium))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // MARK: Search Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(orange)

                TextField("Город, улица и дом", text: $searchText)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            // MARK: Body
            if searchText.isEmpty {
                emptyState
            } else if completer.isSearching && completer.results.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if !searchText.isEmpty && completer.results.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(.tertiaryLabel))
                    Text("Адресов не найдено")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(.secondaryLabel))
                    Spacer()
                }
            } else {
                resultsList
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isFocused = true
            }
        }
        .onChange(of: searchText) { _, newVal in
            completer.update(query: newVal)
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("Logo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(orange)
                .frame(width: 90, height: 90)
            Text("Начните вводить адрес")
                .font(.system(size: 15))
                .foregroundStyle(Color(.secondaryLabel))
            Spacer()
        }
    }

    // MARK: Results List

    private var resultsList: some View {
        List(completer.results, id: \.title) { result in
            Button {
                selectResult(result)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(.label))
                            .lineLimit(1)

                        if !result.subtitle.isEmpty {
                            Text(result.subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(.secondaryLabel))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    // MARK: Select Result

    private func selectResult(_ result: MKLocalSearchCompletion) {
        let combined = result.subtitle.isEmpty
            ? result.title
            : "\(result.title), \(result.subtitle)"
        locationManager.saveAddress(combined)
        dismiss()
    }
}

#Preview {
    AddressSearchSheet()
        .environmentObject(LocationManager())
}
