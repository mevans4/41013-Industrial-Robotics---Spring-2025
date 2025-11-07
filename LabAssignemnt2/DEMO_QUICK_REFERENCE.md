# Lab Assignment 2 - Demo Quick Reference

## 🚀 LAUNCH COMMAND
```matlab
cd LabAssignemnt2
main_with_gui
```

---

## ✅ REQUIREMENTS CHECKLIST

### 1. ✅ Four Robots Operating in Same Workspace
- **LinearUR3** - Sorts 6 books into 3 color piles
- **MotomanGP4** - Picks red books from pile
- **KukaKr3R540** - Picks green books from pile
- **AuboI5** - Picks blue books from pile

**Show**: Point out all 4 robots in environment

---

### 2. ✅ MATLAB GUI with Advanced Teach Functionality

**Location**: GUI window opens automatically

#### Individual Joint Movements:
- Select robot from dropdown
- Use ◀ ▶ buttons next to each joint
- Values update in real-time

**Demo Script**:
```
1. Select "LinearUR3"
2. Press ▶ next to Joint 2
3. Watch robot move, value updates
4. Press ◀ to move back
```

#### [X,Y,Z] Cartesian Movements:
- Right panel has X, Y, Z controls
- Press +X/-X, +Y/-Y, +Z/-Z buttons
- Position display updates

**Demo Script**:
```
1. Press +X button 3 times
2. Press +Z button 2 times
3. Show position display updating
```

---

### 3. ✅ Functional E-Stop (Simulated)

**Location**: Red button in left panel

#### Two-Action Resume:
**Action 1**: Press "EMERGENCY STOP"
- All operations halt immediately
- All controls become disabled
- Status shows "E-STOP ACTIVE"

**Action 2**: Press "RESUME OPERATIONS"
- System resumes operations
- Controls become enabled
- Status shows "OPERATIONAL"

**Demo Script**:
```
1. Press red "EMERGENCY STOP" button
   → Show controls are disabled
   → Try to move joint (won't work)

2. Press green "RESUME OPERATIONS" button
   → Show controls are re-enabled
   → Move joint to prove it works
```

**Code Reference**: `EStopManager.m` lines 45-94

#### Recovery After E-Stop:
- System saves state when e-stop activated
- Can resume operations from where it left off
- No data loss or need to restart

---

### 4. ✅ Simulated Environment with Safety Equipment

**Show in 3D view**:
- ☑ Safety barriers around workspace
- ☑ Emergency stop button (3D model)
- ☑ Fire extinguisher
- ☑ Warning signs
- ☑ Concrete floor marking

**Code**: `EnvironmentManager.m`

---

### 5. ✅ Safety Functionality

#### (a) React to Asynchronous Stop Signal:

**Sensor Simulation** (Light Curtain):
1. Press "TRIGGER SENSOR" button (orange)
2. Try to move robot
3. Movement is blocked
4. Press "CLEAR SENSOR"
5. Movement works again

**Demo Script**:
```
1. Press orange "TRIGGER SENSOR"
   → Status shows "Sensors: BREACHED!"

2. Try to jog a joint
   → Console: "Cannot move: Safety sensor triggered"

3. Press "CLEAR SENSOR"
   → Status shows "Sensors: CLEAR"

4. Jog joint again
   → Works normally
```

**Code Reference**: `SensorSimulator.m`

#### (b) Prevent Collisions:

**Z-Axis Safety**:
- Try moving end-effector below table (Z < 0.01m)
- System prevents collision
- Message: "Z limit reached (table collision prevention)"

**RMRC Collision Avoidance**:
- In `LinearUR3_MotomanGP4_Collaboration.m`
- Robots avoid each other during movement
- Console shows: "[COLLISION AVOIDANCE] Robot distance: X.XXm"

**Demo Script**:
```
1. Select LinearUR3
2. Press -Z multiple times
3. Watch it stop at safe height
4. Console shows safety message
```

**Code References**:
- `SafetyUtils.m` - Z-axis prevention
- `LinearUR3_MotomanGP4_Collaboration.m` lines 205-401

---

## 📊 CODE VIVA PREPARATION

### Question: "Explain how your E-Stop works"
**Answer**:
- E-Stop system is in `EStopManager.m`
- Uses two-action resume pattern
- `Activate()` method halts all operations
- `Disengage()` allows resume but doesn't start
- `Resume()` restarts operations (requires disengage first)
- State is saved for recovery

### Question: "Show me where sensor triggers block movement"
**Answer**:
- `SensorSimulator.m` line 38-56 for trigger logic
- `RobotGUI.m` lines 451-481 check `IsOperational()` before movement
- Both E-Stop and sensor must be clear to move

