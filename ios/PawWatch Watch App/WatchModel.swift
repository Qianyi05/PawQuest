import SwiftUI
import HealthKit
import CoreLocation
import Combine

enum Palette {
    static let bg       = Color(hex: "#0E0F13")
    static let card     = Color(hex: "#1B1D24")
    static let primary  = Color(hex: "#FF8A4C")
    static let accent   = Color(hex: "#FFD166")
    static let text     = Color(hex: "#F2F2F5")
    static let muted    = Color(hex: "#8A8D98")
    static let ring     = Color(hex: "#2A2D37")
}

class HealthModel: ObservableObject {
    @Published var steps = 0
    @Published var authorized = false
    @Published var realCity = "Locating…"
    @Published var temperature: String = ""
    @Published var weatherReady = false

    let dailyGoal = 10000

    private let store = HKHealthStore()
    private let loc = LocationHelper()

    var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(steps) / Double(dailyGoal))
    }

    func start() {
        loc.onLocation = { [weak self] lat, lon in
            self?.fetchCity(lat: lat, lon: lon)
            self?.fetchWeather(lat: lat, lon: lon)
        }
        loc.onFallbackCity = { [weak self] name in
            DispatchQueue.main.async {
                if self?.realCity == "Locating…" { self?.realCity = name }
            }
        }
        loc.request()

        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        store.requestAuthorization(toShare: [], read: [stepType]) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.authorized = ok
                self?.refresh()
            }
        }
    }

    func refresh() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let q = HKStatisticsQuery(quantityType: stepType,
                                  quantitySamplePredicate: predicate,
                                  options: .cumulativeSum) { [weak self] _, stats, _ in
            let s = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            DispatchQueue.main.async {
                self?.steps = s
                self?.authorized = true
            }
        }
        store.execute(q)
    }

    // MARK: - Nominatim
    private func fetchCity(lat: Double, lon: Double) {
        let urlStr = "https://nominatim.openstreetmap.org/reverse?lat=\(lat)&lon=\(lon)&format=json&zoom=10&accept-language=en"
        guard let url = URL(string: urlStr) else { return }
        var req = URLRequest(url: url)
        req.setValue("PawQuest/1.0 (watchOS app)", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let addr = json["address"] as? [String: Any] else { return }
            let city = (addr["city"] as? String)
                ?? (addr["town"] as? String)
                ?? (addr["village"] as? String)
                ?? (addr["county"] as? String)
                ?? (addr["state"] as? String)
            if let city = city {
                DispatchQueue.main.async { self?.realCity = city }
            }
        }.resume()
    }

    // MARK: - Open-Meteo
    private func fetchWeather(lat: Double, lon: Double) {
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m"
        guard let url = URL(string: urlStr) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any],
                  let temp = current["temperature_2m"] as? Double else { return }
            DispatchQueue.main.async {
                self?.temperature = "\(Int(temp.rounded()))°C"
                self?.weatherReady = true
            }
        }.resume()
    }
}

class LocationHelper: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onLocation: ((Double, Double) -> Void)?
    var onFallbackCity: ((String) -> Void)?          

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        let s = m.authorizationStatus
        if s == .authorizedWhenInUse || s == .authorizedAlways {
            m.requestLocation()
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.first else { return }
        let c = loc.coordinate
        onFallbackCity?(Self.cityFromCoordinate(c))
        onLocation?(c.latitude, c.longitude)          
    }

    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
    }

    static func cityFromCoordinate(_ c: CLLocationCoordinate2D) -> String {
        let lat = c.latitude, lng = c.longitude
        guard lat > 35 && lat < 47.5 && lng > 6 && lng < 19 else {
            return "Traveling"
        }
        let cities: [(String, Double, Double)] = [
            ("Milan", 45.4642, 9.19),
            ("Como", 45.808, 9.085),
            ("Turin", 45.0703, 7.6869),
            ("Genova", 44.4056, 8.9463),
            ("Venice", 45.4408, 12.3155),
            ("Bologna", 44.4949, 11.3426),
            ("Florence", 43.7696, 11.2558),
            ("Pisa", 43.7228, 10.4017),
            ("Rome", 41.9028, 12.4964),
            ("Naples", 40.8518, 14.2681),
        ]
        var best = "Italy"; var bestD = Double.greatestFiniteMagnitude
        for (name, clat, clng) in cities {
            let d = (lat-clat)*(lat-clat) + (lng-clng)*(lng-clng)
            if d < bestD { bestD = d; best = name }
        }
        return bestD < 0.5 ? best : "Italy"
    }
}

extension Color {
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(red: Double((rgb & 0xFF0000) >> 16)/255,
                  green: Double((rgb & 0x00FF00) >> 8)/255,
                  blue: Double(rgb & 0x0000FF)/255)
    }
}
