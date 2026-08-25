import Foundation

/// Um registro que o cálculo de consumo não consegue usar.
///
/// Separado de `ConsumptionInterval` de propósito: `intervals(from:)` continua
/// trivial e sempre retorna só o que é calculável, enquanto a UI tem como
/// explicar por que um ponto sumiu do gráfico — inclusive para dado que entrou
/// por importação ou migração, sem passar pela validação do formulário.
struct ConsumptionAnomaly: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// O odômetro é menor que o do registro cronologicamente anterior.
        case odometerWentBackwards(previous: Double)
        /// O odômetro é igual ao do anterior: o trecho teria distância zero.
        case odometerUnchanged(previous: Double)
        /// Litros ausentes ou negativos.
        case nonPositiveLiters
        /// Data, odômetro, litros e preço idênticos ao registro anterior —
        /// assinatura típica de duplicata vinda do sync.
        case duplicate(of: UUID)
    }

    let record: FuelEntry
    let kind: Kind

    init(record: FuelEntry, kind: Kind) {
        self.record = record
        self.kind = kind
    }
}
