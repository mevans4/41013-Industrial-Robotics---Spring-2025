classdef CollisionDetection < handle
    % CollisionDetection - System for detecting and avoiding robot collisions
    % Supports enable/disable toggle and demonstration of collision avoidance

    properties
        isEnabled = true  % Collision detection enabled by default
        robots            % Cell array of robot objects
        safetyDistance = 0.3  % Minimum safe distance between robots (meters)
        collisionDetected = false
        lastCollisionInfo = struct()
    end

    methods
        %% Constructor
        function self = CollisionDetection(robots)
            self.robots = robots;
            fprintf('[COLLISION DETECTION] Initialized with %d robots\n', length(robots));
            fprintf('[COLLISION DETECTION] Safety distance: %.2f meters\n', self.safetyDistance);
        end

        %% Enable/Disable Collision Detection
        function Enable(self)
            self.isEnabled = true;
            fprintf('[COLLISION DETECTION] ENABLED\n');
        end

        function Disable(self)
            self.isEnabled = false;
            fprintf('[COLLISION DETECTION] DISABLED\n');
        end

        function enabled = IsEnabled(self)
            enabled = self.isEnabled;
        end

        %% Check for collisions between all robots
        function [collision, details] = CheckAllRobots(self)
            collision = false;
            details = struct();

            if ~self.isEnabled
                return;
            end

            % Check each pair of robots
            for i = 1:length(self.robots)-1
                for j = i+1:length(self.robots)
                    [pairCollision, distance] = self.CheckRobotPair(i, j);

                    if pairCollision
                        collision = true;
                        details.robot1 = i;
                        details.robot2 = j;
                        details.distance = distance;
                        details.safetyDistance = self.safetyDistance;

                        self.collisionDetected = true;
                        self.lastCollisionInfo = details;

                        fprintf('[COLLISION DETECTED] Robot %d and Robot %d are too close (%.3f m < %.3f m)\n', ...
                            i, j, distance, self.safetyDistance);
                        return;
                    end
                end
            end

            if self.collisionDetected && ~collision
                fprintf('[COLLISION CLEARED] All robots at safe distances\n');
                self.collisionDetected = false;
            end
        end

        %% Check collision between two specific robots
        function [collision, distance] = CheckRobotPair(self, idx1, idx2)
            collision = false;
            distance = inf;

            try
                robot1 = self.robots{idx1};
                robot2 = self.robots{idx2};

                % Get current end-effector positions
                q1 = robot1.model.getpos();
                q2 = robot2.model.getpos();

                T1 = robot1.model.fkineUTS(q1);
                T2 = robot2.model.fkineUTS(q2);

                pos1 = T1(1:3, 4);
                pos2 = T2(1:3, 4);

                % Calculate Euclidean distance
                distance = norm(pos1 - pos2);

                % Check if too close
                if distance < self.safetyDistance
                    collision = true;
                end

            catch ME
                fprintf('[COLLISION CHECK ERROR] %s\n', ME.message);
            end
        end

        %% Check if a planned position would cause collision
        function [wouldCollide, avoidancePos] = CheckPlannedPosition(self, robotIdx, plannedPos)
            wouldCollide = false;
            avoidancePos = plannedPos;

            if ~self.isEnabled
                return;
            end

            % Check distance to all other robots
            for i = 1:length(self.robots)
                if i == robotIdx
                    continue;
                end

                try
                    % Get other robot's current position
                    otherRobot = self.robots{i};
                    qOther = otherRobot.model.getpos();
                    TOther = otherRobot.model.fkineUTS(qOther);
                    posOther = TOther(1:3, 4);

                    % Calculate distance to planned position
                    distance = norm(plannedPos - posOther);

                    if distance < self.safetyDistance
                        wouldCollide = true;

                        fprintf('[COLLISION AVOIDANCE] Planned position too close to Robot %d\n', i);

                        % Calculate avoidance position (move away from other robot)
                        direction = (plannedPos - posOther) / norm(plannedPos - posOther);
                        avoidancePos = posOther + direction * (self.safetyDistance + 0.1);

                        fprintf('[COLLISION AVOIDANCE] Adjusted position: [%.3f, %.3f, %.3f]\n', ...
                            avoidancePos(1), avoidancePos(2), avoidancePos(3));

                        return;
                    end
                catch ME
                    fprintf('[COLLISION CHECK ERROR] %s\n', ME.message);
                end
            end
        end

        %% Check trajectory for collisions
        function [safe, firstCollisionStep] = CheckTrajectory(self, robotIdx, trajectory)
            safe = true;
            firstCollisionStep = -1;

            if ~self.isEnabled
                return;
            end

            % Check each point in the trajectory
            for step = 1:size(trajectory, 1)
                targetPos = trajectory(step, 1:3);

                [wouldCollide, ~] = self.CheckPlannedPosition(robotIdx, targetPos);

                if wouldCollide
                    safe = false;
                    firstCollisionStep = step;
                    fprintf('[TRAJECTORY CHECK] Collision detected at step %d/%d\n', ...
                        step, size(trajectory, 1));
                    return;
                end
            end
        end

        %% Get collision status
        function status = GetStatus(self)
            if ~self.isEnabled
                status = 'DISABLED';
            elseif self.collisionDetected
                status = 'COLLISION DETECTED';
            else
                status = 'ACTIVE - NO COLLISION';
            end
        end

        %% Get last collision info
        function info = GetLastCollisionInfo(self)
            info = self.lastCollisionInfo;
        end

        %% Demonstrate collision avoidance
        function DemonstrateCollisionAvoidance(self)
            fprintf('\n════════════════════════════════════════════════════════\n');
            fprintf('   COLLISION AVOIDANCE DEMONSTRATION\n');
            fprintf('════════════════════════════════════════════════════════\n\n');

            if ~self.isEnabled
                fprintf('⚠ Collision detection is DISABLED\n');
                fprintf('Enable collision detection to run demonstration\n\n');
                return;
            end

            fprintf('This demonstration shows:\n');
            fprintf('  1. Real-time collision checking during robot movement\n');
            fprintf('  2. Automatic path adjustment to avoid collisions\n');
            fprintf('  3. Safe distance maintenance between robots\n\n');

            fprintf('Safety Distance: %.2f meters\n', self.safetyDistance);
            fprintf('Number of Robots: %d\n\n', length(self.robots));

            % Run collision check
            [collision, details] = self.CheckAllRobots();

            if collision
                fprintf('❌ COLLISION DETECTED:\n');
                fprintf('   Robot %d <-> Robot %d\n', details.robot1, details.robot2);
                fprintf('   Distance: %.3f m (minimum: %.3f m)\n', ...
                    details.distance, details.safetyDistance);
                fprintf('   Action: Robots will adjust paths to maintain safe distance\n\n');
            else
                fprintf('✓ NO COLLISIONS: All robots at safe distances\n\n');
            end

            fprintf('════════════════════════════════════════════════════════\n\n');
        end
    end
end
