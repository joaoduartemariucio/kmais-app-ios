import Foundation
@testable import kmais_app_ios

func day(_ offset: Int) -> Date {
    Date(timeIntervalSinceReferenceDate: Double(offset) * 86_400)
}

let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}()

let testVehicleID = UUID(uuidString: "00000000-0000-0000-0000-00000000CA11")!

func full(
    _ dayOffset: Int,
    _ odometer: Double,
    _ liters: Double,
    price: Decimal = 5,
    id: UUID = UUID()
) -> FuelEntry {
    FuelEntry(
        id: id,
        vehicleID: testVehicleID,
        date: day(dayOffset),
        odometer: odometer,
        liters: liters,
        pricePerLiter: price,
        isFullTank: true
    )
}

func partial(
    _ dayOffset: Int,
    _ odometer: Double,
    _ liters: Double,
    price: Decimal = 5,
    id: UUID = UUID()
) -> FuelEntry {
    FuelEntry(
        id: id,
        vehicleID: testVehicleID,
        date: day(dayOffset),
        odometer: odometer,
        liters: liters,
        pricePerLiter: price,
        isFullTank: false
    )
}

func service(_ dayOffset: Int, _ odometer: Double, _ cost: Decimal) -> ServiceEntry {
    ServiceEntry(
        vehicleID: testVehicleID,
        date: day(dayOffset),
        odometer: odometer,
        cost: cost
    )
}

func sample(_ dayOffset: Int, _ odometer: Double) -> OdometerSample {
    OdometerSample(date: day(dayOffset), odometer: odometer)
}

func rule(kilometers: Double?, months: Int?) -> ServiceRule {
    ServiceRule(
        vehicleID: testVehicleID,
        kind: .oilChange,
        kilometerInterval: kilometers,
        monthInterval: months
    )
}
