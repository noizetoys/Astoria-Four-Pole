\
import Foundation
import _Concurrency

// Playground: Task Examples
print("Playground starting")

// Example A: Basic Task + cancellation
let t1 = Task {
    for i in 1...10 {
        try Task.checkCancellation()
        print("t1 tick", i)
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    print("t1 done")
}

Task.detached {
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    t1.cancel()
    print("t1 cancel requested")
}

// Example B: async let
func fetchA() async -> String {
    try? await Task.sleep(nanoseconds: 500_000_000)
    return "A"
}
func fetchB() async -> String {
    try? await Task.sleep(nanoseconds: 700_000_000)
    return "B"
}

Task {
    async let a = fetchA()
    async let b = fetchB()
    let (ra, rb) = await (a, b)
    print("async let results:", ra, rb)
}

// Example C: withTaskGroup
func compute(_ n: Int) async -> Int {
    try? await Task.sleep(nanoseconds: UInt64(100_000_000 + (n * 10_000_000)))
    return n * n
}

Task {
    await withTaskGroup(of: Int.self) { group in
        for i in 1...6 {
            group.addTask { await compute(i) }
        }
        var results: [Int] = []
        for await r in group {
            results.append(r)
            print("group completed", r)
        }
        print("group all:", results)
    }
}

// Example D: Actor + main-actor UI update simulation
actor Counter {
    private var value = 0
    func increment() { value += 1 }
    func read() -> Int { value }
}

let counter = Counter()

Task.detached {
    await counter.increment()
    let v = await counter.read()
    print("counter value (detached):", v)
}

// Let the playground run a bit
try? Task.sleep(nanoseconds: 3_000_000_000)
print("Playground finished")
