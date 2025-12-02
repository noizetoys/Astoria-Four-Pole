# SwiftUI Custom Bindings Cheatsheet

## Overview

Bindings enable two-way data flow in SwiftUI. Custom bindings allow you to intercept, transform, or compute values while maintaining the binding contract. This is essential for computed properties, validation, formatting, and complex state management.

---

## Binding Fundamentals

### What is a Binding?

```swift
struct Binding<Value> {
    var wrappedValue: Value { get nonmutating set }
    
    init(get: @escaping () -> Value, set: @escaping (Value) -> Void)
}

// A binding is a reference to a value elsewhere
// - get: Returns the current value
// - set: Updates the value
```

### Basic Usage

```swift
struct ParentView: View {
    @State private var text = ""
    
    var body: some View {
        // Pass binding with $
        TextField("Enter text", text: $text)
        
        // $text creates Binding<String>
        // Changes flow bidirectionally
    }
}
```

---

## Creating Custom Bindings

### 1. Basic Custom Binding

```swift
struct ContentView: View {
    @State private var value: Double = 0
    
    // Custom binding with transformation
    var percentageBinding: Binding<Double> {
        Binding(
            get: { value * 100 },
            set: { value = $0 / 100 }
        )
    }
    
    var body: some View {
        VStack {
            Text("Value: \(value, specifier: "%.2f")")
            Text("Percentage: \(value * 100, specifier: "%.0f")%")
            
            Slider(value: percentageBinding, in: 0...100)
        }
    }
}
```

### 2. Computed Binding with Validation

```swift
struct ValidatedTextField: View {
    @State private var text = ""
    
    var validatedBinding: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                // Only allow alphanumeric
                let filtered = newValue.filter { $0.isLetter || $0.isNumber }
                text = filtered
            }
        )
    }
    
    var body: some View {
        TextField("Username", text: validatedBinding)
    }
}
```

### 3. Bidirectional Format Conversion

```swift
struct TemperatureConverter: View {
    @State private var celsius: Double = 0
    
    var fahrenheitBinding: Binding<Double> {
        Binding(
            get: {
                celsius * 9/5 + 32
            },
            set: { fahrenheit in
                celsius = (fahrenheit - 32) * 5/9
            }
        )
    }
    
    var body: some View {
        Form {
            Section("Celsius") {
                TextField("°C", value: $celsius, format: .number)
            }
            
            Section("Fahrenheit") {
                TextField("°F", value: fahrenheitBinding, format: .number)
            }
        }
    }
}
```

---

## Binding Transformations

### String to Number Binding

```swift
struct StringToNumberBinding: View {
    @State private var number: Int = 0
    
    var stringBinding: Binding<String> {
        Binding(
            get: { String(number) },
            set: { newValue in
                if let value = Int(newValue) {
                    number = value
                }
            }
        )
    }
    
    var body: some View {
        TextField("Enter number", text: stringBinding)
            .keyboardType(.numberPad)
    }
}
```

### Optional Unwrapping Binding

```swift
struct OptionalBinding: View {
    @State private var optionalText: String?
    
    var unwrappedBinding: Binding<String> {
        Binding(
            get: { optionalText ?? "" },
            set: { newValue in
                optionalText = newValue.isEmpty ? nil : newValue
            }
        )
    }
    
    var body: some View {
        TextField("Optional text", text: unwrappedBinding)
    }
}
```

### Array Element Binding

```swift
struct ArrayElementBinding: View {
    @State private var items = ["A", "B", "C"]
    
    func binding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < items.count else { return "" }
                return items[index]
            },
            set: { newValue in
                guard index < items.count else { return }
                items[index] = newValue
            }
        )
    }
    
    var body: some View {
        List {
            ForEach(items.indices, id: \.self) { index in
                TextField("Item \(index)", text: binding(for: index))
            }
        }
    }
}
```

### Dictionary Value Binding

```swift
struct DictionaryBinding: View {
    @State private var settings: [String: Bool] = [
        "notifications": true,
        "darkMode": false
    ]
    
    func binding(for key: String) -> Binding<Bool> {
        Binding(
            get: { settings[key] ?? false },
            set: { settings[key] = $0 }
        )
    }
    
    var body: some View {
        Form {
            Toggle("Notifications", isOn: binding(for: "notifications"))
            Toggle("Dark Mode", isOn: binding(for: "darkMode"))
        }
    }
}
```

---

## Practical Binding Patterns

### 1. Debounced Binding

