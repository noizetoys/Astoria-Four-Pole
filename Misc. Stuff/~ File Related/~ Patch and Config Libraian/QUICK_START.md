# Quick Start Guide - Patch Management System

## 5-Minute Overview

### What Is This?
A professional patch and configuration management system for synthesizers/audio devices with:
- **20 patch slots per configuration**
- **Unlimited configurations**
- **Comprehensive patch library**
- **Tag-based organization**
- **Advanced search and filtering**

### Key Concepts

**Patch**: A single sound program (e.g., "Deep Bass", "Bright Lead")

**Configuration**: A collection of 20 patches + global settings (e.g., "Live Set 2024")

**Current Configuration**: The active configuration you're working with

**Patch Library**: All patches available, regardless of which configuration they're in

## Quick Actions

### Load a Configuration
```
Sidebar → Click any configuration name
→ Loads it as the current configuration
→ All 20 slots are now accessible
```

### Browse Patches in a Configuration (Without Loading)
```
Sidebar → Click configuration
→ View shows all 20 slots
→ Click any patch to see options
```

### Search for a Patch
```
Main view → Type in search box
→ Results filter in real-time
→ Click "Filter by Tags" for tag filtering
→ Toggle "Favorites" to show starred patches
```

### Load a Patch to a Slot
```
Find patch → Click it
→ Dialog shows options:
   - "Load to Editor" (edit first)
   - "Load to Slot" (direct, select slot 1-20)
→ Choose slot → Click "Load"
```

### Edit a Patch
```
Find patch → Click menu (⋮)
→ "Edit"
→ Modify name, tags, parameters, etc.
→ Choose save option:
   - Update existing
   - Save as new
   - Save to configuration slot
```

### Create New Configuration
```
Sidebar → "New Configuration"
→ Enter name and notes
→ Click "Save"
→ Start loading patches into slots
```

### Save Your Work
```
Menu (···) in toolbar
→ "Save Configuration" (update current)
→ "Save As..." (create new or copy)
```

## Common Workflows

### Scenario 1: Building a Live Set
```
1. Create new configuration ("Live Set 2024")
2. Search for patches by tags (e.g., "Bass", "Lead")
3. Load patches to slots:
   - Slots 1-4: Bass patches
   - Slots 5-8: Lead patches
   - Slots 9-12: Pads
   - Slots 13-16: FX
4. Test in configuration view
5. Save configuration
```

### Scenario 2: Editing a Patch
```
1. Find patch in All Patches view
2. Click menu → "Edit"
3. Make changes
4. Save as new patch (preserves original)
5. Load to specific slot if needed
```

### Scenario 3: Exploring the Library
```
1. Click "All Patches" in sidebar
2. Use search to filter
3. Click tags to refine
4. Sort by category, date, name, etc.
5. Mark favorites (star icon)
6. Load interesting patches to editor
```

### Scenario 4: Organizing Patches
```
1. Edit patch
2. Add descriptive tags
3. Fill in category and author
4. Add notes about the sound
5. Mark as favorite if essential
6. Save changes
```

### Scenario 5: Backing Up a Configuration
```
1. Load configuration
2. Menu → "Save As..."
3. Select "Save As Copy"
4. Name it "[Original Name] - Backup"
5. Original stays active
```

## View Modes Explained

### All Patches View
- Shows every patch in your library
- Regardless of configuration
- Best for exploration and discovery
- Card-based layout with details

### Configuration View
- Shows 20 slots (numbered 1-20)
- Empty slots clearly marked
- Current configuration's patches only
- Grid layout for quick overview

## Search & Filter Guide

### Text Search
Searches in:
- Patch name
- Category
- Author
- Notes

### Tag Filtering
- Click "Filter by Tags" to expand
- Click tags to add to filter
- Multiple tags = must have ALL (AND logic)
- Selected tags highlighted

### Sorting
Options:
- **Name**: Alphabetical
- **Date Created**: Oldest/newest first
- **Date Modified**: Recently edited
- **Category**: Grouped by type
- **Author**: Grouped by creator

