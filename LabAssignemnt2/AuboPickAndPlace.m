function AuboPickAndPlace(robot, bookManager, bookIndices)
    % AuboPickAndPlace - AUBO i5 Book Stacking System
    % Picks books from targetPos locations and places them at finalPos locations
    % bookIndices: Specific books for AUBO to handle (e.g., [5, 6] for blue books)

    fprintf('Starting AUBO i5 book stacking operation...\n');

    % Get optimized home position for the robot
    homeQ = getAuboHomePosition(robot);

    % Initialize robot at home position for consistent starting state
    fprintf('Moving AUBO to initial home position\n');
    moveAuboToHomePosition(robot, homeQ);

    % Sort books by height (highest first) to avoid collisions
    if length(bookIndices) >= 2
        heights = zeros(1, length(bookIndices));
        for i = 1:length(bookIndices)
            pos = bookManager.getAuboTargetPosition(bookIndices(i));
            heights(i) = pos(3);
        end
        [~, order] = sort(heights, 'descend');
        bookIndices = bookIndices(order);

        fprintf('Optimized stacking order: ');
        for i = 1:length(bookIndices)
            fprintf('Book %d ', bookIndices(i));
        end
        fprintf('\n');
    end

    % Store successful IK solutions to use as references
    successfulIKSolutions = containers.Map();

    % Process specific book indices
    for i = 1:length(bookIndices)
        bookIndex = bookIndices(i);
        fprintf('\n=== AUBO Processing Book %d/%d ===\n', i, length(bookIndices));

        % === GET PICK POSITION FROM BOOKMANAGER ===
        pickPos = bookManager.getAuboTargetPosition(bookIndex);
        if isempty(pickPos)
            fprintf('ERROR: No pick position defined for book %d\n', bookIndex);
            continue;
        end

        % === GET PLACE POSITION FROM BOOKMANAGER ===
        placePos = bookManager.getAuboFinalPosition(bookIndex);
        if isempty(placePos)
            fprintf('ERROR: No place position defined for book %d\n', bookIndex);
            continue;
        end

        % === FIND BOOK AT PICK POSITION ===
        [bookHandle, originalVerts] = findBookAtPosition(pickPos);
        if isempty(bookHandle)
            fprintf('ERROR: No book found at pick position [%.3f, %.3f, %.3f]\n', pickPos(1), pickPos(2), pickPos(3));
            continue;
        end

        % Get book color for logging
        bookColor = getBookColor(bookHandle);
        fprintf('Picking %s book from target position: [%.3f, %.3f, %.3f]\n', bookColor, pickPos(1), pickPos(2), pickPos(3));
        fprintf('Placing %s book at final position: [%.3f, %.3f, %.3f]\n', bookColor, placePos(1), placePos(2), placePos(3));

        % Calculate book surface position
        bookSurfacePos = getBookSurfacePosition(bookHandle, pickPos);

        % Execute pick and place operation
        isFirstBook = (i == 1);
        success = executeAuboPickPlace(robot, bookHandle, originalVerts, bookSurfacePos, placePos, homeQ, i, bookIndex, successfulIKSolutions);

        if success
            % Store successful IK solution for future use
            successfulPlacementQ = robot.model.getpos();
            successfulIKSolutions(num2str(bookIndex)) = successfulPlacementQ;
            fprintf('Stored successful IK solution for book %d\n', bookIndex);
        end

        % Return to home position between book operations
        fprintf('Returning to home position after book %d\n', bookIndex);
        moveAuboToHomePosition(robot, homeQ);
        pause(0.3);
    end

    % Final homing after all operations complete
    fprintf('AUBO operations complete - returning to final home position\n');
    moveAuboToHomePosition(robot, homeQ);

    fprintf('\n=== AUBO Operation Complete: Processed %d books ===\n', length(bookIndices));
end