```swift
class DebouncedState: ObservableObject {
    @Published var searchText = ""
    @Published var debouncedText = ""
    
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .assign(to: \.debouncedText, on: self)
    }
}

struct DebouncedSearchView: View {
    @StateObject private var state = DebouncedState()
    
    var body: some View {
        VStack {
            TextField("Search", text: $state.searchText)
            Text("Debounced: \(state.debouncedText)")
        }
    }
}
```

### 2. Uppercase Binding

```swift
extension Binding where Value == String {
    var uppercase: Binding<String> {
        Binding(
            get: { wrappedValue.uppercased() },
            set: { wrappedValue = $0.uppercased() }
        )
    }
}

struct UppercaseTextField: View {
    @State private var text = ""
    
    var body: some View {
        TextField("Enter text", text: $text.uppercase)
    }
}
```

### 3. Clamped Binding

```swift
extension Binding where Value == Int {
    func clamped(to range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}

struct ClampedSlider: View {
    @State private var value = 50
    
    var body: some View {
        VStack {
            Text("Value: \(value)")
            Slider(value: $value.clamped(to: 0...100).doubleValue, in: 0...100)
        }
    }
}

extension Binding where Value == Int {
    var doubleValue: Binding<Double> {
        Binding<Double>(
            get: { Double(wrappedValue) },
            set: { wrappedValue = Int($0) }
        )
    }
}
```

### 4. Animated Binding

```swift
extension Binding {
    func animated(_ animation: Animation = .default) -> Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { newValue in
                withAnimation(animation) {
                    wrappedValue = newValue
                }
            }
        )
    }
}

struct AnimatedToggle: View {
    @State private var isOn = false
    
    var body: some View {
        Toggle("Animated", isOn: $isOn.animated(.spring()))
    }
}
```

### 5. Logged Binding

```swift
extension Binding {
    func logged(_ prefix: String = "") -> Binding<Value> {
        Binding(
            get: {
                print("\(prefix) Get: \(wrappedValue)")
                return wrappedValue
            },
            set: { newValue in
                print("\(prefix) Set: \(newValue)")
                wrappedValue = newValue
            }
        )
    }
}

struct LoggedView: View {
    @State private var text = ""
    
    var body: some View {
        TextField("Text", text: $text.logged("TextField"))
    }
}
```

---

## Advanced Binding Techniques

### 1. Proxy Pattern

```swift
@propertyWrapper
struct Proxied<Value> {
    private var value: Value
    var onChange: ((Value) -> Void)?
    
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            onChange?(newValue)
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { value },
            set: { newValue in
                value = newValue
                onChange?(newValue)
            }
        )
    }
}

struct ProxiedView: View {
    @Proxied var count = 0
    
    init() {
        _count.onChange = { newValue in
            print("Count changed to \(newValue)")
        }
    }
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1
            }
            Slider(value: $count.intToDouble, in: 0...100)
        }
    }
}

extension Binding where Value == Int {
    var intToDouble: Binding<Double> {
        Binding<Double>(
            get: { Double(wrappedValue) },
            set: { wrappedValue = Int($0) }
        )
    }
}
```

### 2. Coalescing Nil Values

```swift
extension Binding {
    func coalesce<T>(_ defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { wrappedValue ?? defaultValue },
            set: { wrappedValue = $0 }
        )
    }
}

struct CoalescingView: View {
    @State private var optionalText: String? = nil
    
    var body: some View {
        TextField("Text", text: $optionalText.coalesce(""))
    }
}
```

### 3. Mapping Bindings

```swift
extension Binding {
    func map<T>(
        get: @escaping (Value) -> T,
        set: @escaping (T) -> Value
    ) -> Binding<T> {
        Binding<T>(
            get: { get(wrappedValue) },
            set: { wrappedValue = set($0) }
        )
    }
}

struct MappedBinding: View {
    @State private var date = Date()
    
    var yearBinding: Binding<Int> {
        $date.map(
            get: { Calendar.current.component(.year, from: $0) },
            set: { year in
                var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                components.year = year
                return Calendar.current.date(from: components) ?? date
            }
        )
    }
    
    var body: some View {
        Stepper("Year: \(Calendar.current.component(.year, from: date))", 
                value: yearBinding, 
                in: 2000...2100)
    }
}
```

### 4. Conditional Binding

```swift
extension Binding {
    func when(_ condition: @escaping (Value) -> Bool) -> Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { newValue in
                if condition(newValue) {
                    wrappedValue = newValue
                }
            }
        )
    }
}

struct ConditionalBinding: View {
    @State private var value = 50
    
    var body: some View {
        Slider(
            value: $value
                .doubleValue
                .when { $0 >= 0 && $0 <= 100 },
            in: 0...100
        )
    }
}
```

---

## Observable Object Bindings

### 1. Published Property Binding

