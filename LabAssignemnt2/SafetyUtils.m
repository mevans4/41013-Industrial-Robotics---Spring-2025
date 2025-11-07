classdef SafetyUtils
    % SafetyUtils - Collection of safety validation functions for robot operations
    % Ensures robots do not violate workspace constraints

    properties (Constant)
        % Minimum safe Z height above table (z=0 is table surface)
        MIN_Z_HEIGHT = 0.01;  % 10mm clearance above table

        % Safety margin for warnings
        WARNING_Z_HEIGHT = 0.05;  % Warn if within 50mm of table
    end

    methods (Static)
        function [safePos, wasModified] = validateZPosition(targetPos, minZ)
            % validateZPosition - Ensures position is above minimum Z height
            %
            % Inputs:
            %   targetPos - [x, y, z] target position vector
            %   minZ - (optional) minimum Z height, defaults to MIN_Z_HEIGHT
            %
            % Outputs:
            %   safePos - validated position with Z clamped if necessary
            %   wasModified - true if position was clamped

            if nargin < 2
                minZ = SafetyUtils.MIN_Z_HEIGHT;
            end

            safePos = targetPos;
            wasModified = false;

            % Check if Z is below minimum safe height
            if targetPos(3) < minZ
                fprintf('*** SAFETY WARNING: Z-position %.4f is below table (z=0)!\n', targetPos(3));
                fprintf('*** Clamping to minimum safe height: %.4f\n', minZ);
                safePos(3) = minZ;
                wasModified = true;
            % Warning if close to table
            elseif targetPos(3) < SafetyUtils.WARNING_Z_HEIGHT
                fprintf('CAUTION: Z-position %.4f is close to table surface\n', targetPos(3));
            end
        end

        function [safeTraj, wasModified] = validateTrajectory(trajectory)
            % validateTrajectory - Validates entire trajectory stays above table
            %
            % Inputs:
            %   trajectory - Nx3 matrix of [x, y, z] positions
            %
            % Outputs:
            %   safeTraj - validated trajectory with Z clamped if necessary
            %   wasModified - true if any positions were clamped

            safeTraj = trajectory;
            wasModified = false;

            for i = 1:size(trajectory, 1)
                if trajectory(i, 3) < SafetyUtils.MIN_Z_HEIGHT
                    fprintf('*** TRAJECTORY SAFETY: Point %d has Z=%.4f below table\n', ...
                        i, trajectory(i, 3));
                    safeTraj(i, 3) = SafetyUtils.MIN_Z_HEIGHT;
                    wasModified = true;
                end
            end

            if wasModified
                fprintf('*** Trajectory modified to prevent table collision\n');
            end
        end

        function valid = checkEndEffectorHeight(robot, q)
            % checkEndEffectorHeight - Checks if joint config results in safe EE height
            %
            % Inputs:
            %   robot - robot object with model
            %   q - joint configuration
            %
            % Outputs:
            %   valid - true if end effector is above minimum height

            % Get end effector pose
            eePose = robot.model.fkine(q);

            % Extract position
            if isa(eePose, 'SE3')
                eePos = eePose.t';
            else
                eePos = eePose(1:3, 4)';
            end

            % Check height
            valid = eePos(3) >= SafetyUtils.MIN_Z_HEIGHT;

            if ~valid
                fprintf('*** SAFETY: Joint config results in EE below table (Z=%.4f)\n', ...
                    eePos(3));
            end
        end

        function displaySafetyStatus(position, label)
            % displaySafetyStatus - Display safety status of a position
            %
            % Inputs:
            %   position - [x, y, z] position vector
            %   label - descriptive label for the position

            zHeight = position(3);

            fprintf('[SAFETY CHECK] %s: Z=%.4f ', label, zHeight);

            if zHeight < 0
                fprintf('- CRITICAL: Below table!\n');
            elseif zHeight < SafetyUtils.MIN_Z_HEIGHT
                fprintf('- UNSAFE: Below minimum clearance\n');
            elseif zHeight < SafetyUtils.WARNING_Z_HEIGHT
                fprintf('- CAUTION: Close to table\n');
            else
                fprintf('- OK\n');
            end
        end
    end
end
