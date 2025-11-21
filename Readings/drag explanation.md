Here you go — the full explanation formatted cleanly as **Markdown**:

---

# How SwiftUI Chooses the Drag Image

### (Where the drag preview comes from in your patch editor)

In your current code, you never explicitly create or specify the **image that appears under the cursor/finger** while a patch is being dragged. Yet you still see a small “ghost” of the patch tile moving around.

This is because SwiftUI (via UIKit/AppKit under the hood) **automatically generates a snapshot** of the view you attach `.onDrag` to.

Below is a step-by-step breakdown of how that works.

---

## 1. Where the drag originates in your code

In the left-side patch palette, each tile is defined like this:

```swift
PatchCellView(patch: patch)
    .onTapGesture(count: 2) {
        viewModel.userRequestedLoadPatch(programNumber: patch.programNumber)
    }
    .onTapGesture {
        viewModel.userRequestedLoadPatch(programNumber: patch.programNumber)
    }
    .onDrag {
        let text = "\(patch.programNumber)"
        return NSItemProvider(object: NSString(string: text))
    }
```

The `.onDrag` closure only returns an **`NSItemProvider`** with the program number as text.
This closure **does not** specify any image or visual for the drag.

---

## 2. So where does the drag image come from?

Because no preview is provided, SwiftUI defaults to:

> **Take a snapshot of the view that has `.onDrag` and use that snapshot as the drag preview.**

In this case, the view being snapped is:

```swift
struct PatchCellView: View {
    let patch: Patch
    
    var body: some View {
        VStack(spacing: 4) {
            Text("#\(patch.programNumber)")
                .font(.headline)
                .foregroundColor(.black)
            Text(patch.name)
                .font(.caption2)
                .foregroundColor(.black)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 1)
        )
    }
}
```

So the ghost image that follows the cursor is simply a rendered snapshot of this tile.

---

## 3. How the system decides what to show

When the drag begins:

1. The user presses on the `PatchCellView`.
2. SwiftUI calls your `.onDrag` closure to request the **drag data** (`NSItemProvider`).
3. UIKit/AppKit captures a **snapshot** of the actual rendered `PatchCellView`.
4. That snapshot becomes the **drag preview**.

No extra code is required unless you want to customize it.

---

## 4. If you want a custom drag preview

SwiftUI allows you to override the default snapshot using `draggable`/`dragPreview` APIs (iOS 17+/macOS 14+):

```swift
PatchCellView(patch: patch)
    .draggable("\(patch.programNumber)") {      // drag data
        CustomPreviewView(patch: patch)         // custom visual preview
    }
```

This allows you to show:

* A larger tile
* A floating badge
* A simplified label
* A scaled/blurred version
* Anything you want

instead of the default snapshot.

---

## TL;DR

* **Your code never specifies a drag image.**
* SwiftUI automatically uses **a snapshot of the dragged view** (`PatchCellView`) as the drag preview.
* Changing the tile’s appearance automatically changes the drag image.
* You can provide a **custom dragPreview** if you want full control over the drag-image appearance.

---

If you'd like, I can provide a version where the preview is a floating, enlarged “Patch #N” card with glow or color gradients.