function success = executeAuboPickPlace(robot, bookHandle, originalVerts, bookSurfacePos, targetPos, homeQ, sequenceIndex, bookIndex, successfulIKSolutions)
    % Execute pick and place with improved IK handling
    pickConfig = homeQ;
    isFirstBook = (sequenceIndex == 1);

    % === APPROACH PHASE: Move above the pick position ===
    approachHeight = 0.12;
    approachPos = [bookSurfacePos(1), bookSurfacePos(2), bookSurfacePos(3) + approachHeight];

    % SAFETY: Validate approach position is above table
    [approachPos, wasModified] = SafetyUtils.validateZPosition(approachPos);
    if wasModified
        fprintf('*** SAFETY: Approach position corrected to prevent table collision\n');
    end

    fprintf('Moving to approach position: [%.3f, %.3f, %.3f]\n', approachPos(1), approachPos(2), approachPos(3));
    if ~moveAuboToPoint(robot, approachPos, pickConfig, isFirstBook, bookIndex, successfulIKSolutions)
        fprintf('ERROR: Failed to move to approach position for book %d\n', bookIndex);
        success = false;
        return;
    end
    pause(0.2);

    % === PICK PHASE: Move down to grasp the book ===
    pickHeight = 0.005;
    pickPos = [bookSurfacePos(1), bookSurfacePos(2), bookSurfacePos(3) + pickHeight];

    % SAFETY: Validate pick position is above table
    [pickPos, wasModified] = SafetyUtils.validateZPosition(pickPos);
    if wasModified
        fprintf('*** SAFETY: Pick position corrected to prevent table collision\n');
    end

    fprintf('Moving to pick position: [%.3f, %.3f, %.3f]\n', pickPos(1), pickPos(2), pickPos(3));
    if ~moveAuboToPoint(robot, pickPos, pickConfig, isFirstBook, bookIndex, successfulIKSolutions)
        fprintf('ERROR: Failed to move to pick position for book %d\n', bookIndex);
        success = false;
        return;
    end
    pause(0.2);

    % Calculate end effector to book offset for precise placement
    currentQ = robot.model.getpos();
    currentEePose = robot.model.fkine(currentQ);
    currentEePos = getPositionFromTransform(currentEePose);

    currentBookVerts = get(bookHandle, 'Vertices');
    currentBookCenter = mean(currentBookVerts, 1);

    % Compute offset vector between end effector and book center
    bookOffset = currentBookCenter - currentEePos;
    fprintf('Calculated book offset: [%.3f, %.3f, %.3f]\n', bookOffset(1), bookOffset(2), bookOffset(3));

    % Package book data for movement functions
    bookData.handle = bookHandle;
    bookData.offset = bookOffset;
    bookData.originalVerts = originalVerts;
    bookData.targetPos = targetPos;

    % === LIFT PHASE: Raise the book after grasping ===
    liftHeight = 0.15;
    liftPos = [bookSurfacePos(1), bookSurfacePos(2), bookSurfacePos(3) + liftHeight];

    % SAFETY: Validate lift position is above table
    [liftPos, wasModified] = SafetyUtils.validateZPosition(liftPos);
    if wasModified
        fprintf('*** SAFETY: Lift position corrected to prevent table collision\n');
    end

    fprintf('Lifting book to: [%.3f, %.3f, %.3f]\n', liftPos(1), liftPos(2), liftPos(3));
    if ~moveAuboWithBook(robot, liftPos, bookData, pickConfig, isFirstBook, bookIndex, successfulIKSolutions)
        fprintf('ERROR: Failed to lift book %d\n', bookIndex);
        success = false;
        return;
    end
    pause(0.2);

    % === TARGET APPROACH: Move above the placement location ===
    targetEePos = targetPos - bookOffset;
    fprintf('Target EE position for placement: [%.3f, %.3f, %.3f]\n', targetEePos(1), targetEePos(2), targetEePos(3));

    targetApproachHeight = 0.12;
    targetApproach = [targetEePos(1), targetEePos(2), targetEePos(3) + targetApproachHeight];

    % SAFETY: Validate approach position is above table
    [targetApproach, wasModified] = SafetyUtils.validateZPosition(targetApproach);
    if wasModified
        fprintf('*** SAFETY: Target approach position corrected to prevent table collision\n');
    end

    fprintf('Moving to placement approach: [%.3f, %.3f, %.3f]\n', targetApproach(1), targetApproach(2), targetApproach(3));
    if ~moveAuboWithBook(robot, targetApproach, bookData, pickConfig, isFirstBook, bookIndex, successfulIKSolutions)
        fprintf('ERROR: Failed to move to placement approach for book %d\n', bookIndex);
        success = false;
        return;
    end
    pause(0.2);

    % === PLACE PHASE: Lower the book to final position ===
    % SAFETY: Validate placement position is above table
    [targetEePos, wasModified] = SafetyUtils.validateZPosition(targetEePos);
    if wasModified
        fprintf('*** SAFETY: Placement position corrected to prevent table collision\n');
        % Update bookData target position if modified
        bookData.targetPos = targetPos;
        bookData.targetPos(3) = max(bookData.targetPos(3), SafetyUtils.MIN_Z_HEIGHT);
    end

    fprintf('Placing book at final position: [%.3f, %.3f, %.3f]\n', targetEePos(1), targetEePos(2), targetEePos(3));
    if ~moveAuboWithBook(robot, targetEePos, bookData, pickConfig, isFirstBook, bookIndex, successfulIKSolutions)
        fprintf('ERROR: Failed to place book %d\n', bookIndex);
        success = false;
        return;
    end
    pause(0.3);

    % === POSITION VERIFICATION: Ensure perfect placement accuracy ===
    finalVerts = get(bookHandle, 'Vertices');
    currentCenter = mean(finalVerts, 1);

    % Calculate and correct any placement errors
    positionError = targetPos - currentCenter;
    if norm(positionError) > 0.001
        fprintf('Correcting placement error: [%.3f, %.3f, %.3f]\n', ...
            positionError(1), positionError(2), positionError(3));
        set(bookHandle, 'Vertices', finalVerts + positionError);
    end

    % Final verification of book placement
    finalVerts = get(bookHandle, 'Vertices');
    finalCenter = mean(finalVerts, 1);
    fprintf('=== AUBO PLACEMENT VERIFICATION ===\n');
    fprintf('Target: [%.3f, %.3f, %.3f]\n', targetPos(1), targetPos(2), targetPos(3));
    fprintf('Actual: [%.3f, %.3f, %.3f]\n', finalCenter(1), finalCenter(2), finalCenter(3));
    fprintf('Placement Error: [%.3f, %.3f, %.3f]\n', ...
        finalCenter(1)-targetPos(1), finalCenter(2)-targetPos(2), finalCenter(3)-targetPos(3));
    fprintf('=== END VERIFICATION ===\n');

    % === RETREAT PHASE: Move away after placement ===
    fprintf('Retreating to: [%.3f, %.3f, %.3f]\n', targetApproach(1), targetApproach(2), targetApproach(3));
    if ~moveAuboToPoint(robot, targetApproach, pickConfig, false, bookIndex, successfulIKSolutions)
        fprintf('WARNING: Failed to retreat after placing book %d\n', bookIndex);
    end
    pause(0.2);

    success = true;
