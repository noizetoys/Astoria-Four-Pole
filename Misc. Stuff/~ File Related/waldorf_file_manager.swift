import Foundation
import Combine

// MARK: - File Manager for Waldorf 4-Pole

class Waldorf4PoleFileManager: ObservableObject {
    // Published properties
    @Published var availableFiles: [ProgramFile] = []
    @Published var availableBanks: [BankFile] = []
    @Published var lastError: String?
    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = false
    
    // File system paths
    private let documentsDirectory: URL
    private let programsDirectory: URL
    private let banksDirectory: URL
    
    // MIDI Manager reference (for send/receive operations)
    weak var midiManager: Waldorf4PoleMIDIManager?
    
    init() {
        // Setup directories
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        programsDirectory = documentsDirectory.appendingPathComponent("Waldorf4Pole/Programs")
        banksDirectory = documentsDirectory.appendingPathComponent("Waldorf4Pole/Banks")
        
        createDirectoriesIfNeeded()
        scanFiles()
    }
    
    // MARK: - Directory Management
    
    private func createDirectoriesIfNeeded() {
        let directories = [programsDirectory, banksDirectory]
        
        for directory in directories {
            if !FileManager.default.fileExists(atPath: directory.path) {
                do {
                    try FileManager.default.createDirectory(
                        at: directory,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                } catch {
                    lastError = "Failed to create directory: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func scanFiles() {
        scanPrograms()
        scanBanks()
    }
    
    private func scanPrograms() {
        availableFiles.removeAll()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: programsDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            for file in files where file.pathExtension == "w4p" {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   let fileSize = attributes[.size] as? Int64 {
                    
                    availableFiles.append(ProgramFile(
                        url: file,
                        name: file.deletingPathExtension().lastPathComponent,
                        creationDate: creationDate,
                        fileSize: fileSize
                    ))
                }
            }
            
            availableFiles.sort { $0.creationDate > $1.creationDate }
        } catch {
            lastError = "Failed to scan programs: \(error.localizedDescription)"
        }
    }
    
    private func scanBanks() {
        availableBanks.removeAll()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: banksDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            for file in files where file.pathExtension == "w4b" {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   let fileSize = attributes[.size] as? Int64 {
                    
                    availableBanks.append(BankFile(
                        url: file,
                        name: file.deletingPathExtension().lastPathComponent,
                        creationDate: creationDate,
                        fileSize: fileSize
                    ))
                }
            }
            
            availableBanks.sort { $0.creationDate > $1.creationDate }
        } catch {
            lastError = "Failed to scan banks: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Program Operations
    
    func saveProgram(_ program: Waldorf4PoleProgram, name: String? = nil) {
        isSaving = true
        
        let fileName = (name ?? program.name).replacingOccurrences(of: "/", with: "-")
        let fileURL = programsDirectory.appendingPathComponent("\(fileName).w4p")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(program)
            try data.write(to: fileURL)
            
            DispatchQueue.main.async {
                self.isSaving = false
                self.scanPrograms()
            }
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to save program: \(error.localizedDescription)"
                self.isSaving = false
            }
        }
    }
    
    func loadProgram(from file: ProgramFile) -> Waldorf4PoleProgram? {
        isLoading = true
        
        do {
            let data = try Data(contentsOf: file.url)
            let decoder = JSONDecoder()
            let program = try decoder.decode(Waldorf4PoleProgram.self, from: data)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            return program
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to load program: \(error.localizedDescription)"
                self.isLoading = false
            }
            return nil
        }
    }
    
    func deleteProgram(_ file: ProgramFile) {
        do {
            try FileManager.default.removeItem(at: file.url)
            scanPrograms()
        } catch {
            lastError = "Failed to delete program: \(error.localizedDescription)"
        }
    }
    
    func exportProgram(_ program: Waldorf4PoleProgram) -> URL? {
        let fileName = "\(program.name.replacingOccurrences(of: "/", with: "-")).w4p"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(program)
            try data.write(to: fileURL)
            return fileURL
        } catch {
            lastError = "Failed to export program: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importProgram(from url: URL) -> Waldorf4PoleProgram? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let program = try decoder.decode(Waldorf4PoleProgram.self, from: data)
            
            // Save to programs directory
            saveProgram(program)
            
            return program
        } catch {
            lastError = "Failed to import program: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Bank Operations
    
    func saveBank(_ bank: Waldorf4PoleBank, name: String) {
        isSaving = true
        
        let fileName = name.replacingOccurrences(of: "/", with: "-")
        let fileURL = banksDirectory.appendingPathComponent("\(fileName).w4b")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(bank)
            try data.write(to: fileURL)
            
            DispatchQueue.main.async {
                self.isSaving = false
                self.scanBanks()
            }
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to save bank: \(error.localizedDescription)"
                self.isSaving = false
            }
        }
    }
    
