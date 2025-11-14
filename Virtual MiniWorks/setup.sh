#!/bin/bash

# Virtual MiniWorks Xcode Project Setup Script

echo "🎹 Virtual Waldorf 4 Pole Filter - Project Setup"
echo "================================================"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"
echo ""

# Get project directory
PROJECT_DIR="VirtualMiniWorks"
echo "📁 Creating project directory: $PROJECT_DIR"

# Create directory structure
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# List of Swift files to copy
SWIFT_FILES=(
    "VirtualMiniWorksApp.swift"
    "MIDIManager.swift"
    "VirtualDeviceState.swift"
    "MIDIPortSelector.swift"
    "ProgramSelector.swift"
    "ParameterView.swift"
    "GlobalSettingsView.swift"
    "MIDIMonitorView.swift"
    "Continuous_Controller_Values.swift"
    "Global_Types.swift"
    "MiniWorks_Errors.swift"
    "MiniWorks_Parameters.swift"
    "Misc_Program_Types.swift"
    "Mod_Sources.swift"
    "SysEx_Constants.swift"
    "SysEx_Message_Types.swift"
    "Raw_Dumps.swift"
)

echo ""
echo "📋 Files to include in your Xcode project:"
echo ""
for file in "${SWIFT_FILES[@]}"; do
    if [ -f "../$file" ]; then
        echo "  ✓ $file"
        cp "../$file" .
    else
        echo "  ⚠ $file (not found)"
    fi
done

# Copy README
if [ -f "../README.md" ]; then
    cp "../README.md" .
    echo "  ✓ README.md"
fi

echo ""
echo "================================================"
echo "📝 Next Steps:"
echo "================================================"
echo ""
echo "1. Open Xcode"
echo "2. Create new project: File → New → Project"
echo "3. Choose: macOS → App"
echo "4. Settings:"
echo "   - Product Name: VirtualMiniWorks"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Save in: $(pwd)"
echo ""
echo "5. Delete the default ContentView.swift"
echo "6. Add all .swift files from this directory to the project"
echo "7. Update SysEx_Constants.swift (see README.md)"
echo "8. Build and run! (⌘R)"
echo ""
echo "📖 See README.md for detailed instructions"
echo ""

exit 0
