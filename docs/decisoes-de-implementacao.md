# Decisões de implementação

O código não tem comentários por escolha do projeto. Este arquivo guarda o
"porquê" das decisões que não se leem no código — as arquiteturais estão no
[ADR 0001](adr/0001-arquitetura.md).

## Domain

**Todo tipo de `Domain/` é declarado `nonisolated`.** O projeto usa
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, então qualquer tipo sem anotação
nasce na main actor — incluindo structs de valor puro. Isso fazia os
repositórios `@ModelActor` chamarem entidades e mappers de fora do ator, com
warnings que viram erro no Swift 6. `Domain` é Foundation puro e não tem motivo
para estar na main actor. Alternativa não adotada: virar
`SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` no projeto inteiro e anotar
explicitamente o que precisa de main actor.

**`Decimal(approximating:)` converte pela representação decimal curta do
`Double`, não pelo valor binário.** `Decimal(_: Double)` passa pelo bits exatos
e reintroduz o ruído que `Decimal` existe para evitar: `Decimal(0.1)` não é
`0.1`. `String(value)` já dá a representação curta que arredonda de volta ao
mesmo `Double`.

**`Consumption.intervals(from:)` ignora registro com litros não positivos por
inteiro** — ele não acumula e não fecha trecho. Trecho com distância ou litros
não positivos não é produzido. O motivo de cada descarte sai por
`anomalies(in:)`, que é uma passada independente: assim `intervals` continua
trivial e a UI ainda consegue explicar por que um ponto sumiu do gráfico.

**`Consumption.anomalies(in:)` compara sempre com o registro imediatamente
anterior, não com o maior odômetro já visto.** Com o maior, um único valor
digitado errado contaminaria todos os registros seguintes; com o anterior, marca
uma linha só.

**`Maintenance` projeta em dias e expõe km/mês.** Média de km/mês combinada com
"mês = 30 dias" acumula quase uma semana de erro por ano. O `averageDaysPerMonth
= 365.25 / 12` serve só para converter o valor exposto para leitura humana.

**`Maintenance.forecast` não lê o relógio.** O ponto mais recente do histórico
faz o papel de "agora", então o mesmo histórico sempre produz a mesma previsão.
Histórico defasado se resolve acrescentando uma leitura atual.

**`Odometer.current` devolve a leitura mais recente por data, não o maior
valor.** Um odômetro que retrocede é dado inconsistente; devolver o máximo
esconderia o problema.

**`Cost.summary` devolve os totais mesmo sem distância.** Só
`costPerKilometer` é opcional: o gasto de um veículo com um único abastecimento
é conhecido, e um `nil` no agregado inteiro apagaria da tela um número que
existe.

## Data

**Cada repositório é um `@ModelActor` com seu próprio `ModelContext`, e por isso
toda escrita efetiva `save()` antes de retornar.** Sem isso, um repositório não
enxerga o que o outro acabou de gravar. É o que `commit()` centraliza.

**`save(_ rules:vehicleID:)` reconcilia por `id` em vez de apagar tudo e
reinserir.** O caminho curto daria o mesmo estado final e erraria feio: com
CloudKit ligado, cada salvamento do formulário viraria uma rodada de deletes e
inserts para sincronizar, e as regras perderiam a identidade que as liga ao
histórico.

**`fetchByID` falha alto em debug com `id` duplicado e segue com o primeiro em
produção.** O formato CloudKit proíbe `@Attribute(.unique)`, então não há
constraint; como o `UUID` é gerado localmente, colisão é bug nosso, não condição
de runtime.

**Os mappers de filho devolvem `Optional` e registram o descarte.** O schema
admite registro sem veículo — exigência do formato CloudKit —, e esse é o
caminho real por onde um dado some da tela. `DataLog.orphanDiscarded` deixa
`assertionFailure` em debug e log com id e tipo em release.

**`VehicleMapper.apply` não reescreve `id` nem `createdAt`**: são a identidade
do registro.

## Presentation

**Distância e volume usam `Measurement` com `usage: .asProvided`.** Com o uso
automático, um device em `en_US` converteria o odômetro para milhas. O
`.asProvided` mantém km e litros e ainda respeita o separador decimal do locale.

**km/L é formatado como número mais sufixo do String Catalog**, porque o
Foundation não tem unidade de eficiência em km/L.

**Os formulários guardam os números como `String`.** Só assim "campo vazio" e
"campo com zero" são estados distintos, e a validação consegue dizer qual dos
dois é o problema. `NumberInput` converte pelo `ParseStrategy` do locale, com
fallback para a notação alheia quando o texto vem de outro locale — daí os dois
`try?`, que não engolem falha: devolvem `nil` e o formulário mostra o motivo.

**O total do abastecimento sai de `FuelEntry.totalCost`**, não de uma
multiplicação na tela: é a mesma conta que alimenta o custo por km, e as duas
não podem divergir.

**`VehicleTimeline` fica em `Presentation` e não em `Domain/Calculations`.**
Agrupar por mês é apresentação; nenhuma métrica sai dali.

**`AppDependencies.inMemory()` existe por três motivos ao mesmo tempo:** valor
padrão exigido pelo `@Entry`, base dos previews e destino do fallback quando o
store em disco falha.
