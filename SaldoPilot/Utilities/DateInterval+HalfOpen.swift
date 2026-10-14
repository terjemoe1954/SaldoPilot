import Foundation

extension DateInterval {
    /// Checks calendar/reporting periods as [start, end), so midnight at the
    /// beginning of the next period is not counted in both periods.
    func containsHalfOpen(_ date: Date) -> Bool {
        date >= start && date < end
    }
}
