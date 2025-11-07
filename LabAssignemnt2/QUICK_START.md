# Quick Start Guide - Book Sorting Demo

## 🎯 What's Fixed

**Problem:** You couldn't start the book moving demo from the GUI.

**Solution:** Added a **"▶ START BOOK DEMO"** button to the GUI that launches the entire automated demo with one click!

---

## 🚀 How to Run the Demo

### Step 1: Launch the System

```matlab
cd LabAssignemnt2
main_with_gui
```

This will:
1. Setup the 3D environment
2. Spawn 6 colored books (2 red, 2 blue, 2 green)
3. Create 4 robots (LinearUR3, MotomanGP4, KukaKr3R540, AuboI5)
4. Launch the GUI

### Step 2: Start the Demo

**In the GUI (left panel), click the green button:**

```
▶ START BOOK DEMO
```

The demo will automatically run through 4 phases:

**Phase 1:** LinearUR3 sorts 6 books into 3 color piles
**Phase 2:** MotomanGP4 picks red books and stacks them
**Phase 3:** KukaKr3R540 picks green books and stacks them
**Phase 4:** AuboI5 picks blue books and stacks them

---

## 🛑 Testing Safety Features

### E-Stop Test

1. Click **"▶ START BOOK DEMO"**
2. During operation, click **"🛑 EMERGENCY STOP"** (red button)
3. Verify robot stops immediately
4. Click **"▶ RESUME OPERATIONS"** (green button)
5. System is ready to continue

### Sensor Test

1. Start the demo or jog a robot
2. Click **"🔴 TRIGGER SENSOR"** (orange button)
3. Verify movement is blocked
4. Click **"✓ CLEAR SENSOR"**
5. Movement resumes

### Collision Prevention Test

1. Select a robot from dropdown
2. Use Cartesian control: Click **"▼ -Z"** repeatedly
3. Watch end-effector approach table
4. Verify it stops at 10mm minimum clearance
5. See message: "Z limit reached (table collision prevention)"

---

## 🎮 GUI Controls

### Left Panel: Safety & Status
- **🛑 EMERGENCY STOP** - Two-action E-Stop
- **▶ RESUME OPERATIONS** - Resume after E-Stop
- **Status Indicators** - Real-time system monitoring
- **Robot Selector** - Choose which robot to control
- **🔴 TRIGGER SENSOR** - Test light curtain
- **🔄 RESET SYSTEM** - Full system reset
- **▶ START BOOK DEMO** - Launch automated sorting ⭐ NEW

### Center Panel: Joint Control (Teach Mode)
- **7 Joint Sliders** (for LinearUR3) or 6 (for others)
- **◀/▶ Buttons** - Jog individual joints
- **Step Size** - Configurable (0.001-0.5 rad)
- **🏠 MOVE TO HOME** - Return to zero position

### Right Panel: Cartesian Control
- **X, Y, Z Controls** - Move end-effector in 3D space
- **◀/▶ Buttons** - Increment/decrement position
- **Step Size** - Configurable (0.001-0.1 m)
- **Current Position** - Real-time display
- **🔄 UPDATE DISPLAY** - Manual refresh

---

## ✅ Requirements Met

### Core Requirements
✅ 4 robots (LinearUR3, KUKAkr3, MotomanGP4, AUBOi5)
✅ 6 books (2 red, 2 blue, 2 green)
✅ UR3 sorts into 3 color piles
✅ Other robots pick from piles and stack separately
✅ Adaptive to book position changes (within workspace)

### Safety (5 forms implemented)
✅ Physical barriers and signage in environment
✅ E-Stop with two-action resume
✅ Active workspace sensing (light curtain)
✅ Collision detection/avoidance (Z-height)
✅ Workspace constraints validation

### GUI Features
✅ Advanced teach mode (joint + Cartesian)
✅ Robot selection dropdown
✅ Real-time status monitoring
✅ E-Stop integration
✅ One-button demo launch ⭐

### E-Stop Requirements
✅ Simulated via GUI (large red button)
✅ Immediate stop on activation
✅ Two-action resume protocol
✅ Recovery/resume capability
✅ No busy while loops (event-driven)

---

## 📂 File Structure

```
LabAssignemnt2/
├── main_with_gui.m           ← MAIN ENTRY POINT (run this!)
├── RobotGUI.m               ← GUI with START DEMO button
├── BookManager.m            ← Book position tracking
├── BookSpawner.m            ← Book creation
├── RobotFactory.m           ← Robot creation
├── EnvironmentManager.m     ← 3D environment setup
├── EStopManager.m           ← E-Stop system
├── SensorSimulator.m        ← Light curtain simulation
├── SafetyUtils.m            ← Safety validation
├── BookPickAndPlace.m       ← UR3 sorting logic
├── MotomanPickAndPlace.m    ← Motoman operations
├── KukaPickAndPlace.m       ← KUKA operations
├── AuboPickAndPlace.m       ← AUBO operations
└── @RobotClasses/           ← Robot class definitions
```

---

## 🎓 Key Changes Made

### 1. RobotGUI.m
- ✅ Added "START DEMO" button (line 154-160)
- ✅ Added `OnStartDemo()` callback (line 621-665)
- ✅ Added `RunAutomatedSorting()` method (line 667-703)
- ✅ Added `CheckSafety()` method (line 705-718)
- ✅ Added 4 safety-wrapped pick-and-place methods (line 720-769)

### 2. main_with_gui.m
- ✅ Simplified by removing helper functions
- ✅ Updated instructions to mention GUI button
- ✅ Cleaner, more maintainable code

### 3. REQUIREMENTS_CHECKLIST.md
- ✅ Comprehensive checklist of all requirements
- ✅ Verification that all criteria are met
- ✅ Testing procedures for each safety feature

---

## 🔧 Troubleshooting

### Demo Button Doesn't Work
- Check E-Stop is not active
- Check sensor is not triggered
- Look for error messages in command window

### Robot Doesn't Move
- Verify E-Stop is cleared (green button should show "EMERGENCY STOP")
- Verify sensor is clear (should show "Sensors: CLEAR")
- Check robot is selected in dropdown

### Books Not Spawning
- Ensure you're in the correct directory: `cd LabAssignemnt2`
- Check book PLY files exist in the directory

---

## 📝 For Code Viva Preparation

**Understand these key components:**

1. **E-Stop Architecture**
   - File: `EStopManager.m`
   - Two-action resume: `Activate()` → `Disengage()` → `Resume()`
   - State management with flags

2. **GUI Event Handling**
   - File: `RobotGUI.m`
   - Callbacks: `@(btn,event) self.OnStartDemo()`
   - Handle class with persistent state

3. **Safety Integration**
   - File: `SafetyUtils.m`, `SensorSimulator.m`
   - Z-height validation
   - Light curtain simulation
   - Trajectory checking

4. **Multi-Robot Coordination**
   - File: `main_with_gui.m`, `RobotGUI.m`
   - Sequential phases (no simultaneous operation)
   - Shared workspace via BookManager

5. **Pick-and-Place Logic**
   - Files: `BookPickAndPlace.m`, etc.
   - IK solving
   - Trajectory planning
   - Grasp calculation

---

## 🎉 Summary

You now have a **fully functional, single-file entry point** system!

**To run the complete demo:**
```matlab
cd LabAssignemnt2
main_with_gui
% Click "▶ START BOOK DEMO" in the GUI
```

**Everything works from one main file with one button press!**

---

**Last Updated:** 2025-11-07
**Status:** ✅ FULLY FUNCTIONAL
