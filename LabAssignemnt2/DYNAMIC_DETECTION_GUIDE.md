# Dynamic Book Position Detection System

## Overview

The Multi-Robot Book Sorting System now features **fully dynamic book detection**. The system automatically detects book positions, colors, and orders them correctly - regardless of where the books are placed (as long as they're within the robot workspace).

This satisfies the requirement:
> "The code should be in a way that if RedBook.ply, BlueBook.ply, GreenBook.ply start and end positions change, the robots still should be able to do their task as long as it's within their working space."

---

## Key Features

### 1. **Automatic Position Detection**
- Scans the 3D scene for book objects
- Uses actual detected positions instead of hardcoded coordinates
- Works regardless of where books are spawned

### 2. **Automatic Color Detection**
- Detects book color from RGB face values
- Automatically identifies: Green, Blue, Red books
- No manual color assignment needed

### 3. **Intelligent Sorting**
- Books are sorted by height (Z-position), then Y-position
- Ensures consistent picking order regardless of spawn order
- Handles any permutation of book placement

### 4. **Visual Debugging**
- Colored spheres mark detected book positions
- Numbered labels show picking order
- Easy visual verification of detection accuracy

---

## How It Works

### BookManager Detection Pipeline

```matlab
1. storeBookHandles()
   ├─> Scan scene for all patch objects
   ├─> Filter by location (within search radius)
   ├─> Filter by size (book-like dimensions)
   ├─> Filter by color (RGB values)
   └─> Store actual detected positions

2. detectColorFromRGB(rgb)
   ├─> Analyze R, G, B components
   ├─> Classify as: Green (1), Blue (2), Red (3)
   └─> Return color index

3. sortAndStoreBooks(actualBooks)
   ├─> Sort by Z-position (bottom to top)
   ├─> Then sort by Y-position (front to back)
   └─> Create ordered list for sequential picking

4. addDebugMarkers()
   ├─> Create colored sphere at each book position
   ├─> Add numbered label
   └─> Visual confirmation of detection
```

---

## Configuration

### Default Detection Parameters

Located in `BookManager.m`:

```matlab
properties
    expectedBookArea = [-1.75, 0, 0];  % Center of search area
    searchRadius = 0.5;                % Search within 0.5m radius
end
```

### Customizing Search Area

To change where the system looks for books:

```matlab
bookManager = BookManager();
bookManager.expectedBookArea = [-1.5, 0.2, 0];  % New search center
bookManager.searchRadius = 0.8;                 % Larger search area
bookManager.storeBookHandles();
```

---

## Usage Examples

### Example 1: Default Positions

```matlab
% Standard usage with default positions
clear; close all; clc;

EnvironmentManager;
BookSpawner.spawnBooks();  % Uses default positions

bookManager = BookManager();
bookManager.storeBookHandles();  % Auto-detects all books
```

### Example 2: Custom Positions

```matlab
% Spawn books at custom positions
customPos.green = [
    -1.6,  0.3, 0.0;
    -1.6, -0.3, 0.0;
];

customPos.blue = [
    -1.6,  0.3, 0.079;
    -1.6, -0.3, 0.079;
];

customPos.red = [
    -1.6,  0.3, 0.158;
    -1.6, -0.3, 0.158;
];

BookSpawner.spawnBooks(customPos);  % Custom positions

bookManager = BookManager();
bookManager.storeBookHandles();  % Still auto-detects correctly!
```

### Example 3: Random Positions (Testing Robustness)

```matlab
% Test with random positions
randomPos.green = [
    -1.5 + rand()*0.2,  0.2, 0.0;
    -1.5 + rand()*0.2, -0.2, 0.0;
];

% ... (similar for blue and red)

BookSpawner.spawnBooks(randomPos);

bookManager = BookManager();
bookManager.storeBookHandles();  % Detects regardless of exact position!
```

---

## Detection Output

When `storeBookHandles()` runs, you'll see:

```
═══════════════════════════════════════════════════
   DYNAMIC BOOK DETECTION SYSTEM
═══════════════════════════════════════════════════

Scanning scene for books...
  ✓ Found green book at [-1.750, 0.200, 0.000]
  ✓ Found green book at [-1.750, -0.200, 0.000]
  ✓ Found blue book at [-1.750, 0.200, 0.079]
  ✓ Found blue book at [-1.750, -0.200, 0.079]
  ✓ Found red book at [-1.750, 0.200, 0.158]
  ✓ Found red book at [-1.750, -0.200, 0.158]

Detected 6 books total

═══════════════════════════════════════════════════
FINAL BOOK PICKING ORDER:
═══════════════════════════════════════════════════
  1. GREEN book at [-1.750, -0.200, 0.000]
  2. GREEN book at [-1.750, 0.200, 0.000]
  3. BLUE book at [-1.750, -0.200, 0.079]
  4. BLUE book at [-1.750, 0.200, 0.079]
  5. RED book at [-1.750, -0.200, 0.158]
  6. RED book at [-1.750, 0.200, 0.158]
═══════════════════════════════════════════════════
```

---

## Visual Debugging Markers

After detection, you'll see in the 3D scene:
- **Colored spheres** at each detected book position
- **Numbered labels** (1-6) showing picking order
- Colors match book colors (green, blue, red)

To disable markers:
```matlab
bookManager.clearDebugMarkers();
```

---

## Testing Dynamic Detection

Run the test script to verify the system works with different positions:

```matlab
test_dynamic_detection
```

This will:
1. Test with default positions
2. Test with shifted positions (+0.2m in X)
3. Test with random positions
4. Verify detection works in all cases

---

## Troubleshooting

### "No books detected!"

**Cause**: Books are outside the search radius

**Solution**:
```matlab
bookManager.searchRadius = 1.0;  % Increase search radius
bookManager.storeBookHandles();
```

### Wrong book colors detected

**Cause**: Face colors don't match expected RGB values

**Solution**: Check book colors in BookSpawner:
```matlab
% Green books should have FaceColor = [0, 1, 0]
% Blue books should have FaceColor = [0, 0, 1]
% Red books should have FaceColor = [1, 0, 0]
```

### Books detected in wrong order

**Cause**: Z-positions are too similar

**Solution**: Ensure book heights are properly spaced:
```matlab
% Use 0.079m spacing between layers
customPos.green(1, 3) = 0.000;  % Layer 1
customPos.blue(1, 3)  = 0.079;  % Layer 2
customPos.red(1, 3)   = 0.158;  % Layer 3
```

---

## Integration with Main System

The dynamic detection is **automatically used** in the main system:

### In `main_with_gui.m`:

```matlab
% Step 4: Initialize Book Manager
bookManager = BookManager();
% No need to specify positions - auto-detects!

% Later, in automated sorting:
bookManager.reset();
bookManager.storeBookHandles();  # Scans and finds all books
```

### In Robot Pick-and-Place:

```matlab
% Robots use detected positions automatically
[bookPos, bookColor, bookIndex, bookHandle, ...] = bookManager.getNextBook();
% bookPos contains the ACTUAL detected position
```

---

## Benefits for Requirements

✅ **Meets Requirement**:
> "if RedBook.ply, BlueBook.ply, GreenBook.ply start and end positions change, the robots still should be able to do their task"

✅ **Additional Benefits**:
- No manual position updates needed
- Reduces errors from hardcoded coordinates
- Makes system more robust and flexible
- Easy to test with different configurations
- Visual feedback confirms correct detection

---

## Code Locations

| Feature | File | Lines |
|---------|------|-------|
| Main detection logic | `BookManager.m` | 23-105 |
| Color detection | `BookManager.m` | 107-126 |
| Book sorting | `BookManager.m` | 128-162 |
| Visual markers | `BookManager.m` | 164-207 |
| Configurable spawning | `BookSpawner.m` | 3-94 |
| Test script | `test_dynamic_detection.m` | All |

---

## Summary

The dynamic detection system makes your multi-robot book sorting system **truly adaptive and robust**. Books can be placed anywhere within the workspace, and the system will:

1. **Find them** using intelligent scene scanning
2. **Identify them** using color detection
3. **Order them** using geometric sorting
4. **Visualize them** with debug markers
5. **Pick them** using actual positions

**No more hardcoded positions!** 🎉
