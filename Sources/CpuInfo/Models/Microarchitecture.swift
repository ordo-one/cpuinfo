// ===----------------------------------------------------------------------===//
//
// Copyright © 2022-2026 Ordo One AB
//
// Licensed under Apache License v2.0
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2022-2026 Ordo One AB
//
// https://ordo.one
//
// ===----------------------------------------------------------------------===//

internal import _cpuinfo

// swiftlint:disable type_body_length
/// The CPU microarchitecture as identified by cpuinfo.
///
/// Each case corresponds to a specific processor design. Use the
/// ``Cluster/microarchitecture`` or ``Core/microarchitecture`` properties
/// to determine which microarchitecture a given core uses.
///
/// New cases arrive in minor releases, as vendor bumps bring in hardware that upstream
/// cpuinfo has learned to recognize, so switch over this type with a `default` case.
///
/// - Example:
/// ```swift
/// for cluster in ProcessorInfo.current.clusters {
///     print(cluster.microarchitecture.description)
///     // e.g. "Apple Firestorm (A14/M1 P-core)" or "AMD Zen 4 (Ryzen 7000 / EPYC Genoa)"
/// }
/// ```
public enum Microarchitecture: UInt32, Sendable, Equatable, Hashable, Codable, CaseIterable, CustomStringConvertible {
    /// Microarchitecture could not be determined.
    case unknown = 0

    // MARK: - Intel P5/P6/Core

    case p5           = 0x00100100 // swiftlint:disable:this identifier_name
    case quark        = 0x00100101
    case p6           = 0x00100200 // swiftlint:disable:this identifier_name
    case dothan       = 0x00100201
    case yonah        = 0x00100202
    case conroe       = 0x00100203
    case penryn       = 0x00100204
    case nehalem      = 0x00100205
    case sandyBridge  = 0x00100206
    case ivyBridge    = 0x00100207
    case haswell      = 0x00100208
    case broadwell    = 0x00100209
    case skyLake      = 0x0010020A
    case palmCove     = 0x0010020B
    case sunnyCove    = 0x0010020C
    case willowCove   = 0x0010020D
    case goldenCove   = 0x0010020E
    case raptorCove   = 0x0010020F
    case redwoodCove  = 0x00100210
    case coyoteCove   = 0x00100211

    // MARK: - Intel Netburst

    case willamette   = 0x00100300
    case prescott     = 0x00100301

    // MARK: - Intel Atom

    case bonnell      = 0x00100400
    case saltwell     = 0x00100401
    case silvermont   = 0x00100402
    case airmont      = 0x00100403
    case goldmont     = 0x00100404
    case goldmontPlus = 0x00100405
    case tremont      = 0x00100406
    case gracemont    = 0x00100407
    case crestmont    = 0x00100408
    case darkmont     = 0x00100409

    // MARK: - Intel Knights

    case knightsFerry    = 0x00100500
    case knightsCorner   = 0x00100501
    case knightsLanding  = 0x00100502
    case knightsHill     = 0x00100503
    case knightsMill     = 0x00100504

    // MARK: - Intel XScale

    case xscale       = 0x00100600

    // MARK: - AMD

    case k5           = 0x00200100 // swiftlint:disable:this identifier_name
    case k6           = 0x00200101 // swiftlint:disable:this identifier_name
    case k7           = 0x00200102 // swiftlint:disable:this identifier_name
    case k8           = 0x00200103 // swiftlint:disable:this identifier_name
    case k10          = 0x00200104
    case bulldozer    = 0x00200105
    case piledriver   = 0x00200106
    case steamroller  = 0x00200107
    case excavator    = 0x00200108
    case zen          = 0x00200109
    case zen2         = 0x0020010A
    case zen3         = 0x0020010B
    case zen4         = 0x0020010C
    case zen5         = 0x0020010D
    case zen6         = 0x0020010E
    case oberon       = 0x0020010F
    case arden        = 0x00200110

    // MARK: - AMD Cats

    case geode        = 0x00200200
    case bobcat       = 0x00200201
    case jaguar       = 0x00200202
    case puma         = 0x00200203