```swift
@Observable
class ViewModel {
    var username = ""
    var age: Int = 0
    var isEnabled = false
}

struct ObservableBinding: View {
    @Bindable var viewModel: ViewModel
    
    var body: some View {
        Form {
            TextField("Username", text: $viewModel.username)
            Stepper("Age: \(viewModel.age)", value: $viewModel.age)
            Toggle("Enabled", isOn: $viewModel.isEnabled)
        }
    }
}
```

### 2. Nested Property Binding

```swift
@Observable
class User {
    var profile = Profile()
}

@Observable
class Profile {
    var name = ""
    var email = ""
}

struct NestedBinding: View {
    @Bindable var user: User
    
    var body: some View {
        Form {
            TextField("Name", text: $user.profile.name)
            TextField("Email", text: $user.profile.email)
        }
    }
}
```

### 3. Custom Getter/Setter for Observable

```swift
@Observable
class Settings {
    private var _volume: Double = 0.5
    
    var volume: Double {
        get { _volume }
        set { _volume = max(0, min(1, newValue)) }  // Clamp
    }
}

struct SettingsView: View {
    @Bindable var settings: Settings
    
    var body: some View {
        Slider(value: $settings.volume, in: 0...1)
    }
}
```

---

## Complex Binding Examples

### 1. Multi-Field Validation

```swift
struct SignupForm: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var passwordMatchBinding: Binding<String> {
        Binding(
            get: { confirmPassword },
            set: { newValue in
                confirmPassword = newValue
                validatePasswordMatch()
            }
        )
    }
    
    @State private var passwordsMatch = true
    
    func validatePasswordMatch() {
        passwordsMatch = password == confirmPassword
    }
    
    var body: some View {
        Form {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            SecureField("Confirm Password", text: passwordMatchBinding)
            
            if !passwordsMatch {
                Text("Passwords don't match")
                    .foregroundColor(.red)
            }
        }
    }
}
```

### 2. Format Preserving Binding

```swift
struct PhoneNumberField: View {
    @State private var phoneNumber = ""
    
    var formattedBinding: Binding<String> {
        Binding(
            get: { formatPhoneNumber(phoneNumber) },
            set: { newValue in
                phoneNumber = newValue.filter { $0.isNumber }
            }
        )
    }
    
    func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.filter { $0.isNumber }
        
        guard !cleaned.isEmpty else { return "" }
        
        var result = ""
        let mask = "(XXX) XXX-XXXX"
        var index = cleaned.startIndex
        
        for ch in mask where index < cleaned.endIndex {
            if ch == "X" {
                result.append(cleaned[index])
                index = cleaned.index(after: index)
            } else {
                result.append(ch)
            }
        }
        
        return result
    }
    
    var body: some View {
        TextField("Phone", text: formattedBinding)
            .keyboardType(.numberPad)
    }
}
```

### 3. Multi-Source Binding

```swift
struct MultiSourceBinding: View {
    @State private var useMetric = true
    @State private var centimeters: Double = 0
    @State private var inches: Double = 0
    
    var displayBinding: Binding<Double> {
        Binding(
            get: { useMetric ? centimeters : inches },
            set: { newValue in
                if useMetric {
                    centimeters = newValue
                    inches = newValue / 2.54
                } else {
                    inches = newValue
                    centimeters = newValue * 2.54
                }
            }
        )
    }
    
    var body: some View {
        VStack {
            Picker("Unit", selection: $useMetric) {
                Text("Metric").tag(true)
                Text("Imperial").tag(false)
            }
            .pickerStyle(.segmented)
            
            TextField(
                useMetric ? "Centimeters" : "Inches",
                value: displayBinding,
                format: .number
            )
            
            Text("= \(useMetric ? inches : centimeters, specifier: "%.2f") \(useMetric ? "in" : "cm")")
        }
    }
}
```

### 4. Aggregate Binding

```swift
struct Color {
    var red: Double
    var green: Double
    var blue: Double
}

struct ColorPicker: View {
    @State private var color = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    func componentBinding(_ keyPath: WritableKeyPath<Color, Double>) -> Binding<Double> {
        Binding(
            get: { color[keyPath: keyPath] },
            set: { color[keyPath: keyPath] = $0 }
        )
    }
    
    var body: some View {
        VStack {
            Slider(value: componentBinding(\.red), in: 0...1)
                .accentColor(.red)
            Slider(value: componentBinding(\.green), in: 0...1)
                .accentColor(.green)
            Slider(value: componentBinding(\.blue), in: 0...1)
                .accentColor(.blue)
            
            Rectangle()
                .fill(SwiftUI.Color(
                    red: color.red,
                    green: color.green,
                    blue: color.blue
                ))
                .frame(height: 100)
        }
    }
}
```