Click arrow to toggle ascending/descending

### Favorites
- Toggle "Favorites" switch
- Shows only starred patches
- Works with other filters

## Save Options Explained

### Save Configuration
**Updates current configuration**
- Overwrites existing config
- Date modified updates
- Use for regular saves

### Save As New
**Creates new configuration, makes it current**
- Original preserved
- New ID assigned
- Becomes active configuration
- Use when evolving a set

### Save As Copy
**Duplicates configuration**
- Original remains active
- Copy added to library
- Use for backups or variants

## Load Options Explained

### Load to Editor
**Safe editing before commitment**
- Opens patch in editor
- Make changes without affecting original
- Choose save destination
- Can save to slot or as standalone patch

### Load to Slot
**Direct, immediate loading**
- Overwrites existing patch in slot
- No confirmation (fast workflow)
- Use when you know where it goes
- Can't edit before loading

## Tips & Tricks

### Naming Conventions
```
[Category] - [Description] - [Variant]
Examples:
- Bass - Deep Sub - Dark
- Lead - Screaming - Bright
- Pad - Warm Strings - v2
```

### Tagging Strategy
Use 2-4 tags per patch:
- Genre tag (Bass, Lead, Pad, etc.)
- Character tag (Warm, Aggressive, Ambient)
- Use tag (Live, Studio, Experimental)

### Configuration Organization
```
Performance:
- "Live Set 2024"
- "Studio Session A"

Templates:
- "Electronic Template"
- "Ambient Starting Point"

Archive:
- "Old Live Set"
- "Experiment Archive"
```

### Slot Arrangement Ideas
```
Option 1 - By Type:
1-5: Bass
6-10: Leads
11-15: Pads
16-20: FX/Utility

Option 2 - By Song:
1-4: Song A patches
5-8: Song B patches
9-12: Song C patches
13-20: Shared/Utility

Option 3 - Performance:
1-10: Main patches (quick access)
11-15: Variations
16-20: Emergency backups
```

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Save | ⌘S |
| New Configuration | ⌘N |
| Focus Search | ⌘F |
| Close Dialog | ⌘W |
| Confirm | ⌘Return |
| Cancel | Escape |

## Common Questions

**Q: Can I have the same patch in multiple slots?**
A: Yes! Load the same patch to as many slots as needed.

**Q: Can a patch be in multiple configurations?**
A: Yes! All patches are shared across configurations.

**Q: What happens if I edit a patch that's in multiple slots?**
A: Changes apply to the patch itself, affecting all slots/configurations using it. Use "Save as New" to create a variant instead.

**Q: Can I have more than 20 patches in a configuration?**
A: No, configurations are limited to 20 slots to match typical hardware constraints. Use multiple configurations for larger sets.

**Q: What if I delete a patch that's in a configuration?**
A: The slot becomes empty. The configuration isn't damaged, just missing that patch.

**Q: Can I reorder patches in a configuration?**
A: Currently, you load patches to specific slots. To reorder, load them to different slots or use a new configuration.

## Troubleshooting

**Search isn't finding my patch**
- Check spelling
- Try partial matches
- Use tag filters instead
- Check if correct view mode (All Patches vs Configuration)

**Can't save configuration**
- Ensure configuration has a name
- Check if you have the current configuration loaded
- Try "Save As New" if update fails

**Patch disappeared after editing**
- Check if you clicked "Cancel" instead of "Save"
- Look in All Patches view (might not be in current configuration)
- Check date modified sort to find recent changes

**Slots not updating**
- Ensure you loaded patch to correct slot
- Check if you saved the configuration after loading
- Verify you're viewing the current configuration

## Next Steps

After mastering the basics:
1. Read full documentation for advanced features
2. Explore batch operations
3. Set up backup routine
4. Customize categories and tags
5. Experiment with configuration templates

## Getting Help

See full documentation:
- **PATCH_SYSTEM_README.md** - Complete feature list
- **PatchLibraryView.swift** - Source code and comments
- Inline help throughout the app