    // MARK: - ARM

    case arm7         = 0x00300100
    case arm9         = 0x00300101
    case arm11        = 0x00300102

    // MARK: - ARM Cortex-A (32-bit)

    case cortexA5     = 0x00300205
    case cortexA7     = 0x00300207
    case cortexA8     = 0x00300208
    case cortexA9     = 0x00300209
    case cortexA12    = 0x00300212
    case cortexA15    = 0x00300215
    case cortexA17    = 0x00300217

    // MARK: - ARM Cortex-A (64-bit capable)

    case cortexA32    = 0x00300332
    case cortexA35    = 0x00300335
    case cortexA53    = 0x00300353
    case cortexA55r0  = 0x00300354
    case cortexA55    = 0x00300355
    case cortexA57    = 0x00300357
    case cortexA65    = 0x00300365
    case cortexA72    = 0x00300372
    case cortexA73    = 0x00300373
    case cortexA75    = 0x00300375
    case cortexA76    = 0x00300376
    case cortexA77    = 0x00300377
    case cortexA78    = 0x00300378

    // MARK: - ARM Neoverse

    case neoverseN1   = 0x00300400
    case neoverseE1   = 0x00300401
    case neoverseV1   = 0x00300402
    case neoverseN2   = 0x00300403
    case neoverseV2   = 0x00300404
    case neoverseV3   = 0x00300405

    // MARK: - ARM Cortex-X

    case cortexX1     = 0x00300501
    case cortexX2     = 0x00300502
    case cortexX3     = 0x00300503
    case cortexX4     = 0x00300504
    case cortexX925   = 0x00300505

    // MARK: - ARM Cortex (v9)

    case cortexA510   = 0x00300551
    case cortexA520   = 0x00300552
    case cortexA320   = 0x00300553
    case cortexA710   = 0x00300571
    case cortexA715   = 0x00300572
    case cortexA720   = 0x00300573
    case cortexA725   = 0x00300574

    // MARK: - ARM Lumex

    case lumexC1Ultra   = 0x00300600
    case lumexC1Premium = 0x00300601
    case lumexC1Pro     = 0x00300602
    case lumexC1Nano    = 0x00300603

    // MARK: - Qualcomm

    case scorpion     = 0x00400100
    case krait        = 0x00400101
    case kryo         = 0x00400102
    case falkor       = 0x00400103
    case saphira      = 0x00400104
    case oryon        = 0x00400105
    case oryonV3      = 0x00400106

    // MARK: - Nvidia

    case denver       = 0x00500100
    case denver2      = 0x00500101
    case carmel       = 0x00500102

    // MARK: - Samsung

    case exynosM1     = 0x00600100
    case exynosM2     = 0x00600101
    case exynosM3     = 0x00600102
    case exynosM4     = 0x00600103
    case exynosM5     = 0x00600104

    // MARK: - Apple

    case swift        = 0x00700100
    case cyclone      = 0x00700101
    case typhoon      = 0x00700102
    case twister      = 0x00700103
    case hurricane    = 0x00700104
    case monsoon      = 0x00700105
    case mistral      = 0x00700106
    case vortex       = 0x00700107
    case tempest      = 0x00700108
    case lightning    = 0x00700109
    case thunder      = 0x0070010A
    case firestorm    = 0x0070010B
    case icestorm     = 0x0070010C
    case avalanche    = 0x0070010D
    case blizzard     = 0x0070010E
    case everest      = 0x00700200
    case sawtooth     = 0x00700201
    case collEverest  = 0x00700202
    case collSawtooth = 0x00700203
    case tupaiEverest  = 0x00700204
    case tupaiSawtooth = 0x00700205
    case tahitiEverest  = 0x00700206
    case tahitiSawtooth = 0x00700207
    case tilosEverest   = 0x00700208
    case tilosSawtooth  = 0x00700209
    case donanEverest   = 0x00700308
    case donanSawtooth  = 0x00700309
    case sotraSuper       = 0x0070030A
    case sotraPerformance = 0x0070030B

    // MARK: - Cavium

