% main_with_gui.m - Multi-Robot Book Sorting with GUI Control
% Lab Assignment 2 - Industrial Robotics
% Features: GUI Control, E-Stop, Sensor Simulation, Joint/Cartesian Jogging

clear; close all; clc;

fprintf('════════════════════════════════════════════════════════\n');
fprintf('   MULTI-ROBOT BOOK SORTING SYSTEM WITH GUI CONTROL\n');
fprintf('════════════════════════════════════════════════════════\n\n');

%% Step 1: Setup Environment
fprintf('Step 1: Setting up environment...\n');
EnvironmentManager;
fprintf('✓ Environment setup complete\n\n');

%% Step 2: Spawn Books
fprintf('Step 2: Spawning books...\n');
BookSpawner.spawnBooks();
BookSpawner.drawBookStartMarkers();
fprintf('✓ Books spawned: 6 books (2 red, 2 green, 2 blue)\n\n');

%% Step 3: Create Robots
fprintf('Step 3: Creating robots...\n');
robots = RobotFactory.createAllRobots();
fprintf('✓ Created 4 robots:\n');
fprintf('  - LinearUR3 (Book Sorter)\n');
fprintf('  - YaskawaGP4/MotomanGP4 (Red Books)\n');
fprintf('  - KukaKr3R540 (Green Books)\n');
fprintf('  - AuboI5 (Blue Books)\n\n');

%% Step 4: Initialize Book Manager
fprintf('Step 4: Initializing book manager...\n');
bookManager = BookManager();
fprintf('✓ Book manager ready\n\n');

%% Step 5: Launch GUI
fprintf('Step 5: Launching GUI...\n');
gui = RobotGUI(robots, bookManager);
fprintf('✓ GUI launched successfully\n\n');

fprintf('════════════════════════════════════════════════════════\n');
fprintf('   GUI CONTROL PANEL IS NOW ACTIVE\n');
fprintf('════════════════════════════════════════════════════════\n\n');

fprintf('GUI FEATURES:\n');
fprintf('  🛑 E-STOP:          Emergency stop with two-action resume\n');
fprintf('  🎮 JOINT CONTROL:   Jog individual joints\n');
fprintf('  📐 CARTESIAN:       Control end-effector X, Y, Z position\n');
fprintf('  🔴 SENSOR:          Test light curtain simulation\n');
fprintf('  🤖 ROBOT SELECT:    Switch between 4 robots\n\n');

fprintf('TESTING E-STOP:\n');
fprintf('  1. Press "EMERGENCY STOP" button (red)\n');
fprintf('  2. Verify all movement controls are disabled\n');
fprintf('  3. Press "RESUME OPERATIONS" button (green)\n');
fprintf('  4. Verify controls are re-enabled\n\n');

fprintf('TESTING SENSOR:\n');
fprintf('  1. Press "TRIGGER SENSOR" button (orange)\n');
fprintf('  2. Try to move robot (should be blocked)\n');
fprintf('  3. Press "CLEAR SENSOR" button\n');
fprintf('  4. Movement should be permitted again\n\n');

fprintf('AUTOMATED OPERATION:\n');
fprintf('  Click the "▶ START BOOK DEMO" button in the GUI to begin!\n');
fprintf('  The demo will automatically run all 4 phases:\n');
fprintf('    Phase 1: LinearUR3 sorts 6 books into color piles\n');
fprintf('    Phase 2: MotomanGP4 picks red books and stacks them\n');
fprintf('    Phase 3: KukaKr3R540 picks green books and stacks them\n');
fprintf('    Phase 4: AuboI5 picks blue books and stacks them\n\n');

fprintf('E-STOP INTEGRATION:\n');
fprintf('  - E-Stop can be triggered at any time during the demo\n');
fprintf('  - Sensor trigger will also halt the demo\n');
fprintf('  - Demo automatically checks safety before each phase\n\n');

fprintf('════════════════════════════════════════════════════════\n');
fprintf('NOTE: Keep this command window open to see status messages\n');
fprintf('════════════════════════════════════════════════════════\n\n');

% Keep script running so GUI stays active
fprintf('GUI is active. Close GUI window to exit.\n\n');
