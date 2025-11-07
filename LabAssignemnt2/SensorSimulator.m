classdef SensorSimulator < handle
    % SensorSimulator - Simulated Safety Sensor System (Light Curtain)
    % Simulates active workspace sensing for safety demonstration
    % Meets assignment requirement: "react to simulated sensor input"

    properties
        % Sensor State
        isTriggered = false         % True when sensor detects intrusion
        triggerTime
        clearTime

        % Sensor Configuration
        sensorType = 'Light Curtain'
        sensorPosition = [0, 0, 0.5]  % Position in workspace
        detectionRadius = 0.3          % Detection zone radius (meters)

        % Visual Representation
        sensorPlotHandle
        zoneHandle

        % Intrusion Detection
        intrusionDetected = false
        intrusionPosition = []
        intrusionCount = 0
    end

    methods
        %% Constructor
        function self = SensorSimulator()
            fprintf('[SENSOR] Initializing safety sensor system...\n');
            self.isTriggered = false;
            self.intrusionDetected = false;
            fprintf('[SENSOR] %s initialized\n', self.sensorType);
            fprintf('[SENSOR] Detection zone radius: %.2f m\n', self.detectionRadius);
        end

        %% Trigger Sensor (Simulate breach)
        function Trigger(self)
            fprintf('\n╔════════════════════════════════════╗\n');
            fprintf('║   SAFETY SENSOR TRIGGERED          ║\n');
            fprintf('╚════════════════════════════════════╝\n');

            self.isTriggered = true;
            self.intrusionDetected = true;
            self.triggerTime = datetime('now');
            self.intrusionCount = self.intrusionCount + 1;

            fprintf('[SENSOR] ⚠ Light curtain breach detected!\n');
            fprintf('[SENSOR] ⚠ Time: %s\n', datestr(now, 'HH:MM:SS'));
            fprintf('[SENSOR] ⚠ All robot movements blocked\n');
            fprintf('[SENSOR] ⚠ Clear sensor to resume operations\n');

            % Could visualize sensor zone in red
            self.VisualizeTriggered();
        end

        %% Clear Sensor (Remove breach)
        function Clear(self)
            if self.isTriggered
                fprintf('\n[SENSOR] Clearing safety sensor...\n');

                self.isTriggered = false;
                self.intrusionDetected = false;
                self.clearTime = datetime('now');

                fprintf('[SENSOR] ✓ Sensor cleared at %s\n', datestr(now, 'HH:MM:SS'));
                fprintf('[SENSOR] ✓ Robot movements permitted\n');

                % Could visualize sensor zone in green
                self.VisualizeCleared();
            else
                fprintf('[SENSOR] Sensor already clear\n');
            end
        end

        %% Check if Sensor is Triggered
        function triggered = IsTriggered(self)
            triggered = self.isTriggered;
        end

        %% Simulate Continuous Monitoring (Check robot proximity)
        function breached = MonitorWorkspace(self, robotPositions)
            % Check if any robot is too close to sensor zone
            % robotPositions: Nx3 array of [x, y, z] positions

            breached = false;

            for i = 1:size(robotPositions, 1)
                distance = norm(robotPositions(i, :) - self.sensorPosition);

                if distance < self.detectionRadius
                    if ~self.isTriggered
                        fprintf('[SENSOR] ⚠ Robot %d entered detection zone!\n', i);
                        self.intrusionPosition = robotPositions(i, :);
                        self.Trigger();
                    end
                    breached = true;
                    return;
                end
            end

            % If previously triggered but no longer breached, auto-clear
            if self.isTriggered && ~breached
                fprintf('[SENSOR] Zone clear - auto-clearing sensor\n');
                self.Clear();
            end
        end

        %% Simulate Object Entering Workspace
        function SimulateIntrusionEvent(self, position)
            % Simulate external object (person, obstacle) entering workspace

            if nargin < 2
                position = [0.2, 0.3, 0.2];  % Default intrusion position
            end

            fprintf('\n[SENSOR] ⚠ Simulating workspace intrusion...\n');
            fprintf('[SENSOR] ⚠ Object detected at [%.2f, %.2f, %.2f]\n', ...
                position(1), position(2), position(3));

            self.intrusionPosition = position;
            self.Trigger();
        end

        %% Get Sensor Status String
        function status = GetStatus(self)
            if self.isTriggered
                status = 'BREACHED - Movement Blocked';
            else
                status = 'CLEAR - Monitoring';
            end
        end

        %% Get Status Details
        function details = GetStatusDetails(self)
            details = struct();
            details.isTriggered = self.isTriggered;
            details.sensorType = self.sensorType;
            details.intrusionDetected = self.intrusionDetected;
            details.intrusionCount = self.intrusionCount;
            details.statusString = self.GetStatus();

            if ~isempty(self.triggerTime)
                details.triggerTime = self.triggerTime;
            end
            if ~isempty(self.clearTime)
                details.clearTime = self.clearTime;
            end
            if ~isempty(self.intrusionPosition)
                details.intrusionPosition = self.intrusionPosition;
            end
        end

        %% Display Status
        function DisplayStatus(self)
            fprintf('\n┌─ SENSOR SYSTEM STATUS ─────────────┐\n');
            fprintf('│ Sensor Type:      %s\n', self.sensorType);
            fprintf('│ Status:           %s\n', self.GetStatus());
            fprintf('│ Is Triggered:     %s\n', self.BoolToString(self.isTriggered));
            fprintf('│ Intrusion Count:  %d\n', self.intrusionCount);

            if ~isempty(self.intrusionPosition)
                fprintf('│ Last Intrusion:   [%.2f, %.2f, %.2f]\n', ...
                    self.intrusionPosition(1), self.intrusionPosition(2), ...
                    self.intrusionPosition(3));
            end

            fprintf('└────────────────────────────────────┘\n\n');
        end

        %% Visualize Detection Zone (Triggered)
        function VisualizeTriggered(self)
            try
                % Draw red sphere at sensor position
                if ~isempty(self.zoneHandle) && ishandle(self.zoneHandle)
                    delete(self.zoneHandle);
                end

                [X, Y, Z] = sphere(20);
                X = X * self.detectionRadius + self.sensorPosition(1);
                Y = Y * self.detectionRadius + self.sensorPosition(2);
                Z = Z * self.detectionRadius + self.sensorPosition(3);

                hold on;
                self.zoneHandle = surf(X, Y, Z, ...
                    'FaceColor', [1 0 0], ...
                    'EdgeColor', 'none', ...
                    'FaceAlpha', 0.3);
                hold off;

                fprintf('[SENSOR] Visualized breach zone in red\n');
            catch ME
                % Visualization failed, not critical
                fprintf('[SENSOR] Could not visualize zone: %s\n', ME.message);
            end
        end

        %% Visualize Detection Zone (Cleared)
        function VisualizeCleared(self)
            try
                % Draw green sphere at sensor position
                if ~isempty(self.zoneHandle) && ishandle(self.zoneHandle)
                    delete(self.zoneHandle);
                end

                [X, Y, Z] = sphere(20);
                X = X * self.detectionRadius + self.sensorPosition(1);
                Y = Y * self.detectionRadius + self.sensorPosition(2);
                Z = Z * self.detectionRadius + self.sensorPosition(3);

                hold on;
                self.zoneHandle = surf(X, Y, Z, ...
                    'FaceColor', [0 1 0], ...
                    'EdgeColor', 'none', ...
                    'FaceAlpha', 0.2);
                hold off;

                fprintf('[SENSOR] Visualized safe zone in green\n');
            catch ME
                % Visualization failed, not critical
                fprintf('[SENSOR] Could not visualize zone: %s\n', ME.message);
            end
        end

        %% Remove Visualization
        function ClearVisualization(self)
            try
                if ~isempty(self.zoneHandle) && ishandle(self.zoneHandle)
                    delete(self.zoneHandle);
                end
                if ~isempty(self.sensorPlotHandle) && ishandle(self.sensorPlotHandle)
                    delete(self.sensorPlotHandle);
                end
            catch
                % Ignore cleanup errors
            end
        end

        %% Check Movement Permitted
        function permitted = IsMovementPermitted(self)
            % Returns true if robots can move (sensor not triggered)
            permitted = ~self.isTriggered;

            if ~permitted
                fprintf('[SENSOR] ⚠ Movement blocked by sensor\n');
            end
        end

        %% Simulate Sensor Test
        function RunSensorTest(self)
            fprintf('\n═══ SENSOR SYSTEM TEST ═══\n');

            fprintf('Step 1: Triggering sensor...\n');
            self.Trigger();
            pause(1);

            self.DisplayStatus();
            pause(1);

            fprintf('Step 2: Clearing sensor...\n');
            self.Clear();
            pause(1);

            self.DisplayStatus();

            fprintf('═══ SENSOR TEST COMPLETE ═══\n\n');
        end
    end

    methods (Access = private)
        %% Helper: Convert boolean to string
        function str = BoolToString(~, value)
            if value
                str = 'YES';
            else
                str = 'NO';
            end
        end
    end

    methods (Static)
        %% Static: Create Default Sensor
        function sensor = CreateDefaultSensor()
            sensor = SensorSimulator();
            fprintf('[SENSOR] Default sensor created\n');
        end

        %% Static: Create Sensor at Position
        function sensor = CreateSensorAt(position, radius)
            sensor = SensorSimulator();
            sensor.sensorPosition = position;
            if nargin > 1
                sensor.detectionRadius = radius;
            end
            fprintf('[SENSOR] Sensor created at [%.2f, %.2f, %.2f]\n', ...
                position(1), position(2), position(3));
        end
    end
end
