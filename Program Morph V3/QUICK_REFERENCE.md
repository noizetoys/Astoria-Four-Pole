# Morphing Quick Reference Card

## 🚀 Quick Start (Copy-Paste Ready)

```swift
// RECOMMENDED: Production-ready with full control
let morph = ProgramMorphFiltered(
    source: sourceProgram,
    destination: destinationProgram,
    config: .allParameters
)

morph.startMorph()  // 2-second morph by default
```

## 📋 Three Implementations

| Use | File | One-Line Description |
|-----|------|---------------------|
| **Learning** | ProgramMorph.swift | Simple, no optimization |
| **Performance** | ProgramMorphOptimized.swift | 60-90% fewer messages |
| **Production** ⭐ | ProgramMorphFiltered.swift | Full control + optimization |

## ⚙️ Configuration Presets

```swift
// Everything (default)
.allParameters

// Just envelopes
.envelopesOnly           // VCF + VCA ADSR

// Just filters
.filtersOnly             // Cutoff, resonance + mod

// VCF chain
.vcfOnly                 // Filter envelope + cutoff + resonance + mod

// VCA chain
.vcaOnly                 // Amp envelope + volume + panning + mod

// Modulation only
.modulationOnly          // LFO + all mod amounts
```

## 🎛️ Common Usage Patterns

```swift
// Filter sweep (3-4 params)
let config = MorphFilterConfig.filtersOnly
let morph = ProgramMorphFiltered(source: closed, destination: open, config: config)
morph.morphDuration = 4.0
morph.startMorph()

// Envelope morph (10 params)
let morph = ProgramMorphFiltered(source: pluck, destination: pad, config: .envelopesOnly)
morph.startMorph()

// Full patch morph (all params)
let morph = ProgramMorphFiltered(source: ambient, destination: aggressive)
morph.startMorph()

// Manual control
morph.setMorphPosition(0.5)  // Jump to 50%

// Ping-pong
morph.startMorph(to: 1.0)
// ... then later ...
morph.startMorph(to: 0.0)
```

## 🔧 Parameter Groups

```swift
.vcfEnvelope       // Filter ADSR + cutoff amount
.vcaEnvelope       // Amp ADSR + volume amount
.vcfModulation     // Cutoff/resonance mod amounts
.vcaModulation     // Volume/panning mod amounts
.lfo               // LFO speed + speed mod
.filters           // Cutoff + resonance
.output            // Volume + panning
.timing            // Gate time
```

## 🎯 Enable/Disable Groups

```swift
// Enable specific groups
let config = MorphFilterConfig()
config.enabledGroups = [.vcfEnvelope, .filters]

// Disable one group
config.enabledGroups.remove(.lfo)

// Disable specific parameter
config.disabledParameters.insert(.cutoff)

// Force enable specific parameter
config.forceEnabledParameters.insert(.resonance)
```

## 🔀 Discrete Parameter Strategies

```swift
.ignore              // Don't change (DEFAULT)
.snapAtHalf          // Switch at 50%
.snapAtThreshold     // Switch at custom %
.useSource           // Keep source value
.useDestination      // Jump to dest immediately

// Apply strategy
config.modulationSourceStrategy = .snapAtHalf
config.discreteSnapThreshold = 0.75

// Include optional discrete params
config.includeLFOShape = true
config.includeTriggerSource = false  // Usually keep false
config.includeTriggerMode = false    // Usually keep false
```

## 📊 Statistics

```swift
// Check what's being morphed
print(morph.stats.description)
// Output:
// - Total Parameters: 29
// - Continuous: 26
// - Discrete: 3
// - Unchanged: 17
// - Messages Sent: 1,234
// - Messages Saved: 567

// List morphing parameters
print(morph.morphingParameterNames)
// ["vcfEnvelopeAttack", "cutoff", ...]

// List only changing parameters
print(morph.changingParameterNames)
// ["cutoff", "resonance", ...]
```

## 🎨 UI Components

```swift
// Basic control
MorphControlView(morph: morph)

// Advanced with visualization
AdvancedMorphView(morph: morph)

// With filter configuration
MorphFilterControlView(morph: morph)

// Complete solution
CompleteMorphView(morph: morph)
```

## ⏱️ Timing Control

```swift
morph.morphDuration = 4.0    // 4 seconds
morph.updateRate = 30.0       // 30 Hz (default)
morph.sendCCMessages = true   // Enable/disable CC sending

// Check status
if morph.isAutoMorphing {
    morph.stopMorph()
}
```

## 🎹 Integration with MIDI

