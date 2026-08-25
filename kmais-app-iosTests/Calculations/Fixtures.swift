import Foundation
@testable import kmais_app_ios

/// Dia `offset` a partir da data de referência (2001-01-01 00:00 UTC).
///
/// Deslocamentos inteiros de 86.400 s, sem fuso nem horário de verão no meio,
/// para que as contas de data dos testes sejam exatas.
func day(_ offset: Int) -> Date {
    Date(timeIntervalSinceReferenceDate: Double(offset) * 86_400)
}

/// Calendário gregoriano em UTC: a previsão não pode depender do fuso da
/// máquina que roda os testes.
let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}()

/// Veículo padrão dos cenários. O cálculo não olha para o vínculo, mas a
/// entidade exige um.
let testVehicleID = UUID(uuidString: "00000000-0000-0000-0000-00000000CA11")!

/// Abastecimento com tanque cheio.
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

/// Abastecimento parcial.
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