    case thunderx     = 0x00800100
    case thunderx2    = 0x00800200

    // MARK: - Marvell

    case pj4          = 0x00900100

    // MARK: - Broadcom

    case brahmaB15    = 0x00A00100
    case brahmaB53    = 0x00A00101

    // MARK: - AppliedMicro

    case xgene        = 0x00B00100

    // MARK: - Hygon

    case dhyana        = 0x01000100

    // MARK: - HiSilicon

    case taishanV110   = 0x00C00100

    /// Decodes a raw value, mapping values this version does not know to ``unknown``.
    public init(from decoder: any Decoder) throws {
        self = Self(rawValue: try decoder.singleValueContainer().decode(UInt32.self)) ?? .unknown
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        // Intel Core
        case .p5:            "Intel P5 (Pentium)"
        case .quark:         "Intel Quark"
        case .p6:            "Intel P6 (Pentium Pro/II/III)"
        case .dothan:        "Intel Dothan (Pentium M)"
        case .yonah:         "Intel Yonah (Core Duo)"
        case .conroe:        "Intel Conroe (Core 2)"
        case .penryn:        "Intel Penryn (Core 2, 45nm)"
        case .nehalem:       "Intel Nehalem (1st gen Core)"
        case .sandyBridge:   "Intel Sandy Bridge (2nd gen Core)"
        case .ivyBridge:     "Intel Ivy Bridge (3rd gen Core)"
        case .haswell:       "Intel Haswell (4th gen Core)"
        case .broadwell:     "Intel Broadwell (5th gen Core)"
        case .skyLake:       "Intel Sky Lake / Kaby Lake (6th-8th gen)"
        case .palmCove:      "Intel Palm Cove (Cannon Lake)"
        case .sunnyCove:     "Intel Sunny Cove (Ice Lake)"
        case .willowCove:    "Intel Willow Cove (Tiger Lake)"
        case .goldenCove:    "Intel Golden Cove (Sapphire Rapids)"
        case .raptorCove:    "Intel Raptor Cove (Emerald Rapids)"
        case .redwoodCove:   "Intel Redwood Cove (Granite Rapids)"
        case .coyoteCove:    "Intel Coyote Cove (Nova Lake P-core)"

        // Intel Netburst
        case .willamette:    "Intel Willamette (Pentium 4)"
        case .prescott:      "Intel Prescott (Pentium 4, 90nm)"

        // Intel Atom
        case .bonnell:       "Intel Bonnell (Atom)"
        case .saltwell:      "Intel Saltwell (Atom, 32nm)"
        case .silvermont:    "Intel Silvermont (Atom, 22nm)"
        case .airmont:       "Intel Airmont (Atom, 14nm)"
        case .goldmont:      "Intel Goldmont (Atom)"
        case .goldmontPlus:  "Intel Goldmont Plus (Atom)"
        case .tremont:       "Intel Tremont (Atom)"
        case .gracemont:     "Intel Gracemont (E-core, 12th gen+)"
        case .crestmont:     "Intel Crestmont (E-core, 14th gen)"
        case .darkmont:      "Intel Darkmont (E-core)"

        // Intel Knights
        case .knightsFerry:    "Intel Knights Ferry (MIC)"
        case .knightsCorner:   "Intel Knights Corner (Xeon Phi)"
        case .knightsLanding:  "Intel Knights Landing (Xeon Phi x200)"
        case .knightsHill:     "Intel Knights Hill"
        case .knightsMill:     "Intel Knights Mill (Xeon Phi x205)"

        // Intel XScale
        case .xscale:         "Intel XScale (ARM)"

        // AMD
        case .k5:            "AMD K5"
        case .k6:            "AMD K6"
        case .k7:            "AMD K7 (Athlon)"
        case .k8:            "AMD K8 (Athlon 64 / Opteron)"
        case .k10:           "AMD K10 (Phenom / Barcelona)"
        case .bulldozer:     "AMD Bulldozer (15h)"
        case .piledriver:    "AMD Piledriver (15h, 2nd gen)"
        case .steamroller:   "AMD Steamroller (15h, 3rd gen)"
        case .excavator:     "AMD Excavator (15h, 4th gen)"
        case .zen:           "AMD Zen (Ryzen 1000 / EPYC Naples)"
        case .zen2:          "AMD Zen 2 (Ryzen 3000 / EPYC Rome)"
        case .zen3:          "AMD Zen 3 (Ryzen 5000 / EPYC Milan)"
        case .zen4:          "AMD Zen 4 (Ryzen 7000 / EPYC Genoa)"
        case .zen5:          "AMD Zen 5 (Ryzen 9000 / EPYC Turin)"
        case .zen6:          "AMD Zen 6"
        case .oberon:        "AMD Oberon (Zen 2, PlayStation 5 / 4700S)"
        case .arden:         "AMD Arden (Zen 2, Xbox Series X|S / 4800S)"
        case .geode:         "AMD Geode"
        case .bobcat:        "AMD Bobcat (14h)"
        case .jaguar:        "AMD Jaguar (16h)"
        case .puma:          "AMD Puma (16h, 2nd gen)"

        // ARM classic
        case .arm7:          "ARM7"
        case .arm9:          "ARM9"
        case .arm11:         "ARM11"

        // ARM Cortex-A 32-bit
        case .cortexA5:      "ARM Cortex-A5"
        case .cortexA7:      "ARM Cortex-A7"
        case .cortexA8:      "ARM Cortex-A8"
        case .cortexA9:      "ARM Cortex-A9"
        case .cortexA12:     "ARM Cortex-A12"
        case .cortexA15:     "ARM Cortex-A15"
        case .cortexA17:     "ARM Cortex-A17"

        // ARM Cortex-A 64-bit
        case .cortexA32:     "ARM Cortex-A32"
        case .cortexA35:     "ARM Cortex-A35"
        case .cortexA53:     "ARM Cortex-A53"
        case .cortexA55r0:   "ARM Cortex-A55 r0"
        case .cortexA55:     "ARM Cortex-A55"
        case .cortexA57:     "ARM Cortex-A57"
        case .cortexA65:     "ARM Cortex-A65"
        case .cortexA72:     "ARM Cortex-A72"
        case .cortexA73:     "ARM Cortex-A73"
        case .cortexA75:     "ARM Cortex-A75"
        case .cortexA76:     "ARM Cortex-A76"
        case .cortexA77:     "ARM Cortex-A77"
        case .cortexA78:     "ARM Cortex-A78"

        // ARM Neoverse
        case .neoverseN1:    "ARM Neoverse N1"
        case .neoverseE1:    "ARM Neoverse E1"
        case .neoverseV1:    "ARM Neoverse V1"
        case .neoverseN2:    "ARM Neoverse N2"
        case .neoverseV2:    "ARM Neoverse V2"
        case .neoverseV3:    "ARM Neoverse V3 / V3AE"

        // ARM Cortex-X
        case .cortexX1:      "ARM Cortex-X1"
        case .cortexX2:      "ARM Cortex-X2"
        case .cortexX3:      "ARM Cortex-X3"
        case .cortexX4:      "ARM Cortex-X4"
        case .cortexX925:    "ARM Cortex-X925"

        // ARM Cortex v9
        case .cortexA510:    "ARM Cortex-A510 (ARMv9)"
        case .cortexA520:    "ARM Cortex-A520 (ARMv9)"
        case .cortexA320:    "ARM Cortex-A320 (ARMv9)"
        case .cortexA710:    "ARM Cortex-A710 (ARMv9)"
        case .cortexA715:    "ARM Cortex-A715 (ARMv9)"
        case .cortexA720:    "ARM Cortex-A720 (ARMv9)"
        case .cortexA725:    "ARM Cortex-A725 (ARMv9)"

        // ARM Lumex
        case .lumexC1Ultra:   "ARM Lumex C1 Ultra"
        case .lumexC1Premium: "ARM Lumex C1 Premium"
        case .lumexC1Pro:     "ARM Lumex C1 Pro"
        case .lumexC1Nano:    "ARM Lumex C1 Nano"

        // Qualcomm
        case .scorpion:      "Qualcomm Scorpion"
        case .krait:         "Qualcomm Krait"
        case .kryo:          "Qualcomm Kryo"
        case .falkor:        "Qualcomm Falkor"
        case .saphira:       "Qualcomm Saphira"
        case .oryon:         "Qualcomm Oryon"
        case .oryonV3:       "Qualcomm Oryon V3"

        // Nvidia
        case .denver:        "Nvidia Denver"
        case .denver2:       "Nvidia Denver 2"
        case .carmel:        "Nvidia Carmel"

        // Samsung
        case .exynosM1:      "Samsung Exynos M1 (Mongoose)"
        case .exynosM2:      "Samsung Exynos M2 (Mongoose 2)"
        case .exynosM3:      "Samsung Exynos M3 (Meerkat)"
        case .exynosM4:      "Samsung Exynos M4 (Meerkat 2)"
        case .exynosM5:      "Samsung Exynos M5"

        // Apple
        case .swift:            "Apple Swift (A6)"
        case .cyclone:          "Apple Cyclone (A7)"
        case .typhoon:          "Apple Typhoon (A8)"
        case .twister:          "Apple Twister (A9)"
        case .hurricane:        "Apple Hurricane (A10 Fusion)"
        case .monsoon:          "Apple Monsoon (A11 P-core)"
        case .mistral:          "Apple Mistral (A11 E-core)"
        case .vortex:           "Apple Vortex (A12 P-core)"
        case .tempest:          "Apple Tempest (A12 E-core)"
        case .lightning:        "Apple Lightning (A13 P-core)"
        case .thunder:          "Apple Thunder (A13 E-core)"
        case .firestorm:        "Apple Firestorm (A14/M1 P-core)"
        case .icestorm:         "Apple Icestorm (A14/M1 E-core)"
        case .avalanche:        "Apple Avalanche (A15/M2 P-core)"
        case .blizzard:         "Apple Blizzard (A15/M2 E-core)"
        case .everest:          "Apple Everest (A16 P-core)"
        case .sawtooth:         "Apple Sawtooth (A16 E-core)"
        case .collEverest:      "Apple Coll Everest (A17/M3 P-core)"
        case .collSawtooth:     "Apple Coll Sawtooth (A17/M3 E-core)"
        case .tupaiEverest:     "Apple Tupai Everest (A18 P-core)"
        case .tupaiSawtooth:    "Apple Tupai Sawtooth (A18 E-core)"
        case .tahitiEverest:    "Apple Tahiti Everest (A18 Pro P-core)"
        case .tahitiSawtooth:   "Apple Tahiti Sawtooth (A18 Pro E-core)"
        case .tilosEverest:     "Apple Tilos Everest (A19/M5 P-core)"
        case .tilosSawtooth:    "Apple Tilos Sawtooth (A19/M5 E-core)"
        case .donanEverest:     "Apple Donan Everest (M4 P-core)"
        case .donanSawtooth:    "Apple Donan Sawtooth (M4 E-core)"
        case .sotraSuper:       "Apple Sotra Super (M5 Pro/Max super core)"
        case .sotraPerformance: "Apple Sotra Performance (M5 Pro/Max performance core)"

        // Cavium
        case .thunderx:      "Cavium ThunderX"
        case .thunderx2:     "Cavium ThunderX2"

        // Marvell
        case .pj4:           "Marvell PJ4 (Sheeva)"

        // Broadcom
        case .brahmaB15:     "Broadcom Brahma B15"
        case .brahmaB53:     "Broadcom Brahma B53"

        // AppliedMicro
        case .xgene:         "AppliedMicro X-Gene"

        // Hygon
        case .dhyana:        "Hygon Dhyana (Zen-based)"

        // HiSilicon
        case .taishanV110:   "HiSilicon TaiShan v110 (Kunpeng 920)"

        case .unknown:       "Unknown"
        @unknown default:    "Unknown (0x\(String(rawValue, radix: 16)))"
        }
    }
}
// swiftlint:enable type_body_length
