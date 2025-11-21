//
//  UndoAction.swift
//  Check it Out
//
//  Created by James B. Majors on 11/20/25.
//
import  Foundation

// MARK: - Undo Manager

enum UndoAction {
    case loadPatchToSlot(slot: Int, oldPatch: Patch?, newPatch: Patch?)
    case clearSlot(slot: Int, patch: Patch?)
    case deletePatch(patch: Patch)
    case deleteConfiguration(config: Configuration)
    case modifyPatch(oldPatch: Patch, newPatch: Patch)
    case createConfiguration(config: Configuration)
    case modifyConfiguration(oldConfig: Configuration, newConfig: Configuration)
}

@Observable
class UndoManager {
    private var undoStack: [UndoAction] = []
    private var redoStack: [UndoAction] = []
    private let maxStackSize = 50
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    func registerUndo(_ action: UndoAction) {
        undoStack.append(action)
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }
    
    func undo(viewModel: PatchLibraryViewModel) {
        guard let action = undoStack.popLast() else { return }
        
        switch action {
        case .loadPatchToSlot(let slot, let oldPatch, _):
            if let old = oldPatch {
                viewModel.loadPatchToSlot(old, slot: slot, registerUndo: false)
            } else {
                viewModel.clearSlot(slot, registerUndo: false)
            }
            
        case .clearSlot(let slot, let patch):
            if let patch = patch {
                viewModel.loadPatchToSlot(patch, slot: slot, registerUndo: false)
            }
            
        case .deletePatch(let patch):
            viewModel.restorePatch(patch)
            
        case .deleteConfiguration(let config):
            viewModel.restoreConfiguration(config)
            
        case .modifyPatch(let oldPatch, _):
            viewModel.updatePatchDirectly(oldPatch, registerUndo: false)
            
        case .createConfiguration(let config):
            viewModel.deleteConfiguration(config, registerUndo: false)
            
        case .modifyConfiguration(let oldConfig, _):
            viewModel.updateConfigurationDirectly(oldConfig, registerUndo: false)
        }
        
        redoStack.append(action)
    }
    
    func redo(viewModel: PatchLibraryViewModel) {
        guard let action = redoStack.popLast() else { return }
        
        switch action {
        case .loadPatchToSlot(let slot, _, let newPatch):
            if let new = newPatch {
                viewModel.loadPatchToSlot(new, slot: slot, registerUndo: false)
            } else {
                viewModel.clearSlot(slot, registerUndo: false)
            }
            
        case .clearSlot(let slot, _):
            viewModel.clearSlot(slot, registerUndo: false)
            
        case .deletePatch(let patch):
            viewModel.deletePatch(patch, registerUndo: false)
            
        case .deleteConfiguration(let config):
            viewModel.deleteConfiguration(config, registerUndo: false)
            
        case .modifyPatch(_, let newPatch):
            viewModel.updatePatchDirectly(newPatch, registerUndo: false)
            
        case .createConfiguration(let config):
            viewModel.restoreConfiguration(config)
            
        case .modifyConfiguration(_, let newConfig):
            viewModel.updateConfigurationDirectly(newConfig, registerUndo: false)
        }
        
        undoStack.append(action)
    }
    
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