---

## Constant Bindings

### Creating Read-Only Bindings

```swift
struct ConstantBindingExample: View {
    var body: some View {
        VStack {
            // Read-only binding
            TextField("Constant", text: .constant("Cannot change"))
                .disabled(true)
            
            // For preview/testing
            Toggle("Always On", isOn: .constant(true))
                .disabled(true)
        }
    }
}
```

---

## Binding to UserDefaults

### AppStorage Binding

```swift
struct SettingsView: View {
    @AppStorage("username") private var username = ""
    @AppStorage("darkMode") private var darkMode = false
    
    var body: some View {
        Form {
            TextField("Username", text: $username)
            Toggle("Dark Mode", isOn: $darkMode)
        }
    }
}
```

### Custom UserDefaults Binding

```swift
extension Binding where Value == Bool {
    static func userDefaults(_ key: String, defaultValue: Bool = false) -> Binding<Bool> {
        Binding(
            get: { UserDefaults.standard.bool(forKey: key) },
            set: { UserDefaults.standard.set($0, forKey: key) }
        )
    }
}

struct CustomDefaultsBinding: View {
    @State private var setting = Binding<Bool>.userDefaults("mySetting")
    
    var body: some View {
        Toggle("Setting", isOn: setting)
    }
}
```

---

## Testing with Bindings

### Mock Binding for Previews

```swift
struct ContentView: View {
    @Binding var value: Int
    
    var body: some View {
        Stepper("Value: \(value)", value: $value)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Create temporary state for preview
        ContentView(value: .constant(5))
    }
}
```

### Stateful Preview

```swift
struct StatefulPreview: View {
    @State private var value = 5
    
    var body: some View {
        ContentView(value: $value)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreview()
    }
}
```

---

## Performance Considerations

### 1. Avoid Expensive Get Operations

```swift
// Bad: Expensive operation on every get
var badBinding: Binding<String> {
    Binding(
        get: { expensiveComputation() },  // Called frequently!
        set: { value = $0 }
    )
}

// Good: Cache result
@State private var cachedValue = ""

var goodBinding: Binding<String> {
    Binding(
        get: { cachedValue },
        set: { newValue in
            cachedValue = newValue
            updateBackingStore(newValue)
        }
    )
}
```

### 2. Minimize Binding Creation

```swift
// Bad: Creates new binding on every body evaluation
var body: some View {
    TextField("Text", text: Binding(
        get: { value },
        set: { value = $0 }
    ))
}

// Good: Computed property (still cached by SwiftUI)
var valueBinding: Binding<String> {
    Binding(
        get: { value },
        set: { value = $0 }
    )
}

var body: some View {
    TextField("Text", text: valueBinding)
}
```

---

## Common Patterns Reference

```swift
// 1. Transform on set
Binding(
    get: { value },
    set: { value = transform($0) }
)

// 2. Bidirectional conversion
Binding(
    get: { convertToDisplay(value) },
    set: { value = convertFromDisplay($0) }
)

// 3. Validation
Binding(
    get: { value },
    set: { if validate($0) { value = $0 } }
)

// 4. Side effect
Binding(
    get: { value },
    set: {
        value = $0
        performSideEffect($0)
    }
)

// 5. Conditional update
Binding(
    get: { value },
    set: { if condition { value = $0 } }
)

// 6. Clamping
Binding(
    get: { value },
    set: { value = clamp($0, min, max) }
)

// 7. Debouncing (via observable object)
@Published var immediate = ""
@Published var debounced = ""

// 8. Logging
Binding(
    get: { 
        print("Get: \(value)")
        return value 
    },
    set: {
        print("Set: \($0)")
        value = $0
    }
)
```

---

## Best Practices

1. **Keep bindings simple** - Complex logic should be in view models
2. **Cache expensive computations** - Don't compute on every get
3. **Validate in set** - Ensure data integrity
4. **Use extensions** - Create reusable binding transformations
5. **Test edge cases** - Nil values, empty strings, boundary conditions
6. **Document custom bindings** - Explain transformation behavior
7. **Consider using @Observable** - Simpler for iOS 17+
8. **Avoid unnecessary binding creation** - Computed properties are fine

---

## Additional Resources

- [Binding Documentation](https://developer.apple.com/documentation/swiftui/binding)
- [Data Essentials in SwiftUI (WWDC)](https://developer.apple.com/videos/play/wwdc2020/10040/)
- [SwiftUI Property Wrappers](https://www.hackingwithswift.com/quick-start/swiftui/all-swiftui-property-wrappers-explained-and-compared)
