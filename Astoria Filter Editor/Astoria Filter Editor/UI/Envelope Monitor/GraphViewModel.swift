//
//  GraphViewModel.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/21/25.
//
import Combine
import Foundation


    // MARK: - Graph View Model

/**
 * GraphViewModel - Manages the scrolling graph data and timing
 *
 * Responsibilities:
 * 1. Maintains an array of DataPoint objects for the graph
 * 2. Runs a timer that samples MIDI values at regular intervals
 * 3. Detects note events and marks the EXACT point where they occur
 * 4. Manages the scrolling behavior (adding/removing data points)
 *
 * How Note Display Works:
 * 1. When a note event occurs (noteValue changes), we mark THAT SPECIFIC point
 * 2. Only the data point at that moment gets hasNote=true with the velocity
 * 3. Subsequent points do NOT show the note marker unless another note occurs
 * 4. This creates a single dot (or pair of dots) at each note event
 *
 * Key Settings:
 * - maxDataPoints: Maximum number of points to keep (older points are removed)
 * - Timer interval: 0.05 seconds (50ms) = 20 updates per second
 *
 * Usage:
 * 1. Create: let viewModel = GraphViewModel()
 * 2. Start: viewModel.start(midiManager: midiManager)
 * 3. Observe: @ObservedObject var viewModel: GraphViewModel
 * 4. Stop: viewModel.stop() (called automatically on deinit)
 */
@MainActor
class GraphViewModel: ObservableObject {
        // MARK: Published Properties
    
        /// Array of data points displayed on the graph
        /// Newest points are at the end, oldest at the beginning
    @Published var dataPoints: [DataPoint] = []
    
        // MARK: Configuration
    
        /// Maximum number of data points to keep in memory
        /// When exceeded, oldest points are removed (creating the scrolling effect)
        /// Default: 200 points ≈ 10 seconds of data at 20 Hz
    private let maxDataPoints = 200
    
        // MARK: Private State
    
        /// Timer that triggers data sampling
    private var timer: Timer?
    
        /// Last recorded note velocity value
        /// Used to detect when the note value changes
    private var lastNoteValue: UInt8 = 0
    
        // MARK: Start/Stop
    
    /**
     * Starts the graph data collection.
     *
     * Parameters:
     * - midiManager: The MIDIManager to observe for CC and note values
     *
     * This method:
     * 1. Creates a repeating timer (50ms interval = 20 Hz)
     * 2. On each tick, samples the current CC and note values
     * 3. Detects note events (when noteValue changes)
     * 4. Creates DataPoint objects - ONLY the point where the note changed has the marker
     * 5. Manages the dataPoints array (adding new, removing old)
     *
     * The timer captures weak references to prevent retain cycles.
     */
    
    private var ccListenerTask: Task<Void, Never>?
    private var noteListenerTask: Task<Void, Never>?
    private var timerListenerTask: Task<Void, Never>?

    @Published var ccValue: UInt8 = 0
    @Published var noteValue: UInt8 = 0
    
    private var midiService: MIDIService = .shared
    private var config: MiniworksDeviceProfile
    
