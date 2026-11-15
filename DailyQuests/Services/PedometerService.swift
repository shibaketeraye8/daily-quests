import Foundation
import Combine
import CoreMotion

/// Шаги за сегодня из датчика движения iPhone (CoreMotion).
/// Не требует аккаунта разработчика и доступа к «Здоровью».
final class PedometerService: ObservableObject {
    @Published private(set) var stepsToday: Int = 0
    @Published private(set) var permissionDenied: Bool = false

    private let pedometer = CMPedometer()
    private var lastRefresh = Date.distantPast

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    func refresh(force: Bool = false, _ completion: ((Int) -> Void)? = nil) {
        guard isAvailable else {
            completion?(0)
            return
        }

        if !force && Date().timeIntervalSince(lastRefresh) < 5 {
            completion?(stepsToday)
            return
        }
        lastRefresh = Date()

        let start = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if error != nil {
                    self.permissionDenied = true
                    completion?(self.stepsToday)
                    return
                }

                self.permissionDenied = false
                let steps = data?.numberOfSteps.intValue ?? 0
                self.stepsToday = steps
                completion?(steps)
            }
        }
    }
}
