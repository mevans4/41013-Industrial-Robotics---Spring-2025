classdef RobotGUI < handle
    % RobotGUI - Comprehensive GUI for Multi-Robot Book Sorting System
    % Features: E-Stop, Joint Jogging, Cartesian Control, Sensor Monitoring

    properties
        % GUI Components
        fig
        panels
        buttons
        sliders
        labels
        textFields
        statusText

        % Robot System
        robots
        selectedRobotIndex = 1
        bookManager

        % Safety Systems
        eStopManager
        sensorSimulator

        % Movement Parameters
        jointStep = 0.05  % radians per button press
        cartesianStep = 0.01  % meters per button press

        % State
        isInitialized = false

        % Demo State Management
        isDemoRunning = false
        demoPaused = false
    end

    methods
        %% Constructor
        function self = RobotGUI(robots, bookManager)
            fprintf('Initializing Robot Control GUI...\n');

            % Store robot references
            self.robots = robots;
            self.bookManager = bookManager;

            % Create safety systems
            self.eStopManager = EStopManager();
            self.sensorSimulator = SensorSimulator();

            % Create GUI
            self.CreateGUI();

            % Initialize
            self.isInitialized = true;

            fprintf('GUI Initialized Successfully!\n');
        end

        %% Create GUI Components
        function CreateGUI(self)
            % Create main figure
            self.fig = uifigure('Name', 'Robot Control System - Lab Assignment 2', ...
                'Position', [100 100 1000 700], ...
                'Color', [0.95 0.95 0.95]);

            % Create main grid layout
            mainGrid = uigridlayout(self.fig, [1 3]);
            mainGrid.ColumnWidth = {'1.5x', '2x', '1.5x'};

            % Left Panel: E-Stop & Status
            self.CreateLeftPanel(mainGrid);

            % Center Panel: Joint Control
            self.CreateCenterPanel(mainGrid);

            % Right Panel: Cartesian Control
            self.CreateRightPanel(mainGrid);
        end

        %% Left Panel: E-Stop and Status
        function CreateLeftPanel(self, parent)
            leftPanel = uipanel(parent, 'Title', 'SAFETY & STATUS', ...
                'FontWeight', 'bold', 'FontSize', 12, ...
                'BackgroundColor', [0.98 0.98 0.98]);

            grid = uigridlayout(leftPanel, [11 1]);
            grid.RowHeight = {'fit', 'fit', '1x', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x'};

            % E-STOP BUTTON (Large, Red)
            self.buttons.estop = uibutton(grid, 'push', ...
                'Text', '🛑 EMERGENCY STOP', ...
                'FontSize', 18, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.8 0.1 0.1], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(btn,event) self.OnEStopPressed());

            % RESUME BUTTON (Initially disabled)
            self.buttons.resume = uibutton(grid, 'push', ...
                'Text', '▶ RESUME OPERATIONS', ...
                'FontSize', 14, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.2 0.6 0.2], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(btn,event) self.OnResumePressed());

            % Status Display
            statusPanel = uipanel(grid, 'Title', 'System Status', ...
                'BackgroundColor', 'white');
            statusGrid = uigridlayout(statusPanel, [6 1]);
            statusGrid.RowHeight = repmat({'fit'}, 1, 6);

            self.labels.systemStatus = uilabel(statusGrid, ...
                'Text', '● System: OPERATIONAL', ...
                'FontSize', 11, 'FontWeight', 'bold', ...
                'FontColor', [0 0.6 0]);

            self.labels.estopStatus = uilabel(statusGrid, ...
                'Text', '○ E-Stop: READY', ...
                'FontSize', 11);

            self.labels.sensorStatus = uilabel(statusGrid, ...
                'Text', '○ Sensors: CLEAR', ...
                'FontSize', 11);

            self.labels.robotStatus = uilabel(statusGrid, ...
                'Text', '○ Robot: LinearUR3', ...
                'FontSize', 11);

            self.labels.collisionStatus = uilabel(statusGrid, ...
                'Text', '○ Collision: NONE', ...
                'FontSize', 11);

            self.labels.booksStatus = uilabel(statusGrid, ...
                'Text', '○ Books: 0/6 Sorted', ...
                'FontSize', 11);

            % Robot Selection
            uilabel(grid, 'Text', 'Select Robot:', 'FontWeight', 'bold');
            self.buttons.robotSelect = uidropdown(grid, ...
                'Items', {'LinearUR3', 'MotomanGP4', 'KukaKr3R540', 'AuboI5'}, ...
                'Value', 'LinearUR3', ...
                'ValueChangedFcn', @(dd,event) self.OnRobotSelected(dd.Value));

            % SENSOR TEST BUTTON
            self.buttons.sensorTest = uibutton(grid, 'push', ...
                'Text', '🔴 TRIGGER SENSOR', ...
                'FontSize', 12, ...
                'BackgroundColor', [0.9 0.6 0.2], ...
                'ButtonPushedFcn', @(btn,event) self.OnSensorTriggered());

            % RESET SYSTEM BUTTON
            self.buttons.reset = uibutton(grid, 'push', ...
                'Text', '🔄 RESET SYSTEM', ...
                'FontSize', 12, ...
                'BackgroundColor', [0.3 0.5 0.8], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(btn,event) self.OnResetSystem());

            % START DEMO BUTTON
            self.buttons.startDemo = uibutton(grid, 'push', ...
                'Text', '▶ START BOOK DEMO', ...
                'FontSize', 14, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.2 0.7 0.3], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(btn,event) self.OnStartDemo());
        end

        %% Center Panel: Joint Control
        function CreateCenterPanel(self, parent)
            centerPanel = uipanel(parent, 'Title', 'JOINT CONTROL (TEACH MODE)', ...
                'FontWeight', 'bold', 'FontSize', 12, ...
                'BackgroundColor', [0.98 0.98 0.98]);

            grid = uigridlayout(centerPanel, [8 1]);
            grid.RowHeight = repmat({'fit'}, 1, 8);

            % Instructions
            uilabel(grid, 'Text', 'Use buttons to jog individual joints:', ...
                'FontSize', 10, 'HorizontalAlignment', 'center');

            % Create joint controls for 7 joints (LinearUR3 has prismatic + 6 revolute)
            self.sliders.joints = cell(7, 1);
            self.labels.jointValues = cell(7, 1);
            self.buttons.jointMinus = cell(7, 1);
            self.buttons.jointPlus = cell(7, 1);

            for i = 1:7
                % Joint panel
                jointPanel = uipanel(grid, 'BackgroundColor', 'white');
                jointGrid = uigridlayout(jointPanel, [2 4]);
                jointGrid.ColumnWidth = {'fit', '1x', 'fit', 'fit'};

                % Joint label
                if i == 1
                    jointLabel = sprintf('J%d (Prismatic)', i);
                else
                    jointLabel = sprintf('J%d', i);
                end
                uilabel(jointGrid, 'Text', jointLabel, 'FontWeight', 'bold');

                % Value display
                self.labels.jointValues{i} = uilabel(jointGrid, ...
                    'Text', '0.00°', 'HorizontalAlignment', 'center');

                % Minus button
                self.buttons.jointMinus{i} = uibutton(jointGrid, 'push', ...
                    'Text', '◀', ...
                    'ButtonPushedFcn', @(btn,event) self.OnJointJog(i, -1));

                % Plus button
                self.buttons.jointPlus{i} = uibutton(jointGrid, 'push', ...
                    'Text', '▶', ...
                    'ButtonPushedFcn', @(btn,event) self.OnJointJog(i, 1));

                % Skip slider creation for space
            end

            % Home Position Button
            self.buttons.home = uibutton(grid, 'push', ...
                'Text', '🏠 MOVE TO HOME', ...
                'FontSize', 12, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.4 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(btn,event) self.OnMoveHome());
        end

        %% Right Panel: Cartesian Control
        function CreateRightPanel(self, parent)
            rightPanel = uipanel(parent, 'Title', 'CARTESIAN CONTROL', ...
                'FontWeight', 'bold', 'FontSize', 12, ...
                'BackgroundColor', [0.98 0.98 0.98]);

            grid = uigridlayout(rightPanel, [10 1]);
            grid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x', 'fit'};

            % Instructions
            uilabel(grid, 'Text', 'Control end-effector position (meters):', ...
                'FontSize', 10, 'HorizontalAlignment', 'center');

            % X Control
            xPanel = uipanel(grid, 'Title', 'X Position', 'BackgroundColor', 'white');
            xGrid = uigridlayout(xPanel, [1 3]);
            xGrid.ColumnWidth = {'fit', '1x', 'fit'};

            self.buttons.xMinus = uibutton(xGrid, 'push', 'Text', '◀ -X', ...
                'ButtonPushedFcn', @(btn,event) self.OnCartesianJog('x', -1));
            self.labels.xValue = uilabel(xGrid, 'Text', '0.000 m', ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            self.buttons.xPlus = uibutton(xGrid, 'push', 'Text', '+X ▶', ...
                'ButtonPushedFcn', @(btn,event) self.OnCartesianJog('x', 1));

            % Y Control
            yPanel = uipanel(grid, 'Title', 'Y Position', 'BackgroundColor', 'white');
            yGrid = uigridlayout(yPanel, [1 3]);
            yGrid.ColumnWidth = {'fit', '1x', 'fit'};

            self.buttons.yMinus = uibutton(yGrid, 'push', 'Text', '◀ -Y', ...
                'ButtonPushedFcn', @(btn,event) self.OnCartesianJog('y', -1));
            self.labels.yValue = uilabel(yGrid, 'Text', '0.000 m', ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            self.buttons.yPlus = uibutton(yGrid, 'push', 'Text', '+Y ▶', ...
                'ButtonPushedFcn', @(btn,event) self.OnCartesianJog('y', 1));

            % Z Control
            zPanel = uipanel(grid, 'Title', 'Z Position', 'BackgroundColor', 'white');
            zGrid = uigridlayout(zPanel, [1 3]);
            zGrid.ColumnWidth = {'fit', '1x', 'fit'};

            self.buttons.zMinus = uibutton(zGrid, 'push', 'Text', '▼ -Z', ...
                'ButtonPushedFcn', @(btn,event) self.OnCartesianJog('z', -1));
            self.labels.zValue = uilabel(zGrid, 'Text', '0.000 m', ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            self.buttons.zPlus = uibutton(zGrid, 'push', 'Text', '+Z ▲', ...
                'ButtonPushedFcn', @(btn,event) self.OnCartesianJog('z', 1));

            % Step Size Control
            stepPanel = uipanel(grid, 'Title', 'Step Size', 'BackgroundColor', 'white');
            stepGrid = uigridlayout(stepPanel, [2 2]);

            uilabel(stepGrid, 'Text', 'Joint Step (rad):');
            self.textFields.jointStep = uieditfield(stepGrid, 'numeric', ...
                'Value', self.jointStep, 'Limits', [0.001 0.5], ...
                'ValueChangedFcn', @(ef,event) self.OnStepChanged('joint', ef.Value));

            uilabel(stepGrid, 'Text', 'Cartesian Step (m):');
            self.textFields.cartStep = uieditfield(stepGrid, 'numeric', ...
                'Value', self.cartesianStep, 'Limits', [0.001 0.1], ...
                'ValueChangedFcn', @(ef,event) self.OnStepChanged('cart', ef.Value));

            % Current Position Display
            posPanel = uipanel(grid, 'Title', 'Current EE Position', ...
                'BackgroundColor', 'white');
            posGrid = uigridlayout(posPanel, [3 1]);

            self.labels.currentPos = uilabel(posGrid, 'Text', 'X: 0.000 m', 'FontSize', 9);
            uilabel(posGrid, 'Text', 'Y: 0.000 m', 'FontSize', 9);
            uilabel(posGrid, 'Text', 'Z: 0.000 m', 'FontSize', 9);

            % Update Display Button
            self.buttons.updateDisplay = uibutton(grid, 'push', ...
                'Text', '🔄 UPDATE DISPLAY', ...
                'ButtonPushedFcn', @(btn,event) self.UpdateDisplay());
        end

        %% Callback: E-Stop Pressed
        function OnEStopPressed(self)
            fprintf('\n*** EMERGENCY STOP ACTIVATED ***\n');

            % Activate e-stop
            self.eStopManager.Activate();

            % Set pause flag if demo is running
            if self.isDemoRunning
                self.demoPaused = true;
                fprintf('Demo PAUSED - will stop at next movement step.\n');
            end

            % Update GUI
            self.buttons.estop.BackgroundColor = [1 0 0];
            self.buttons.estop.Text = '⛔ E-STOP ACTIVE';
            self.buttons.estop.Enable = 'off';

            self.buttons.resume.Enable = 'on';

            self.labels.systemStatus.Text = '● System: E-STOP ACTIVE';
            self.labels.systemStatus.FontColor = [1 0 0];

            self.labels.estopStatus.Text = '● E-Stop: ENGAGED';
            self.labels.estopStatus.FontColor = [1 0 0];

            % Disable all movement controls
            self.SetMovementControlsEnabled(false);

            fprintf('All operations halted. Press RESUME to continue.\n');
        end

        %% Callback: Resume Pressed
        function OnResumePressed(self)
            fprintf('\n*** RESUMING OPERATIONS ***\n');

            % Check if e-stop can be disengaged
            if self.eStopManager.CanResume()
                self.eStopManager.Resume();

                % Clear pause flag to resume demo
                self.demoPaused = false;

                % Update GUI
                self.buttons.estop.BackgroundColor = [0.8 0.1 0.1];
                self.buttons.estop.Text = '🛑 EMERGENCY STOP';
                self.buttons.estop.Enable = 'on';

                self.buttons.resume.Enable = 'off';

                self.labels.systemStatus.Text = '● System: OPERATIONAL';
                self.labels.systemStatus.FontColor = [0 0.6 0];

                self.labels.estopStatus.Text = '○ E-Stop: READY';
                self.labels.estopStatus.FontColor = [0 0 0];

                % Re-enable movement controls (but not if demo is running)
                if ~self.isDemoRunning
                    self.SetMovementControlsEnabled(true);
                end

                fprintf('System resumed successfully.\n');
                if self.isDemoRunning
                    fprintf('Demo will continue from current position.\n');
                end
            else
                fprintf('ERROR: Cannot resume - e-stop still engaged\n');
            end
        end


        %% Callback: Robot Selected
        function OnRobotSelected(self, robotName)
            robotMap = containers.Map(...
                {'LinearUR3', 'MotomanGP4', 'KukaKr3R540', 'AuboI5'}, ...
                {1, 2, 3, 4});

            if isKey(robotMap, robotName)
                self.selectedRobotIndex = robotMap(robotName);
                self.labels.robotStatus.Text = sprintf('○ Robot: %s', robotName);
                self.UpdateDisplay();
                fprintf('Selected robot: %s\n', robotName);
            end
        end

        %% Callback: Joint Jog
        function OnJointJog(self, jointIndex, direction)
            % Check e-stop
            if ~self.eStopManager.IsOperational()
                fprintf('Cannot move: E-Stop active\n');
                return;
            end

            % Check sensors
            if self.sensorSimulator.IsTriggered()
                fprintf('Cannot move: Safety sensor triggered\n');
                return;
            end

            robot = self.robots{self.selectedRobotIndex};

            try
                % Get current joint angles
                q = robot.model.getpos();

                % Calculate new joint angle
                q(jointIndex) = q(jointIndex) + direction * self.jointStep;

                % Check joint limits
                if ~isempty(robot.model.links(jointIndex).qlim)
                    qmin = robot.model.links(jointIndex).qlim(1);
                    qmax = robot.model.links(jointIndex).qlim(2);
                    q(jointIndex) = max(qmin, min(qmax, q(jointIndex)));
                end

                % Animate
                robot.model.animate(q);
                drawnow();

                % Update display
                self.UpdateDisplay();

            catch ME
                fprintf('Error jogging joint %d: %s\n', jointIndex, ME.message);
            end
        end

        %% Callback: Cartesian Jog
        function OnCartesianJog(self, axis, direction)
            % Check e-stop
            if ~self.eStopManager.IsOperational()
                fprintf('Cannot move: E-Stop active\n');
                return;
            end

            % Check sensors
            if self.sensorSimulator.IsTriggered()
                fprintf('Cannot move: Safety sensor triggered\n');
                return;
            end

            robot = self.robots{self.selectedRobotIndex};

            try
                % Get current pose
                q = robot.model.getpos();
                T = robot.model.fkineUTS(q);
                currentPos = T(1:3, 4);

                % Calculate new position
                newPos = currentPos;
                switch axis
                    case 'x'
                        newPos(1) = newPos(1) + direction * self.cartesianStep;
                    case 'y'
                        newPos(2) = newPos(2) + direction * self.cartesianStep;
                    case 'z'
                        newPos(3) = newPos(3) + direction * self.cartesianStep;
                        % Safety check for Z
                        if newPos(3) < 0.01
                            newPos(3) = 0.01;
                            fprintf('Z limit reached (table collision prevention)\n');
                        end
                end

                % Create target transform (keep same orientation)
                Tnew = T;
                Tnew(1:3, 4) = newPos;

                % Solve IK
                qNew = robot.model.ikcon(Tnew, q);

                if ~any(isnan(qNew))
                    robot.model.animate(qNew);
                    drawnow();
                    self.UpdateDisplay();
                else
                    fprintf('IK failed for target position\n');
                end

            catch ME
                fprintf('Error moving in %s: %s\n', axis, ME.message);
            end
        end

        %% Callback: Move Home
        function OnMoveHome(self)
            if ~self.eStopManager.IsOperational()
                fprintf('Cannot move: E-Stop active\n');
                return;
            end

            robot = self.robots{self.selectedRobotIndex};

            try
                qCurrent = robot.model.getpos();
                qHome = zeros(1, length(qCurrent));

                qTraj = jtraj(qCurrent, qHome, 30);

                for i = 1:size(qTraj, 1)
                    if ~self.eStopManager.IsOperational()
                        fprintf('Movement interrupted by E-Stop\n');
                        return;
                    end

                    robot.model.animate(qTraj(i, :));
                    drawnow();
                    pause(0.02);
                end

                self.UpdateDisplay();
                fprintf('Robot moved to home position\n');

            catch ME
                fprintf('Error moving home: %s\n', ME.message);
            end
        end

        %% Callback: Sensor Triggered
        function OnSensorTriggered(self)
            if self.sensorSimulator.IsTriggered()
                % Clear sensor
                self.sensorSimulator.Clear();
                self.labels.sensorStatus.Text = '○ Sensors: CLEAR';
                self.labels.sensorStatus.FontColor = [0 0 0];
                self.buttons.sensorTest.Text = '🔴 TRIGGER SENSOR';
                fprintf('Light curtain cleared\n');
            else
                % Trigger sensor
                self.sensorSimulator.Trigger();
                self.labels.sensorStatus.Text = '● Sensors: BREACHED!';
                self.labels.sensorStatus.FontColor = [1 0.5 0];
                self.buttons.sensorTest.Text = '✓ CLEAR SENSOR';
                fprintf('Light curtain breached - movement blocked\n');
            end
        end

        %% Callback: Reset System
        function OnResetSystem(self)
            fprintf('\n════════════════════════════════════════════════════════\n');
            fprintf('   RESETTING ENTIRE SYSTEM\n');
            fprintf('════════════════════════════════════════════════════════\n\n');

            % Clear e-stop if active
            if ~self.eStopManager.IsOperational()
                fprintf('Clearing E-Stop...\n');
                self.eStopManager.Reset();
            end

            % Clear sensors
            fprintf('Clearing sensors...\n');
            self.sensorSimulator.Clear();

            % Reset demo state
            self.isDemoRunning = false;
            self.demoPaused = false;

            % Move all robots to home positions
            fprintf('Moving all robots to home positions...\n');
            for i = 1:length(self.robots)
                robot = self.robots{i};
                try
                    % Get home position (all zeros for all joints)
                    qCurrent = robot.model.getpos();
                    homeQ = zeros(1, length(qCurrent));

                    % Create smooth trajectory to home
                    steps = 30;
                    qTraj = jtraj(qCurrent, homeQ, steps);

                    % Animate to home position
                    for j = 1:steps
                        robot.model.animate(qTraj(j, :));
                        drawnow();
                        pause(0.02);
                    end

                    fprintf('  ✓ Robot %d moved to home\n', i);
                catch ME
                    fprintf('  ⚠ Warning: Could not move robot %d to home: %s\n', i, ME.message);
                end
            end

            % Clear all books from the scene
            fprintf('Clearing all books...\n');
            try
                % Find all book objects in the scene
                h = findobj('Type', 'patch');
                for i = 1:length(h)
                    % Check if this is a book object
                    vertices = get(h(i), 'Vertices');
                    if ~isempty(vertices)
                        % Delete if it looks like a book (has vertices)
                        faceColor = get(h(i), 'FaceColor');
                        if isnumeric(faceColor) && length(faceColor) == 3
                            % Check if it's a colored object (likely a book)
                            if any(faceColor == [0 1 0]) || any(faceColor == [0 0 1]) || any(faceColor == [1 0 0])
                                delete(h(i));
                            end
                        end
                    end
                end
                fprintf('  ✓ Books cleared\n');
            catch ME
                fprintf('  ⚠ Warning: Could not clear all books: %s\n', ME.message);
            end

            % Respawn books at original positions
            fprintf('Respawning books at original positions...\n');
            try
                BookSpawner.spawnBooks();
                fprintf('  ✓ Books respawned: 6 books (2 red, 2 green, 2 blue)\n');
            catch ME
                fprintf('  ⚠ Warning: Could not respawn books: %s\n', ME.message);
            end

            % Reset book manager
            fprintf('Resetting book manager...\n');
            try
                self.bookManager.reset();
                self.bookManager.storeBookHandles();
                fprintf('  ✓ Book manager reset\n');
            catch ME
                fprintf('  ⚠ Warning: Could not reset book manager: %s\n', ME.message);
            end

            % Update GUI
            self.buttons.estop.BackgroundColor = [0.8 0.1 0.1];
            self.buttons.estop.Text = '🛑 EMERGENCY STOP';
            self.buttons.estop.Enable = 'on';
            self.buttons.resume.Enable = 'off';

            self.buttons.startDemo.Enable = 'on';
            self.buttons.startDemo.Text = '▶ START BOOK DEMO';
            self.buttons.startDemo.BackgroundColor = [0.2 0.7 0.3];

            self.labels.systemStatus.Text = '● System: OPERATIONAL';
            self.labels.systemStatus.FontColor = [0 0.6 0];
            self.labels.estopStatus.Text = '○ E-Stop: READY';
            self.labels.estopStatus.FontColor = [0 0 0];
            self.labels.sensorStatus.Text = '○ Sensors: CLEAR';
            self.labels.sensorStatus.FontColor = [0 0 0];
            self.labels.booksStatus.Text = '○ Books: 0/6 Sorted';

            self.SetMovementControlsEnabled(true);

            fprintf('\n════════════════════════════════════════════════════════\n');
            fprintf('   SYSTEM RESET COMPLETE - Ready to run demo again!\n');
            fprintf('════════════════════════════════════════════════════════\n\n');
        end

        %% Callback: Step Size Changed
        function OnStepChanged(self, type, value)
            if strcmp(type, 'joint')
                self.jointStep = value;
            else
                self.cartesianStep = value;
            end
        end

        %% Update Display
        function UpdateDisplay(self)
            try
                robot = self.robots{self.selectedRobotIndex};
                q = robot.model.getpos();

                % Update joint values
                for i = 1:min(length(q), 7)
                    if i == 1 && length(q) == 7  % Prismatic joint
                        self.labels.jointValues{i}.Text = sprintf('%.3f m', q(i));
                    else
                        self.labels.jointValues{i}.Text = sprintf('%.2f°', rad2deg(q(i)));
                    end
                end

                % Update cartesian position
                T = robot.model.fkineUTS(q);
                pos = T(1:3, 4);

                self.labels.xValue.Text = sprintf('%.3f m', pos(1));
                self.labels.yValue.Text = sprintf('%.3f m', pos(2));
                self.labels.zValue.Text = sprintf('%.3f m', pos(3));

            catch ME
                fprintf('Display update error: %s\n', ME.message);
            end
        end

        %% Enable/Disable Movement Controls
        function SetMovementControlsEnabled(self, enabled)
            enableStr = 'on';
            if ~enabled
                enableStr = 'off';
            end

            % Joint controls
            for i = 1:7
                if ~isempty(self.buttons.jointMinus{i})
                    self.buttons.jointMinus{i}.Enable = enableStr;
                    self.buttons.jointPlus{i}.Enable = enableStr;
                end
            end

            % Cartesian controls
            self.buttons.xMinus.Enable = enableStr;
            self.buttons.xPlus.Enable = enableStr;
            self.buttons.yMinus.Enable = enableStr;
            self.buttons.yPlus.Enable = enableStr;
            self.buttons.zMinus.Enable = enableStr;
            self.buttons.zPlus.Enable = enableStr;
            self.buttons.home.Enable = enableStr;
        end

        %% Check if system is operational
        function operational = IsOperational(self)
            operational = self.eStopManager.IsOperational() && ...
                         ~self.sensorSimulator.IsTriggered();
        end

        %% Callback: Start Demo
        function OnStartDemo(self)
            fprintf('\n════════════════════════════════════════════════════════\n');
            fprintf('   STARTING AUTOMATED BOOK SORTING DEMO\n');
            fprintf('════════════════════════════════════════════════════════\n\n');

            % Check if system is operational
            if ~self.IsOperational()
                fprintf('ERROR: Cannot start demo - System not operational\n');
                if ~self.eStopManager.IsOperational()
                    fprintf('  - E-Stop is active. Press RESUME to continue.\n');
                end
                if self.sensorSimulator.IsTriggered()
                    fprintf('  - Safety sensor is triggered. Clear sensor to continue.\n');
                end
                return;
            end

            % Set demo state flags
            self.isDemoRunning = true;
            self.demoPaused = false;

            % Update GUI - disable start during demo
            self.buttons.startDemo.Enable = 'off';
            self.buttons.startDemo.Text = '⏳ DEMO RUNNING...';

            try
                % Run automated sorting
                self.RunAutomatedSorting();

                fprintf('\n════════════════════════════════════════════════════════\n');
                fprintf('   DEMO COMPLETED SUCCESSFULLY!\n');
                fprintf('════════════════════════════════════════════════════════\n\n');
                self.buttons.startDemo.Text = '✓ DEMO COMPLETE';
                self.buttons.startDemo.BackgroundColor = [0.2 0.7 0.3];
            catch ME
                fprintf('\nERROR during demo: %s\n', ME.message);
                fprintf('Stack trace:\n');
                for i = 1:length(ME.stack)
                    fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
                end
                self.buttons.startDemo.Text = '❌ DEMO FAILED';
                self.buttons.startDemo.BackgroundColor = [0.8 0.1 0.1];
            end

            % Reset demo state
            self.isDemoRunning = false;
            self.demoPaused = false;

            % Re-enable demo button
            pause(2);
            self.buttons.startDemo.Enable = 'on';
            self.buttons.startDemo.Text = '▶ START BOOK DEMO';
            self.buttons.startDemo.BackgroundColor = [0.2 0.7 0.3];
        end

        %% Run Automated Sorting
        function RunAutomatedSorting(self)
            fprintf('E-Stop and sensor monitoring is ACTIVE during operation\n');
            fprintf('Press E-Stop button in GUI to halt at any time\n');
            fprintf('Press RESET SYSTEM button to stop and reset the entire system\n\n');

            % Phase 1: UR3 Sorting
            fprintf('════ PHASE 1: UR3 SORTING BOOKS ════\n');
            if self.CheckSafetyAndState()
                self.BookPickAndPlaceWithSafety(self.robots{1});
            else
                return;
            end

            % Phase 2: Motoman Red Books
            fprintf('\n════ PHASE 2: MOTOMAN PICKING RED BOOKS ════\n');
            if self.CheckSafetyAndState()
                self.MotomanPickAndPlaceWithSafety(self.robots{2}, [4, 3]);
            else
                return;
            end

            % Phase 3: KUKA Green Books
            fprintf('\n════ PHASE 3: KUKA PICKING GREEN BOOKS ════\n');
            if self.CheckSafetyAndState()
                self.KukaPickAndPlaceWithSafety(self.robots{3}, [2, 1]);
            else
                return;
            end

            % Phase 4: AUBO Blue Books
            fprintf('\n════ PHASE 4: AUBO PICKING BLUE BOOKS ════\n');
            if self.CheckSafetyAndState()
                self.AuboPickAndPlaceWithSafety(self.robots{4}, [6, 5]);
            else
                return;
            end
        end

        %% Safety Check Function
        function safe = CheckSafety(self)
            safe = self.IsOperational();

            if ~safe
                if ~self.eStopManager.IsOperational()
                    fprintf('⚠ OPERATION HALTED: E-Stop is active\n');
                    fprintf('⚠ Disengage E-Stop and press RESUME to continue\n');
                elseif self.sensorSimulator.IsTriggered()
                    fprintf('⚠ OPERATION HALTED: Safety sensor triggered\n');
                    fprintf('⚠ Clear sensor to continue\n');
                end
            end
        end

        %% Safety and State Check Function (includes pause checks)
        function safe = CheckSafetyAndState(self)
            % Wait while demo is paused
            while self.demoPaused
                fprintf('⏸ Demo PAUSED - waiting for resume...\n');
                pause(0.5);
                drawnow();  % Process GUI events
            end

            % Now check safety systems
            safe = self.IsOperational();

            if ~safe
                if ~self.eStopManager.IsOperational()
                    fprintf('⚠ OPERATION HALTED: E-Stop is active\n');
                    fprintf('⚠ Disengage E-Stop and press RESUME to continue\n');
                elseif self.sensorSimulator.IsTriggered()
                    fprintf('⚠ OPERATION HALTED: Safety sensor triggered\n');
                    fprintf('⚠ Clear sensor to continue\n');
                end
            end
        end

        %% Safety-Wrapped Pick and Place Functions
        function BookPickAndPlaceWithSafety(self, robot)
            % Wrapper that checks e-stop before calling BookPickAndPlace
            if ~self.CheckSafetyAndState()
                fprintf('Book sorting interrupted by safety system\n');
                return;
            end

            % Call original function with GUI reference for state checking
            BookPickAndPlace(robot, self.bookManager, self);

            % Update books status
            self.labels.booksStatus.Text = '○ Books: 6/6 Sorted (UR3)';
        end

        function MotomanPickAndPlaceWithSafety(self, robot, bookIndices)
            if ~self.CheckSafetyAndState()
                fprintf('Motoman operation interrupted by safety system\n');
                return;
            end

            MotomanPickAndPlace(robot, self.bookManager, bookIndices, self);

            % Update books status
            self.labels.booksStatus.Text = '○ Books: Red Books Stacked';
        end

        function KukaPickAndPlaceWithSafety(self, robot, bookIndices)
            if ~self.CheckSafetyAndState()
                fprintf('Kuka operation interrupted by safety system\n');
                return;
            end

            KukaPickAndPlace(robot, self.bookManager, bookIndices, self);

            % Update books status
            self.labels.booksStatus.Text = '○ Books: Green Books Stacked';
        end

        function AuboPickAndPlaceWithSafety(self, robot, bookIndices)
            if ~self.CheckSafetyAndState()
                fprintf('Aubo operation interrupted by safety system\n');
                return;
            end

            AuboPickAndPlace(robot, self.bookManager, bookIndices, self);

            % Update books status
            self.labels.booksStatus.Text = '○ Books: All Complete!';
        end
    end
end
