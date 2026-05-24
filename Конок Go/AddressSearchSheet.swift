//
//  AddressSearchSheet.swift
//  Конок Go
//

import SwiftUI
import MapKit

// MARK: - Unified Suggestion Model

struct AddressSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    var completion: MKLocalSearchCompletion?
    var mapItem: MKMapItem?
}

// MARK: - Private Delegate

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
        DispatchQueue.main.async { [weak self] in self?.onFinished() }
    }
}

// MARK: - Search Completer

@Observable
final class SearchCompleter {
    var suggestions: [AddressSuggestion] = []
    var isSearching: Bool = false

    private let mkCompleter = MKLocalSearchCompleter()
    private let delegate = SearchDelegate()
    private var searchTask: Task<Void, Never>?

    private let oshRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.5283, longitude: 72.7985),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    init() {
        mkCompleter.resultTypes = [.address, .pointOfInterest]
        mkCompleter.region = oshRegion
        delegate.onResults = { [weak self] completions in
            guard let self else { return }
            let fromCompleter = completions.map {
                AddressSuggestion(title: $0.title, subtitle: $0.subtitle, completion: $0)
            }
            self.mergeSuggestions(fromCompleter: fromCompleter)
        }
        delegate.onFinished = { [weak self] in self?.isSearching = false }
        mkCompleter.delegate = delegate
    }

    func update(query: String) {
        searchTask?.cancel()
        if query.isEmpty {
            suggestions = []
            isSearching = false
            return
        }
        isSearching = true
        mkCompleter.queryFragment = query
        searchTask = Task {
            await localSearch(query: query)
        }
    }

    private func localSearch(query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = oshRegion
        request.resultTypes = [.address, .pointOfInterest]

        guard let response = try? await MKLocalSearch(request: request).start() else { return }
        guard !Task.isCancelled else { return }

        let fromSearch = response.mapItems.compactMap { item -> AddressSuggestion? in
            let placemark = item.placemark
            let street = placemark.thoroughfare ?? ""
            let num = placemark.subThoroughfare ?? ""
            let city = placemark.locality ?? ""
            let poiName = item.name ?? ""

            // Build the main address line: "улица Ленина, 15"
            let addressLine: String
            if !street.isEmpty && !num.isEmpty {
                addressLine = "\(street), \(num)"
            } else if !street.isEmpty {
                addressLine = street
            } else if !poiName.isEmpty {
                addressLine = poiName
            } else {
                return nil
            }

            // Subtitle: city or POI detail
            let subtitle: String
            if !poiName.isEmpty && poiName != street {
                subtitle = [city, street, num].filter { !$0.isEmpty }.joined(separator: ", ")
            } else {
                subtitle = city
            }

            return AddressSuggestion(title: addressLine, subtitle: subtitle, mapItem: item)
        }

        await MainActor.run {
            mergeSuggestions(fromSearch: fromSearch)
        }
    }

    private func mergeSuggestions(fromCompleter: [AddressSuggestion] = [],
                                   fromSearch: [AddressSuggestion] = []) {
        var seen = Set<String>()
        var merged: [AddressSuggestion] = []

        // MKLocalSearch results (with house numbers) go first
        for s in fromSearch + fromCompleter {
            let key = s.title.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                merged.append(s)
            }
        }
        suggestions = merged
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

            // Header
            HStack {
                Button("Закрыть") { dismiss() }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(orange)
                Spacer()
                Text("Адрес доставки")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("Закрыть").font(.system(size: 16)).opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(orange)
                TextField("Улица и номер дома", text: $searchText)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
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

            // Body
            if searchText.isEmpty {
                emptyState
            } else if completer.isSearching && completer.suggestions.isEmpty {
                VStack { Spacer(); ProgressView(); Spacer() }
            } else if completer.suggestions.isEmpty {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isFocused = true }
        }
        .onChange(of: searchText) { _, newVal in completer.update(query: newVal) }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("Logo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(orange)
                .frame(width: 90, height: 90)
            Text("Введите улицу и номер дома")
                .font(.system(size: 15))
                .foregroundStyle(Color(.secondaryLabel))
            Spacer()
        }
    }

    private var resultsList: some View {
        List(completer.suggestions) { suggestion in
            Button { selectSuggestion(suggestion) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(.label))
                            .lineLimit(1)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
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

    private func selectSuggestion(_ suggestion: AddressSuggestion) {
        let combined: String
        if let item = suggestion.mapItem {
            let placemark = item.placemark
            let street = placemark.thoroughfare ?? ""
            let num = placemark.subThoroughfare ?? ""
            let poiName = item.name ?? ""

            if !street.isEmpty && !num.isEmpty {
                combined = "\(street), \(num)"
            } else if !street.isEmpty {
                combined = street
            } else if !poiName.isEmpty {
                combined = poiName
            } else {
                combined = suggestion.title
            }
        } else {
            combined = suggestion.subtitle.isEmpty
                ? suggestion.title
                : "\(suggestion.title), \(suggestion.subtitle)"
        }
        locationManager.saveAddress(combined)
        dismiss()
    }
}

#Preview {
    AddressSearchSheet().environmentObject(LocationManager())
}