    private var cancellables = Set<AnyCancellable>()
    
    
    init(configuration: MiniworksDeviceProfile ) {
        debugPrint(message: "Creating with \(configuration)")
        
        self.config = configuration
        
        // Publisher way
        NotificationCenter.default.publisher(for: .midiSourceConnected)
            .sink { [weak self] _ in
                debugPrint(icon: "📡", message: "Notification Recieved:  midiSourceConnected")
                Task {
                    await self?.start()
                }
            }
            .store(in: &cancellables)
    }
    
    
    func start() async {
        guard
            let source = await midiService.availableSources().first
        else {
            debugPrint(icon: "🔥🔥❌", message: "Source is nil...Cannot connect")
            return
        }
        
        print("📊 Starting graph data collection (20 Hz)")
        print("   - Max data points: \(maxDataPoints)")
//        print("   - Note markers: Only at exact moment of note event")
        
        ccListenerTask = createCCListener(source: source)
        
        noteListenerTask = createNoteListener(source: source)
        
        timer = createTimer(source: source, velocity: nil, note: nil)
        
    }
    
    
    private func createCCListener(source: MIDIDevice) -> Task<Void, Never> {
        Task { [weak self] in
            guard
                let self
            else { return }
            
            for await ccData in await self.midiService.ccStream(from: source) {
                if Task.isCancelled { break }
                
                guard
                    ccData.cc == ContinuousController.breathControl
                        //                    ccData.channel == config.midiChannel
                else {
                        // ✅ Use continue instead of return to skip this CC but keep processing
                    continue
                }
                
                self.ccValue = ccData.value
            }
        }
        
    }
    
    
    private func createNoteListener(source: MIDIDevice) -> Task<Void, Never> {
        Task { [weak self] in
            guard
                let self
            else { return }
            
            for await note in await self.midiService.noteStream(from: source) {
                if Task.isCancelled { break }
                    //                guard
                    //                    note.channel == config.midiChannel,
                    //                    note.note == config.noteNumber
                    //                else {
                    //                    // ✅ Use continue instead of return to skip this note but keep processing
                    //                    continue
                    //                }
                    //
                    // ✅ Store velocity, not note number (note number is constant per your filter)
                self.noteValue = note.velocity
            }
        }

    }
    
    
    private func createTimer(source: MIDIDevice, velocity: UInt8?, note: UInt8?) -> Timer {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            
            // Hop to the main actor before touching actor-isolated state
//            Task { @MainActor [weak self] in
                guard let self else { return }
                
                // Cancel any in-flight timer listener task before starting a new one
                self.timerListenerTask?.cancel()
                
                self.timerListenerTask = Task { [weak self] in
                    guard let self else { return }
                    await self.updateTimer()
                }
//            }
        }
    }
    
    
    @MainActor
    private func updateTimer() async {
        guard !Task.isCancelled else { return }
        
            // Sample current values from MIDI manager
        let ccVal = CGFloat(self.ccValue)
        let currentNoteValue = self.noteValue
        
            // CRITICAL: Only mark THIS point if the note changed RIGHT NOW
        var noteVal: CGFloat? = nil
        
        if currentNoteValue != self.lastNoteValue && currentNoteValue > 0 {
                // New note event detected with velocity > 0
            noteVal = CGFloat(currentNoteValue)
                //                    print("\n🎵 Note event at this exact point: velocity=\(currentNoteValue)\n")
            self.lastNoteValue = currentNoteValue
        }
        else if currentNoteValue == 0 && self.lastNoteValue > 0 {
                // Note off detected (velocity = 0) - reset for next note
                //                    print("\n🎵 Note off detected, resetting for next note\n")
            self.lastNoteValue = 0
        }
        
            // Create new data point with current state
            // hasNote and noteValue are ONLY set if a note event happened on THIS tick
        let newPoint = DataPoint(
            value: ccVal,
            hasNote: noteVal != nil,
            noteValue: noteVal
        )
        
        self.dataPoints.append(newPoint)
        
            // SCROLLING: Remove oldest points when we exceed max
            // This creates the left-scrolling effect
        if self.dataPoints.count > self.maxDataPoints {
            self.dataPoints.removeFirst(self.dataPoints.count - self.maxDataPoints)
        }
    }
    
    
    /**
     * Stops the graph data collection.
     *
     * Invalidates and releases the timer. Call this when:
     * - The view disappears
     * - The app is closing
     * - You want to pause data collection
     */
    func stop() {
        print("📊 Stopping graph data collection")
        
        ccListenerTask?.cancel()
        ccListenerTask = nil
        
        noteListenerTask?.cancel()
        noteListenerTask = nil
        
        timerListenerTask?.cancel()
        timerListenerTask = nil
        
        timer?.invalidate()
        timer = nil

        dataPoints = []
    }
    
        // MARK: Cleanup
    
    /**
     * Cleanup when GraphViewModel is deallocated.
     * Ensures the timer is stopped.
     */
    deinit {
        print("📊 Stopping graph data collection")
        timer?.invalidate()
        timer = nil
        ccListenerTask = nil
        noteListenerTask = nil
    }
}