### Question: "How does teach mode work?"
**Answer**:
- `RobotGUI.m` line 451-481 implements joint jogging
- Gets current joint angles
- Adds/subtracts step size
- Checks joint limits
- Animates robot to new position

### Question: "Explain Cartesian control implementation"
**Answer**:
- `RobotGUI.m` lines 484-520
- Gets current end-effector pose via forward kinematics
- Calculates new target position
- Uses inverse kinematics (`ikcon`) to find joint angles
- Safety checks Z-axis before movement

---

## 🎯 DEMO SEQUENCE (5 minutes)

### Part 1: GUI Introduction (1 min)
```
1. Show GUI window with 3 panels
2. Point out E-Stop button
3. Point out joint controls
4. Point out Cartesian controls
```

### Part 2: E-Stop Demo (1 min)
```
1. Press E-Stop → Show halt
2. Press Resume → Show recovery
3. Explain two-action requirement
```

### Part 3: Sensor Demo (1 min)
```
1. Trigger sensor → Show blocked
2. Try movement → Show prevention
3. Clear sensor → Show resume
```

### Part 4: Teach Mode Demo (1 min)
```
1. Jog 2-3 joints individually
2. Show real-time updates
3. Show joint limit enforcement
```

### Part 5: Cartesian Control (1 min)
```
1. Move X, Y, Z independently
2. Show position display
3. Demonstrate Z-safety (table collision)
```

---

## 📁 FILE LOCATIONS

| Feature | File | Key Lines |
|---------|------|-----------|
| GUI Main | `RobotGUI.m` | All |
| E-Stop Logic | `EStopManager.m` | 45-94 (activate/resume) |
| Sensor Logic | `SensorSimulator.m` | 38-56 (trigger/clear) |
| Joint Jog | `RobotGUI.m` | 451-481 |
| Cartesian | `RobotGUI.m` | 484-520 |
| Z-Safety | `SafetyUtils.m` | 14-42 |
| Collision Avoid | `LinearUR3_MotomanGP4_Collaboration.m` | 205-401 |
| Environment | `EnvironmentManager.m` | All |

---

## 🐛 TROUBLESHOOTING

### GUI won't launch
```matlab
close all force
main_with_gui
```

### Robot won't move
- Check E-Stop not active (red button)
- Check sensor not triggered (orange button)
- Check console for IK failures

### Joint limits reached
- Press "MOVE TO HOME" button
- Then try movement again

---

## 💬 KEY TALKING POINTS

1. **"Two-action e-stop is implemented"**
   - Not a busy while loop
   - Proper state management
   - Can recover and resume

2. **"Active sensor simulation demonstrates workspace safety"**
   - Light curtain breach blocks movement
   - Real-time detection
   - Automatic clearing when safe

3. **"Advanced teach functionality beyond basic toolbox"**
   - Individual joint control
   - Cartesian control
   - Real-time feedback
   - Safety checking

4. **"Safety equipment strategically placed"**
   - Barriers prevent access
   - Emergency stops accessible
   - Fire safety equipment
   - Warning signage

5. **"Collision detection prevents damage"**
   - Table collision prevention
   - Robot-robot avoidance (RMRC)
   - Active checking during movement

---

## 📞 IF ASKED ABOUT HARDWARE E-STOP

**Response**: "We've implemented a fully functional simulated e-stop system that demonstrates the required two-action resume pattern. The system architecture allows for easy integration with hardware (Arduino, physical button) via serial communication. The `EStopManager` class is hardware-agnostic and can accept stop signals from any source."

**Bonus**: "If we had physical hardware, we would add a serial listener in `EStopManager.m` to read Arduino signals, keeping all the existing logic intact."

---

## ✨ BONUS FEATURES IMPLEMENTED

- Real-time status display
- Multiple robot support with dropdown
- Configurable step sizes
- Joint limit enforcement
- IK failure handling
- Visual feedback (colors, status text)
- State recovery after e-stop
- Intrusion counting in sensor

---

**END OF QUICK REFERENCE**

---

## 🎓 FINAL CHECKLIST BEFORE DEMO

- [ ] Run `test_gui.m` - all tests pass
- [ ] Run `main_with_gui.m` - GUI opens
- [ ] Test E-Stop → Resume cycle
- [ ] Test Sensor → Clear cycle
- [ ] Test joint jogging (3 joints)
- [ ] Test Cartesian control (X, Y, Z)
- [ ] Verify all 4 robots visible
- [ ] Check console for error messages
- [ ] Review code locations above
- [ ] Practice 5-minute demo sequence

**Good luck with your demo! 🚀**