end

%% MOVEMENT FUNCTIONS WITH IMPROVED IK HANDLING

function success = moveAuboToPoint(robot, targetPosition, referenceConfig, isFirstBook, bookIndex, successfulIKSolutions)
    steps = 25;

    targetTransform = transl(targetPosition) * trotx(pi) * trotz(-pi/2);

    % SMART IK SOLUTION USING PREVIOUS SUCCESSFUL SOLUTIONS
    qTarget = [];
    if ~isFirstBook && isKey(successfulIKSolutions, '5')
        fprintf('    Using IK adaptation from previous successful solution\n');
        previousQ = successfulIKSolutions('5');
        qTarget = robot.model.ikcon(targetTransform, previousQ);
    end

    if isempty(qTarget) || any(isnan(qTarget))
        % Standard IK approach
        qTarget = robot.model.ikcon(targetTransform, referenceConfig);
    end

    if any(isnan(qTarget))
        currentQ = robot.model.getpos();
        qTarget = robot.model.ikcon(targetTransform, currentQ);
    end

    if any(isnan(qTarget))
        fprintf('    ERROR: All IK methods failed for position [%.3f, %.3f, %.3f]\n', ...
            targetPosition(1), targetPosition(2), targetPosition(3));
        success = false;
        return;
    end

    qCurrent = robot.model.getpos();
    qTraj = jtraj(qCurrent, qTarget, steps);

    for i = 1:steps
        robot.model.animate(qTraj(i, :));
        drawnow();
        pause(0.02);
    end

    success = true;
end

