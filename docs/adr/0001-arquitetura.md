# ADR 0001 — Repository + MVVM em camadas dentro de um único target

- **Status:** aceito
- **Data:** 2026-08-24
- **Contexto do projeto:** app de manutenção de veículos, um desenvolvedor,
  iOS 26.5, SwiftUI + SwiftData, CloudKit desligado mas com o schema já no
  formato compatível.

## Decisão

Separar o app em `Domain`, `Data` e `Presentation`, com padrão Repository e um
ViewModel por tela. As três camadas vivem em **pastas** do mesmo target, não em
módulos separados.

`Domain` importa apenas Foundation e contém as entidades (structs), as funções
puras de cálculo, os protocolos de repositório e de serviço, e os erros.
`Data` implementa os protocolos sobre SwiftData e é a única que conhece os
`@Model`. `Presentation` fala só com protocolos de `Domain`. A composição
concreta vive em `App/AppDependencies`.

## Por que sem use cases

Nesta escala, um use case por operação seria uma camada de passagem: a maioria
teria uma linha, chamando um método de repositório. A orquestração — buscar,
calcular, expor estado — cabe no ViewModel sem que ele acumule regra de
negócio, porque o cálculo já mora em `Domain/Calculations` e é testado lá.

Revisar se: um mesmo fluxo passar a ser disparado por três ou mais telas, ou se
uma operação começar a coordenar mais de dois repositórios com regra de
consistência entre eles.

## O que a fronteira Presentation ↔ Data garante — e o que não garante

**Não é garantia. É convenção.** Como tudo é um módulo só, não existe `import`
entre as camadas, e o compilador não tem como recusar um ViewModel que
instancie `VehicleModel` diretamente.

O que está de fato garantido:

- `import SwiftUI` e `import SwiftData` em qualquer arquivo de `Domain/` falham
  o build. Isso é uma linha de import real, detectada exatamente pela regra
  `domain_no_swiftui` / `domain_no_swiftdata` do SwiftLint.

O que é apenas convenção verificada por nome:

- A regra `presentation_no_data_types` procura os identificadores da camada
  `Data` (`VehicleModel`, `ModelContext`, `SwiftData*Repository`, …) dentro de
  `Presentation/`. É por isso que os `@Model` têm sufixo `Model`: sem a
  convenção de nome, a regra não teria o que procurar. **A lista é manual** —
  um `@Model` novo precisa ser acrescentado à regra, senão passa batido.

A garantia real exigiria `Domain`, `Data` e `Presentation` como módulos
separados, com o compilador recusando o import. Isso foi descartado nesta etapa
por custo de build e de manutenção de targets. Se a fronteira for violada na
prática mais de uma vez, essa é a hora de reconsiderar.

Uma dependência adicional: se o SwiftLint não estiver instalado na máquina, a
fase de build emite um aviso e passa. O CI precisa instalá-lo para que as regras
sejam efetivamente aplicadas.

## O custo de abrir mão de `@Query`

`@Query` é a forma mais direta de ler SwiftData no SwiftUI, e é gratuita em
reatividade: a view redesenha sozinha quando o store muda. Ela foi descartada
porque exige que a view declare o tipo `@Model` — o que faz o `@Model` cruzar
até a camada de apresentação e derruba a separação inteira.

O que se paga por isso:

- Cada ViewModel carrega os dados em `onAppear` e **recarrega após cada
  escrita**. Nada de cache, nada de observação manual do `ModelContext`.
- Uma alteração feita fora da tela atual não aparece até o próximo carregamento.
  Com um app de um usuário só e CloudKit desligado, isso hoje não acontece.
- Mais código: um `load()` explícito por ViewModel, com estado de carregamento e
  de erro modelados à mão.

Esse custo é temporário por escolha, não por descuido.

## Plano para o `ResultsObserver` no iOS 27

Quando o deployment target subir para iOS 27, o `ResultsObserver` entra **dentro
das implementações** de repositório, em `Data/Repositories`. Os protocolos de
`Domain/Repositories` ganham um método aditivo do tipo

```swift
func observeAll() -> AsyncStream<[Vehicle]>
```

e nenhuma assinatura existente muda. Os ViewModels que quiserem reatividade
trocam o `load()` por um `for await` sobre esse stream; os que não quiserem
continuam funcionando como estão. Foi para permitir essa troca sem reescrita que
os repositórios já nascem `async` e devolvendo entidades.

## Quando revisar esta decisão

- A fronteira `Presentation → Data` for violada na prática: promover as camadas
  a módulos de verdade.
- Surgir uma segunda superfície consumindo os mesmos dados (widget, App Intents,
  watchOS): aí `Domain` e `Data` viram Swift Packages, porque passam a ser
  compartilhados entre targets — e o compilador passa a impor o que hoje é
  convenção.
- O recarregar-após-escrever ficar perceptível em tela: antecipar o
  `ResultsObserver` ou aceitar `@Query` numa tela específica, documentando a
  exceção.
- Um fluxo passar a ser usado por três ou mais telas: reavaliar use cases.
