classdef LinearUR3_MotomanGP4_Collaboration < handle
    %% Two-Robot Collaboration with RMRC and Collision Avoidance
    
    properties
        robotLinear;
        robotMotoman;
        bookModels;
        bookPoses;
        
        % Obstacle properties
        obstacles;
        obstaclePositions;
        obstacleRadii;
        
        % Collision avoidance parameters
        safetyDistance = 0.15;
        obstacleAvoidDist = 0.12;
        repulsiveGain = 0.5;
        
        % RMRC parameters
        deltaT = 0.05;
        epsilon = 0.1;              % Manipulability threshold
        lambda = 0.01;              % Base damping coefficient
        lambdaMax = 0.5;            % Maximum damping when near singularity
        maxVelocity = 0.3;
        maxJointVel = 1.0;
        maxIterations = 200;        % Maximum RMRC iterations before fallback
        
        % Position parameters
        startPositions = [
            -0.2,  0.4, 0.15;
            -0.2,  0.4, 0.10;
            -0.2,  0.4, 0.05;
            -0.35,  0.4, 0.15;
            -0.35,  0.4, 0.10;
            -0.35,  0.4, 0.05;
            -0.55,  0.4, 0.15;
            -0.5,  0.4, 0.10;
            -0.5,  0.4, 0.05;
        ];
        
        handoffPosition = [0.0, 0.5, 0.11];
        
        endPositions = [
            0.8, 0.4, 0.11;
            0.8, 0.5, 0.11;
            0.8, 0.6, 0.11;
            0.8, 0.4, 0.22;
            0.8, 0.5, 0.22;
            0.8, 0.6, 0.22;
            0.8, 0.4, 0.33;
            0.8, 0.5, 0.33;
            0.8, 0.6, 0.33;
        ];
        
        bookHeight = 0.13;
        bookThickness = 0.04;
        approachHeight = 0.15;
        numSteps = 50;
        
        motomanGripperOffset = transl(0, 0, 0.06) ;%* trotx(-pi/2);
        linearGripperOffset = transl(0, 0, 0.06) ;%* trotx(-pi/2);
    end
    
    methods
        %% Constructor
        function self = LinearUR3_MotomanGP4_Collaboration()
            clf;
            hold on;
            
            self.SetupEnvironment();
            
            disp('Creating robots...');
            self.robotLinear = LinearUR3(transl(0.4, 0.7, 0));
            self.robotMotoman = MotomanGP4(transl(-0.3, 0.1, 0));
            
            self.CreateObstacles();
            self.InitializeBooks();
            self.MoveToHome();
            
            self.ExecuteCollaborativePickAndPlace();
            
            disp('Collaborative operation with RMRC and collision avoidance completed!');
        end
        
        %% Setup Environment
        function SetupEnvironment(self)
            axis([-2 2 -1 2 0 2]);
            view(3);
            xlabel('X (m)');
            ylabel('Y (m)');
            zlabel('Z (m)');
            title('Two-Robot Collaboration with RMRC & Collision Avoidance');
            grid on;
            
            surf([-1 1; -1 1], [-0.5 -0.5; 1 1], [0 0; 0 0], ...
                'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.5);
            
            [X, Y] = meshgrid([-0.6, -0.2], [0.3, 0.7]);
            Z = zeros(size(X)) + 0.04;
            surf(X, Y, Z, 'FaceColor', [0.6 0.4 0.2], 'FaceAlpha', 0.7);
            
            [X, Y] = meshgrid([1.0, 0.5], [0.3, 0.7]);
            Z = zeros(size(X)) + 0.04;
            surf(X, Y, Z, 'FaceColor', [0.6 0.4 0.2], 'FaceAlpha', 0.7);
            
            [X, Y] = meshgrid([-0.1, 0.1], [0.4, 0.6]);
            Z = zeros(size(X)) + 0.04;
            surf(X, Y, Z, 'FaceColor', [0.3 0.7 0.3], 'FaceAlpha', 0.4);
        end
        
        %% Create Obstacles
        function CreateObstacles(self)
            disp('Creating obstacles for collision avoidance demonstration...');
            
            % CHANGE OBSTACLE POSITIONS HERE
            self.obstaclePositions = [
                0.0, 0.4, 0.3;   % Obstacle 1
                0.2, 0.4, 0.2;   % Obstacle 2
            ];
            
            self.obstacleRadii = [0.08; 0.06];
            
            self.obstacles = cell(size(self.obstaclePositions, 1), 1);
            for i = 1:size(self.obstaclePositions, 1)
                [X, Y, Z] = sphere(20);
                X = X * self.obstacleRadii(i) + self.obstaclePositions(i, 1);
                Y = Y * self.obstacleRadii(i) + self.obstaclePositions(i, 2);
                Z = Z * self.obstacleRadii(i) + self.obstaclePositions(i, 3);
                self.obstacles{i} = surf(X, Y, Z, ...
                    'FaceColor', [1 0.3 0.3], 'EdgeColor', 'none', ...
                    'FaceAlpha', 0.6);
            end
        end
        
        %% Initialize Books
        function InitializeBooks(self)
            disp('Initializing books at start positions...');
            self.bookModels = cell(9, 1);
            self.bookPoses = zeros(4, 4, 9);
            
            for i = 1:9
                bookTr = transl(self.startPositions(i, :)) ;%* trotx(pi/2);
                self.bookPoses(:, :, i) = bookTr;
                
                [f, v, ~] = plyread('RedBook.ply', 'tri');
                v = v * 0.5;
                
                homV = [v, ones(size(v, 1), 1)]';
                transformedV = bookTr * homV;
                
                self.bookModels{i} = trisurf(f, transformedV(1,:), ...
                    transformedV(2,:), transformedV(3,:), ...
                    'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.8);
            end
        end
        
        %% Move to Home Position
        function MoveToHome(self)
            disp('Moving robots to home positions...');
            
            qHomeLinear = [0, -pi/2, 0, 0, 0, 0, 0];
            self.robotLinear.model.animate(qHomeLinear);
            
            qHomeMotoman = [0, 0, 0, 0, 0, 0];
            self.robotMotoman.model.animate(qHomeMotoman);
            
            drawnow();
            pause(0.5);
        end
        
        %% Execute Collaborative Pick and Place
        function ExecuteCollaborativePickAndPlace(self)
            for bookNum = 1:9
                fprintf('\n=== Processing book %d of 9 ===\n', bookNum);
                
                startPos = self.startPositions(bookNum, :);
                endPos = self.endPositions(bookNum, :);
                
                self.MotomanPickBookRMRC(bookNum, startPos);
                self.MotomanMoveToHandoffRMRC(bookNum);
                self.LinearMoveToHandoffRMRC();
                
                self.TransferBook(bookNum);
                
                self.MotomanRetreat();
                self.LinearStackBookRMRC(bookNum, endPos);
                self.LinearRetreat();
                
                pause(0.3);
            end
        end
        
        %% Helper: Get Transform Matrix
        function T = GetTransformMatrix(~, fkineResult)
            if isa(fkineResult, 'SE3')
                T = fkineResult.T;
            elseif isobject(fkineResult)
                T = fkineResult.T;
            else
                T = fkineResult;
            end
        end
        
        %% RMRC Movement with Collision Avoidance (FIXED VERSION)
        function MoveRobotRMRC(self, robotName, targetPos, targetRot, bookNum)
            if nargin < 5
                bookNum = [];
            end
            
            fprintf('    [RMRC] Moving %s with collision avoidance...\n', robotName);
            
            if strcmp(robotName, 'motoman')
                robot = self.robotMotoman;
                gripperOffset = self.motomanGripperOffset;
                otherRobot = self.robotLinear;
            else
                robot = self.robotLinear;
                gripperOffset = self.linearGripperOffset;
                otherRobot = self.robotMotoman;
            end
            
            targetTr = eye(4);
            targetTr(1:3, 1:3) = targetRot(1:3, 1:3);
            targetTr(1:3, 4) = targetPos(:);
            
            q = robot.model.getpos();
            
            iterCount = 0;
            stuckCounter = 0;
            lastError = inf;
            
            % RMRC loop with escape conditions
            while true
                iterCount = iterCount + 1;
                
                % Escape if stuck or max iterations
                if iterCount > self.maxIterations
                    fprintf('    [FALLBACK] Max iterations reached, using joint space planning\n');
                    self.FallbackJointSpace(robot, targetTr, gripperOffset, bookNum);
                    return;
                end
                
                % Current end-effector pose
                currentTr = robot.model.fkine(q);
                currentTrMatrix = self.GetTransformMatrix(currentTr);
                currentPos = currentTrMatrix(1:3, 4);
                
                % Position error
                deltaX = targetPos(:) - currentPos;
                posError = norm(deltaX);
                
                % Check if stuck (error not decreasing)
                if abs(posError - lastError) < 0.0001
                    stuckCounter = stuckCounter + 1;
                    if stuckCounter > 20
                        fprintf('    [FALLBACK] Stuck in singularity, using joint space planning\n');
                        self.FallbackJointSpace(robot, targetTr, gripperOffset, bookNum);
                        return;
                    end
                else
                    stuckCounter = 0;
                end
                lastError = posError;
                
                % Check if reached target
                if posError < 0.01
                    fprintf('    [RMRC] Target reached!\n');
                    break;
                end
                
                % Linear velocity towards target
                v = deltaX / norm(deltaX) * min(self.maxVelocity, posError * 5);
                
                % Get Jacobian
                J = robot.model.jacob0(q);
                Jv = J(1:3, :);
                
                % Check manipulability
                manipulability = sqrt(det(Jv * Jv'));
                
                % Adaptive damping based on manipulability
                if manipulability < self.epsilon
                    adaptiveLambda = self.lambdaMax * (1 - manipulability/self.epsilon);
                    if mod(iterCount, 10) == 0  % Print every 10 iterations
                        fprintf('    [WARNING] Near singularity (m = %.4f, lambda = %.3f)\n', ...
                            manipulability, adaptiveLambda);
                    end
                else
                    adaptiveLambda = self.lambda;
                end
                
                % Collision avoidance
                vRepulsive = self.CalculateRepulsiveVelocity(robot, q, otherRobot);
                vObstacle = self.CalculateObstacleAvoidance(robot, q);
                
                % Combined velocity
                vDesired = v + vRepulsive + vObstacle;
                
                % Damped Least Squares with adaptive damping
                JvT = Jv';
                qdot = JvT * inv(Jv * JvT + adaptiveLambda^2 * eye(3)) * vDesired;
                
                % Limit joint velocities
                qdot = self.LimitJointVelocities(qdot);
                
                % Update joint angles
                q = q + qdot' * self.deltaT;
                
                % Apply joint limits
                q = self.EnforceJointLimits(robot, q);
                
                % Animate
                robot.model.animate(q);
                
                % Update book if attached
                if ~isempty(bookNum)
                    endEffectorTr = robot.model.fkine(q);
                    endEffectorMatrix = self.GetTransformMatrix(endEffectorTr);
                    bookTr = endEffectorMatrix * gripperOffset;
                    self.UpdateBookPosition(bookNum, bookTr);
                end
                
                drawnow();
                pause(self.deltaT);
            end
        end
        
        %% Fallback to Joint Space Planning
        function FallbackJointSpace(self, robot, targetTr, gripperOffset, bookNum)
            fprintf('    [JOINT SPACE] Computing trajectory...\n');
            
            qCurrent = robot.model.getpos();
            qTarget = robot.model.ikcon(targetTr, qCurrent);
            
            qTraj = jtraj(qCurrent, qTarget, 30);
            
            for i = 1:size(qTraj, 1)
                robot.model.animate(qTraj(i, :));
                
                if ~isempty(bookNum)
                    endEffectorTr = robot.model.fkine(qTraj(i, :));
                    endEffectorMatrix = self.GetTransformMatrix(endEffectorTr);
                    bookTr = endEffectorMatrix * gripperOffset;
                    self.UpdateBookPosition(bookNum, bookTr);
                end
                
                drawnow();
            end
            
            fprintf('    [JOINT SPACE] Movement completed\n');
        end
        
        %% Calculate Repulsive Velocity
        function vRepulsive = CalculateRepulsiveVelocity(self, robot, q, otherRobot)
            vRepulsive = zeros(3, 1);
            
            currentTr = robot.model.fkine(q);
            currentTrMatrix = self.GetTransformMatrix(currentTr);
            currentPos = currentTrMatrix(1:3, 4);
            
            qOther = otherRobot.model.getpos();
            otherTr = otherRobot.model.fkine(qOther);
            otherTrMatrix = self.GetTransformMatrix(otherTr);
            otherPos = otherTrMatrix(1:3, 4);
            
            diff = currentPos - otherPos;
            distance = norm(diff);
            
            if distance < self.safetyDistance && distance > 0.01
                fprintf('    [COLLISION AVOIDANCE] Robot distance: %.3fm\n', distance);
                
                repulsiveMagnitude = self.repulsiveGain * ...
                    (1/distance - 1/self.safetyDistance) / distance^2;
                vRepulsive = repulsiveMagnitude * (diff / distance);
            end
        end
        
        %% Calculate Obstacle Avoidance Velocity
        function vObstacle = CalculateObstacleAvoidance(self, robot, q)
            vObstacle = zeros(3, 1);
            
            currentTr = robot.model.fkine(q);
            currentTrMatrix = self.GetTransformMatrix(currentTr);
            currentPos = currentTrMatrix(1:3, 4);
            
            for i = 1:size(self.obstaclePositions, 1)
                obstaclePos = self.obstaclePositions(i, :)';
                obstacleRadius = self.obstacleRadii(i);
                
                diff = currentPos - obstaclePos;
                distance = norm(diff) - obstacleRadius;
                
                if distance < self.obstacleAvoidDist && distance > 0.01
                    fprintf('    [OBSTACLE AVOIDANCE] Distance to obstacle %d: %.3fm\n', i, distance);
                    
                    repulsiveMagnitude = self.repulsiveGain * ...
                        (1/distance - 1/self.obstacleAvoidDist) / distance^2;
                    vObstacle = vObstacle + repulsiveMagnitude * (diff / norm(diff));
                end
            end
        end
        
        %% Limit Joint Velocities
        function qdot = LimitJointVelocities(self, qdot)
            for i = 1:length(qdot)
                if abs(qdot(i)) > self.maxJointVel
                    qdot(i) = sign(qdot(i)) * self.maxJointVel;
                end
            end
        end
        
        %% Enforce Joint Limits
        function q = EnforceJointLimits(self, robot, q)
            for i = 1:length(q)
                if ~isempty(robot.model.links(i).qlim)
                    q(i) = max(robot.model.links(i).qlim(1), ...
                               min(robot.model.links(i).qlim(2), q(i)));
                end
            end
        end
        
        %% Phase 1: Motoman Pick Book
        function MotomanPickBookRMRC(self, bookNum, position)
            fprintf('  Phase 1: MotomanGP4 picking book %d (RMRC)...\n', bookNum);
            
            bookTr = transl(position) ;%* trotx(pi/2);
            endEffectorTr = bookTr / self.motomanGripperOffset;
            
            approachPos = endEffectorTr(1:3, 4)' + [0, 0, self.approachHeight];
            self.MoveRobotRMRC('motoman', approachPos, trotx(pi));
            
            graspPos = endEffectorTr(1:3, 4)';
            self.MoveRobotRMRC('motoman', graspPos, trotx(pi));
            pause(0.2);
            
            liftPos = graspPos + [0, 0, self.approachHeight];
            self.MoveRobotRMRC('motoman', liftPos, trotx(pi), bookNum);
        end
        
        %% Phase 2: Motoman Move to Handoff
        function MotomanMoveToHandoffRMRC(self, bookNum)
            fprintf('  Phase 2: MotomanGP4 moving to handoff (RMRC)...\n');
            
            handoffPos = self.handoffPosition;
            self.MoveRobotRMRC('motoman', handoffPos, trotx(pi/2), bookNum);
            pause(0.3);
        end
        
        %% Phase 3: Linear Move to Handoff
        function LinearMoveToHandoffRMRC(self)
            fprintf('  Phase 3: LinearUR3 moving to receive (RMRC)...\n');
            
            handoffPos = self.handoffPosition;
            self.MoveRobotRMRC('linear', handoffPos, trotx(pi/2));
            pause(0.3);
        end
        
        %% Phase 4: Transfer Book
        function TransferBook(self, bookNum)
            fprintf('  Phase 4: Transferring book...\n');
            pause(0.5);
        end
        
        %% Phase 5: Motoman Retreat
        function MotomanRetreat(self)
            fprintf('  Phase 5: MotomanGP4 retreating...\n');
            
            retreatPos = self.handoffPosition + [0, 0, self.approachHeight];
            self.MoveRobotRMRC('motoman', retreatPos, trotx(pi));
            
            qHomeMotoman = [0, 0, 0, 0, 0, 0];
            qTraj = jtraj(self.robotMotoman.model.getpos(), qHomeMotoman, 30);
            for i = 1:size(qTraj, 1)
                self.robotMotoman.model.animate(qTraj(i, :));
                drawnow();
            end
        end
        
        %% Phase 6: Linear Stack Book
        function LinearStackBookRMRC(self, bookNum, position)
            fprintf('  Phase 6: LinearUR3 stacking book %d (RMRC)...\n', bookNum);
            
            bookTargetTr = transl(position) ;%* trotx(pi/2);
            endEffectorPlaceTr = bookTargetTr / self.linearGripperOffset;
            
            approachPos = endEffectorPlaceTr(1:3, 4)' + [0, 0, self.approachHeight];
            self.MoveRobotRMRC('linear', approachPos, trotx(pi), bookNum);
            
            placePos = endEffectorPlaceTr(1:3, 4)';
            self.MoveRobotRMRC('linear', placePos, trotx(pi), bookNum);
            
            self.bookPoses(:, :, bookNum) = bookTargetTr;
            self.UpdateBookPosition(bookNum, bookTargetTr);
            
            pause(0.2);
        end
        
        %% Phase 7: Linear Retreat
        function LinearRetreat(self)
            fprintf('  Phase 7: LinearUR3 retreating...\n');
            
            qCurrent = self.robotLinear.model.getpos();
            qSafe = qCurrent;
            qSafe(3) = qSafe(3) - pi/6;
            
            qTraj = jtraj(qCurrent, qSafe, 20);
            for i = 1:size(qTraj, 1)
                self.robotLinear.model.animate(qTraj(i, :));
                drawnow();
            end
        end
        
        %% Update Book Position
        function UpdateBookPosition(self, bookNum, transform)
            if isempty(self.bookModels{bookNum}) || ~ishandle(self.bookModels{bookNum})
                return;
            end
            
            [f, v, ~] = plyread('RedBook.ply', 'tri');
            v = v * 0.5;
            
            homV = [v, ones(size(v, 1), 1)]';
            transformedV = transform * homV;
            
            delete(self.bookModels{bookNum});
            self.bookModels{bookNum} = trisurf(f, transformedV(1,:), ...
                transformedV(2,:), transformedV(3,:), ...
                'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.8);
        end
    end
end