% Main execution script with GUI
clear; close all; clc;

% Setup environment
EnvironmentManager;

% Spawn books (these are added to the existing environment)
fprintf('Spawning books...\n');
BookSpawner.spawnBooks();
BookSpawner.drawBookStartMarkers();

% Create robots
fprintf('Creating robots...\n');
robots = RobotFactory.createAllRobots();

% Initialize book manager
bookManager = BookManager();

% UR3 Code - Sorts 6 books into 3 color piles
fprintf('\n========== PHASE 1: UR3 SORTING BOOKS ==========\n');
BookPickAndPlace(robots{1}, bookManager);

% Motoman - Picks red books (indices 3, 4) and moves to final location
fprintf('\n========== PHASE 2: MOTOMAN PICKING RED BOOKS ==========\n');
MotomanPickAndPlace(robots{2}, bookManager, [4, 3]);

% KUKA - Picks green books (indices 1, 2) and moves to final location
fprintf('\n========== PHASE 3: KUKA PICKING GREEN BOOKS ==========\n');
KukaPickAndPlace(robots{3}, bookManager, [2, 1]);

% AUBO - Picks blue books (indices 5, 6) and moves to final location
fprintf('\n========== PHASE 4: AUBO PICKING BLUE BOOKS ==========\n');
AuboPickAndPlace(robots{4}, bookManager, [6, 5]);