```swift
// In your MIDI manager
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleMorphUpdate),
    name: .programParameterUpdated,
    object: nil
)

@objc func handleMorphUpdate(_ notification: Notification) {
    guard let type = notification.userInfo?[SysExConstant.parameterType] as? MiniWorksParameter,
          let value = notification.userInfo?[SysExConstant.parameterValue] as? UInt8 else {
        return
    }
    
    sendCC(cc: type.ccValue, value: value, channel: deviceChannel)
}
```

## ✅ What Gets Morphed (Default)

```
✅ VCF Envelope: Attack, Decay, Sustain, Release
✅ VCA Envelope: Attack, Decay, Sustain, Release
✅ Envelope Amounts: Cutoff amount, Volume amount
✅ Filters: Cutoff, Resonance
✅ Modulation Amounts: All mod depths (cutoff, resonance, volume, panning)
✅ LFO: Speed, Speed modulation amount
✅ Output: Volume, Panning
✅ Timing: Gate time

❌ Modulation Sources: .off, .lfo, .envelope (discrete - excluded)
❌ LFO Shape: .sine, .square, etc. (discrete - excluded)
❌ Trigger Source: .audio, .midi (discrete - excluded)
❌ Trigger Mode: .single, .multi (discrete - excluded)
```

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Parameter not morphing | Check if group enabled, not in disabledParameters |
| Too many MIDI messages | Use Optimized/Filtered, reduce updateRate, use groups |
| Discrete params changing | Check includeLFOShape flags, check strategy |
| UI not updating | Ensure @Observable/@Bindable correctly used |
| Morph seems choppy | Increase updateRate (try 40-60 Hz) |

## 📈 Performance Numbers

```
Simple morph (3 params):
- Basic:     870 msgs/sec → 90 msgs/sec (90% reduction)
- Optimized: 90 msgs/sec
- Filtered:  90 msgs/sec

Medium morph (10 params):
- Basic:     870 msgs/sec → 300 msgs/sec (65% reduction)
- Optimized: 300 msgs/sec
- Filtered:  300 msgs/sec

Full morph (29 params):
- Basic:     870 msgs/sec
- Optimized: 870 msgs/sec (no reduction possible)
- Filtered:  870 msgs/sec
```

## 🎯 Recommendations

| Scenario | Use This |
|----------|----------|
| Production app | ProgramMorphFiltered ⭐ |
| Learning/prototyping | ProgramMorph |
| Performance critical | ProgramMorphOptimized |
| User needs control | ProgramMorphFiltered |
| iOS app | ProgramMorphFiltered |
| Simple utility | ProgramMorph |

## 📚 File Guide

```
Core:
├─ ProgramMorph.swift              (basic)
├─ ProgramMorphOptimized.swift     (performance)
└─ ProgramMorphFiltered.swift      (production ⭐)

Configuration:
└─ MorphParameterControl.swift     (groups, strategies)

UI:
├─ MorphControlView.swift          (basic UI)
├─ AdvancedMorphView.swift         (advanced UI)
└─ MorphFilterControlView.swift    (filter config UI)

Docs:
├─ README.md                       (overview)
├─ IMPLEMENTATION_SUMMARY.md       (this comparison)
├─ APPROACHES_COMPARISON.md        (8 approaches)
├─ OPTIMIZATION_ANALYSIS.md        (performance)
├─ DISCRETE_PARAMETERS_GUIDE.md    (discrete handling)
└─ QUICK_REFERENCE.md              (this file)

Examples:
└─ MorphUsageExamples.swift        (complete examples)
```

## 💡 Pro Tips

1. **Start with presets**: Use `.filtersOnly`, `.envelopesOnly` etc.
2. **Group your morphs**: Don't morph everything unless you need to
3. **Avoid discrete params**: Keep defaults (excluded)
4. **Use 30 Hz**: Sweet spot for MIDI bandwidth
5. **Check statistics**: See what's actually changing
6. **Test your morphs**: What sounds good > what's theoretically correct
7. **Use Filtered version**: Best overall choice for production

## 🚦 Decision Tree

```
Need parameter control? 
├─ YES → ProgramMorphFiltered ⭐
└─ NO
   └─ Need optimization?
      ├─ YES → ProgramMorphOptimized
      └─ NO → ProgramMorph (basic)
```

## 📞 Quick Help

```swift
// Stopped responding?
morph.stopMorph()

// Reset everything
morph.resetToSource()
morph.filterConfig = .allParameters

// See what's happening
print(morph.configurationReport)
```

---

**Remember**: When in doubt, use `ProgramMorphFiltered` with default settings. It's optimized, flexible, and production-ready out of the box! 🎉