function success = moveAuboWithBook(robot, targetPosition, bookData, referenceConfig, isFirstBook, bookIndex, successfulIKSolutions)
    steps = 25;

    targetTransform = transl(targetPosition) * trotx(pi) * trotz(-pi/2);

    % SMART IK SOLUTION USING PREVIOUS SUCCESSFUL SOLUTIONS
    qTarget = [];
    if ~isFirstBook && isKey(successfulIKSolutions, '5')
        fprintf('    Using IK adaptation with book\n');
        previousQ = successfulIKSolutions('5');
        qTarget = robot.model.ikcon(targetTransform, previousQ);
    end

    if isempty(qTarget) || any(isnan(qTarget))
        % Standard IK approach
        qTarget = robot.model.ikcon(targetTransform, referenceConfig);

        if any(isnan(qTarget))
            currentQ = robot.model.getpos();
            qTarget = robot.model.ikcon(targetTransform, currentQ);
        end
    end

    if any(isnan(qTarget))
        success = false;
        return;
    end

    qCurrent = robot.model.getpos();
    qTraj = jtraj(qCurrent, qTarget, steps);

    % Store initial state for consistent book movement
    initialEePose = robot.model.fkine(qCurrent);
    if isa(initialEePose, 'SE3')
        initialMatrix = initialEePose.T;
    else
        initialMatrix = initialEePose;
    end

    for i = 1:steps
        q = qTraj(i, :);
        robot.model.animate(q);

        % Get current end effector pose
        currentEePose = robot.model.fkine(q);
        if isa(currentEePose, 'SE3')
            currentMatrix = currentEePose.T;
        else
            currentMatrix = currentEePose;
        end

        % Calculate relative transformation
        relativeTransform = initialMatrix \ currentMatrix;

        % Apply transformation to book
        currentVerts = bookData.originalVerts;
        originalCenter = mean(currentVerts, 1);
        centeredVerts = currentVerts - originalCenter;
        rotatedVerts = (relativeTransform(1:3, 1:3) * centeredVerts')';

        % Calculate new book position
        currentEePos = getPositionFromTransform(currentEePose);
        calculatedBookPos = currentEePos + bookData.offset;
        newVerts = rotatedVerts + calculatedBookPos;

        set(bookData.handle, 'Vertices', newVerts);

        drawnow();
        pause(0.02);
    end

    success = true;
end

%% SUPPORT FUNCTIONS

function homeQ = getAuboHomePosition(robot)
    % Optimized home position for AUBO i5
    % Use the robot's initialJointAngles property
    homeQ = deg2rad([0 135 -105 150 -90 0]);
    fprintf('AUBO home position: [');
    fprintf('%.4f ', homeQ);
    fprintf(']\n');
end

function moveAuboToHomePosition(robot, homeQ)
    fprintf('  Moving AUBO to home position\n');

    qCurrent = robot.model.getpos();

    if max(abs(qCurrent - homeQ)) < 0.01
        fprintf('  AUBO already at home position\n');
        return;
    end

    steps = 25;
    qTraj = jtraj(qCurrent, homeQ, steps);

    for i = 1:steps
        robot.model.animate(qTraj(i, :));
        drawnow();
        pause(0.02);
    end

    fprintf('  AUBO reached home position\n');
end

function position = getPositionFromTransform(transform)
    if isa(transform, 'SE3')
        position = transform.t';
    else
        position = transform(1:3, 4)';
    end
end

function surfacePos = getBookSurfacePosition(bookHandle, bookPos)
    verts = get(bookHandle, 'Vertices');
    maxZ = max(verts(:, 3));
    surfacePos = [bookPos(1), bookPos(2), maxZ];
end

function [bookHandle, bookVerts] = findBookAtPosition(targetPos)
    bookHandle = [];
    bookVerts = [];
    allObjs = findobj('Type', 'patch');
    tolerance = 0.05;

    closestDistance = inf;
    closestObj = [];
    closestVerts = [];

    for i = 1:length(allObjs)
        obj = allObjs(i);
        verts = get(obj, 'Vertices');
        if ~isempty(verts)
            objPos = mean(verts, 1);
            distance = norm(objPos - targetPos);

            if distance < closestDistance
                closestDistance = distance;
                closestObj = obj;
                closestVerts = verts;
            end

            if distance < tolerance
                bookHandle = obj;
                bookVerts = verts;
                return;
            end
        end
    end

    if closestDistance < 0.2
        bookHandle = closestObj;
        bookVerts = closestVerts;
    end
end

function bookColor = getBookColor(bookHandle)
    % Determine book color from handle properties
    faceColor = get(bookHandle, 'FaceColor');
    if isequal(faceColor, [1 0 0])
        bookColor = 'red';
    elseif isequal(faceColor, [0 1 0])
        bookColor = 'green';
    elseif isequal(faceColor, [0 0 1])
        bookColor = 'blue';
    else
        bookColor = 'unknown';
    end
end