    func loadBank(from file: BankFile) -> Waldorf4PoleBank? {
        isLoading = true
        
        do {
            let data = try Data(contentsOf: file.url)
            let decoder = JSONDecoder()
            let bank = try decoder.decode(Waldorf4PoleBank.self, from: data)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            return bank
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to load bank: \(error.localizedDescription)"
                self.isLoading = false
            }
            return nil
        }
    }
    
    func deleteBank(_ file: BankFile) {
        do {
            try FileManager.default.removeItem(at: file.url)
            scanBanks()
        } catch {
            lastError = "Failed to delete bank: \(error.localizedDescription)"
        }
    }
    
    func exportBank(_ bank: Waldorf4PoleBank, name: String) -> URL? {
        let fileName = "\(name.replacingOccurrences(of: "/", with: "-")).w4b"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(bank)
            try data.write(to: fileURL)
            return fileURL
        } catch {
            lastError = "Failed to export bank: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importBank(from url: URL, name: String) -> Waldorf4PoleBank? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let bank = try decoder.decode(Waldorf4PoleBank.self, from: data)
            
            // Save to banks directory
            saveBank(bank, name: name)
            
            return bank
        } catch {
            lastError = "Failed to import bank: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - SysEx File Operations
    
    func exportProgramAsSysEx(_ program: Waldorf4PoleProgram) -> URL? {
        let fileName = "\(program.name.replacingOccurrences(of: "/", with: "-")).syx"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let message = Waldorf4PoleSysExMessage.programDump(program: program)
        let data = Waldorf4PoleSysEx.generate(message: message)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            lastError = "Failed to export SysEx: \(error.localizedDescription)"
            return nil
        }
    }
    
    func importProgramFromSysEx(from url: URL) -> Waldorf4PoleProgram? {
        do {
            let data = try Data(contentsOf: url)
            
            if let message = Waldorf4PoleSysEx.parse(data: data),
               case .programDump(let program) = message {
                
                // Save to programs directory
                saveProgram(program)
                
                return program
            } else {
                lastError = "Invalid SysEx file format"
                return nil
            }
        } catch {
            lastError = "Failed to import SysEx: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - MIDI Integration
    
    func sendProgramToDevice(_ program: Waldorf4PoleProgram) {
        guard let midiManager = midiManager else {
            lastError = "MIDI Manager not configured"
            return
        }
        
        midiManager.sendProgram(program)
    }
    
    func receiveProgramFromDevice(programNumber: Int, completion: @escaping (Waldorf4PoleProgram?) -> Void) {
        guard let midiManager = midiManager else {
            lastError = "MIDI Manager not configured"
            completion(nil)
            return
        }
        
        // Request program from device
        midiManager.requestProgram(programNumber)
        
        // Wait for response (observe MIDI manager's currentProgram)
        var cancellable: AnyCancellable?
        cancellable = midiManager.$currentProgram
            .compactMap { $0 }
            .first()
            .sink { [weak self] program in
                if program.number == programNumber {
                    completion(program)
                }
                cancellable?.cancel()
            }
        
        // Timeout after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            cancellable?.cancel()
            completion(nil)
        }
    }
    
    func receiveBankFromDevice(completion: @escaping (Waldorf4PoleBank?, Waldorf4PoleGlobalParams?) -> Void) {
        guard let midiManager = midiManager else {
            lastError = "MIDI Manager not configured"
            completion(nil, nil)
            return
        }
        
        // Request all dump (bank + globals) from device
        midiManager.requestAllDump()
        
        // Wait for response
        var cancellable: AnyCancellable?
        cancellable = midiManager.$receivedMessages
            .sink { [weak self] messages in
                if let allDumpMessage = messages.last,
                   case .allDump(let bank, let globals) = allDumpMessage {
                    completion(bank, globals)
                    cancellable?.cancel()
                }
            }
        
        // Timeout after 30 seconds (bank transfers can be slow)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            cancellable?.cancel()
            completion(nil, nil)
        }
    }
    
    func sendBankToDevice(_ bank: Waldorf4PoleBank, globals: Waldorf4PoleGlobalParams? = nil) {
        guard let midiManager = midiManager else {
            lastError = "MIDI Manager not configured"
            return
        }
        
        let globalParams = globals ?? Waldorf4PoleGlobalParams()
        midiManager.sendAllDump(bank: bank, globals: globalParams)
    }
}

// MARK: - File Models

struct ProgramFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let creationDate: Date
    let fileSize: Int64
    
    var fileSizeString: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    static func == (lhs: ProgramFile, rhs: ProgramFile) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

struct BankFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let creationDate: Date
    let fileSize: Int64
    
    var fileSizeString: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    static func == (lhs: BankFile, rhs: BankFile) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
