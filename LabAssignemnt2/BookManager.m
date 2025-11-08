classdef BookManager < handle
    properties
        originalBookHandles = {};
        bookHeights = 0.079;
        currentBookIndex = 1;
        booksPlaced = 0;

        % Reference positions for validation (optional)
        expectedBookArea = [-1.75, 0, 0];  % Approximate center of book starting area
        searchRadius = 0.5;  % Search within this radius

        % Visual debugging
        debugMarkers = {};
    end

    methods
        function self = BookManager()
            self.originalBookHandles = {};
            self.currentBookIndex = 1;
            self.booksPlaced = 0;
        end

        function storeBookHandles(self)
            fprintf('\n═══════════════════════════════════════════════════\n');
            fprintf('   DYNAMIC BOOK DETECTION SYSTEM\n');
            fprintf('═══════════════════════════════════════════════════\n\n');

            % Clear previous markers
            self.clearDebugMarkers();

            % Find all patch objects in scene
            allObjs = findobj('Type', 'patch');
            actualBooks = {};

            fprintf('Scanning scene for books...\n');
            for i = 1:length(allObjs)
                obj = allObjs(i);
                verts = get(obj, 'Vertices');
                faceColor = get(obj, 'FaceColor');

                if isempty(verts)
                    continue;
                end

                % Calculate object properties
                objPos = mean(verts, 1);
                minVerts = min(verts);
                maxVerts = max(verts);
                objectSize = maxVerts - minVerts;

                % Book detection criteria:
                % 1. In expected book area
                % 2. Reasonable book-like dimensions
                % 3. Has a valid color
                isInBookArea = norm(objPos - self.expectedBookArea) < self.searchRadius;
                isBookSize = objectSize(1) < 0.2 && objectSize(2) < 0.2 && objectSize(3) < 0.15 && objectSize(3) > 0.02;
                hasColor = isnumeric(faceColor) && length(faceColor) == 3;

                if isInBookArea && isBookSize && hasColor
                    topSurfacePos = [objPos(1), objPos(2), maxVerts(3)];

                    % Detect color from face color
                    colorIndex = self.detectColorFromRGB(faceColor);

                    if colorIndex > 0  % Valid book color detected
                        actualBooks{end+1} = struct(...
                            'handle', obj, ...
                            'position', objPos, ...
                            'originalVerts', verts, ...
                            'topSurfacePosition', topSurfacePos, ...
                            'colorIndex', colorIndex, ...
                            'faceColor', faceColor, ...
                            'size', objectSize);

                        fprintf('  ✓ Found %s book at [%.3f, %.3f, %.3f]\n', ...
                            self.colorIndexToString(colorIndex), ...
                            objPos(1), objPos(2), objPos(3));
                    end
                end
            end

            fprintf('\nDetected %d books total\n', length(actualBooks));

            if length(actualBooks) == 0
                error('No books detected! Make sure BookSpawner has been run first.');
            end

            % Sort and store books
            self.sortAndStoreBooks(actualBooks);

            % Display final book order
            fprintf('\n═══════════════════════════════════════════════════\n');
            fprintf('FINAL BOOK PICKING ORDER:\n');
            fprintf('═══════════════════════════════════════════════════\n');
            for i = 1:length(self.originalBookHandles)
                bookInfo = self.originalBookHandles{i};
                fprintf('  %d. %s book at [%.3f, %.3f, %.3f]\n', ...
                    i, upper(self.colorIndexToString(bookInfo.colorIndex)), ...
                    bookInfo.position(1), bookInfo.position(2), bookInfo.position(3));
            end
            fprintf('═══════════════════════════════════════════════════\n\n');

            % Add visual markers for debugging
            self.addDebugMarkers();
        end

        function colorIndex = detectColorFromRGB(~, rgb)
            % detectColorFromRGB - Automatically detect book color from RGB values
            % Returns: 1=green, 2=blue, 3=red, 0=unknown

            % Normalize RGB values
            r = rgb(1);
            g = rgb(2);
            b = rgb(3);

            % Color detection with tolerance
            if g > 0.7 && r < 0.3 && b < 0.3
                colorIndex = 1;  % Green
            elseif b > 0.7 && r < 0.3 && g < 0.3
                colorIndex = 2;  % Blue
            elseif r > 0.7 && g < 0.3 && b < 0.3
                colorIndex = 3;  % Red
            else
                colorIndex = 0;  % Unknown/other color
            end
        end

        function sortAndStoreBooks(self, actualBooks)
            % Sort books by Z-position (height), then by Y-position
            % This ensures consistent ordering regardless of detection order

            if isempty(actualBooks)
                return;
            end

            % Extract positions for sorting
            numBooks = length(actualBooks);
            positions = zeros(numBooks, 3);
            for i = 1:numBooks
                positions(i, :) = actualBooks{i}.position;
            end

            % Sort by: 1) Z (height), 2) Y (front/back)
            % This gives us bottom-to-top, front-to-back ordering
            [~, sortIdx] = sortrows(positions, [3, 2]);

            % Store sorted books
            self.originalBookHandles = {};
            for i = 1:numBooks
                book = actualBooks{sortIdx(i)};

                bookInfo = struct(...
                    'handle', book.handle, ...
                    'originalVerts', book.originalVerts, ...
                    'position', book.position, ...
                    'topSurfacePosition', book.topSurfacePosition, ...
                    'colorIndex', book.colorIndex, ...
                    'height', book.position(3));

                self.originalBookHandles{end+1} = bookInfo;
            end
        end

        function addDebugMarkers(self)
            % Add visual markers at detected book positions
            hold on;
            for i = 1:length(self.originalBookHandles)
                book = self.originalBookHandles{i};
                pos = book.position;

                % Create colored sphere at book position
                [X, Y, Z] = sphere(10);
                radius = 0.03;
                X = X * radius + pos(1);
                Y = Y * radius + pos(2);
                Z = Z * radius + pos(3) + 0.1;  % Slightly above book

                % Color based on book color
                switch book.colorIndex
                    case 1, markerColor = [0, 1, 0];  % Green
                    case 2, markerColor = [0, 0, 1];  % Blue
                    case 3, markerColor = [1, 0, 0];  % Red
                    otherwise, markerColor = [0.5, 0.5, 0.5];  % Gray
                end

                marker = surf(X, Y, Z, 'FaceColor', markerColor, ...
                    'EdgeColor', 'none', 'FaceAlpha', 0.5);
                self.debugMarkers{end+1} = marker;

                % Add text label
                textLabel = text(pos(1), pos(2), pos(3) + 0.15, ...
                    sprintf('%d', i), 'FontSize', 14, 'FontWeight', 'bold', ...
                    'Color', 'white', 'HorizontalAlignment', 'center', ...
                    'BackgroundColor', markerColor, 'EdgeColor', 'black');
                self.debugMarkers{end+1} = textLabel;
            end
        end

        function clearDebugMarkers(self)
            % Remove all debug markers from scene
            for i = 1:length(self.debugMarkers)
                if ishandle(self.debugMarkers{i}) && isvalid(self.debugMarkers{i})
                    delete(self.debugMarkers{i});
                end
            end
            self.debugMarkers = {};
        end

        function colorStr = colorIndexToString(~, colorIndex)
            switch colorIndex
                case 1, colorStr = 'green';
                case 2, colorStr = 'blue';
                case 3, colorStr = 'red';
                otherwise, colorStr = 'unknown';
            end
        end

        function [bookPos, bookColor, bookIndex, bookHandle, originalVerts, topSurfacePos] = getNextBook(self)
            if isempty(self.originalBookHandles) || self.currentBookIndex > length(self.originalBookHandles)
                bookPos = []; bookColor = ''; bookIndex = 0;
                bookHandle = []; originalVerts = []; topSurfacePos = [];
                return;
            end

            bookInfo = self.originalBookHandles{self.currentBookIndex};
            bookPos = bookInfo.position;
            bookHandle = bookInfo.handle;
            originalVerts = bookInfo.originalVerts;
            topSurfacePos = bookInfo.topSurfacePosition;
            bookIndex = self.currentBookIndex;
            bookColor = self.colorIndexToString(bookInfo.colorIndex);

            fprintf('Next book: %s at [%.3f, %.3f, %.3f] (%d/%d)\n', ...
                bookColor, bookPos(1), bookPos(2), bookPos(3), ...
                self.currentBookIndex, length(self.originalBookHandles));
        end

        function removeBook(self, bookColor, bookIndex)
            if bookIndex <= length(self.originalBookHandles)
                fprintf('Removed %s book %d\n', bookColor, bookIndex);
                self.currentBookIndex = self.currentBookIndex + 1;
            end
        end

        function targetPos = getTargetPosition(self, ~)
            % Book centers for proper stacking (book height = 0.079m)
            % Bottom layer center: 0.079/2 = 0.0395
            % Second layer center: 0.079 + 0.079/2 = 0.1185
            switch self.booksPlaced
                case 0
                    targetPos = [-0.5, -0.25*2.1, 0.0395];
                case 1
                    targetPos = [-0.5, -0.25*2.1, 0.1185];
                case 2
                    targetPos = [-0.5, 0.25*2.1, 0.0395];
                case 3
                    targetPos = [-0.5, 0.25*2.1, 0.1185];
                case 4
                    targetPos = [0, 0, 0.0395];
                case 5
                    targetPos = [0, 0, 0.1185];
            end

            self.booksPlaced = self.booksPlaced + 1;
            fprintf('Stack position: [%.3f, %.3f, %.3f]\n', targetPos(1), targetPos(2), targetPos(3));
        end

        function reset(self)
            self.currentBookIndex = 1;
            self.booksPlaced = 0;
            self.originalBookHandles = {};
            self.clearDebugMarkers();
            fprintf('Book manager reset\n');
        end

        function verifyBookPositions(self)
            fprintf('Checking book positions...\n');
            for i = 1:length(self.originalBookHandles)
                book = self.originalBookHandles{i};
                if ~isempty(book.handle) && isvalid(book.handle)
                    currentVerts = get(book.handle, 'Vertices');
                    currentPos = mean(currentVerts, 1);
                    fprintf('Book %d (%s):\n', i, self.colorIndexToString(book.colorIndex));
                    fprintf('  Expected: [%.3f, %.3f, %.3f]\n', book.position(1), book.position(2), book.position(3));
                    fprintf('  Actual:   [%.3f, %.3f, %.3f]\n', currentPos(1), currentPos(2), currentPos(3));
                else
                    fprintf('Book %d: missing\n', i);
                end
            end
        end
% Motoman books (picks books 3, 4 from center-left stack)
        function targetPos = getMotomanTargetPosition(self, bookIndex)
            % Pick from where UR3 placed them (book centers)
            switch bookIndex
                case 3
                    targetPos = [-0.5, 0.525, 0.0395];  % Bottom layer
                case 4
                    targetPos = [-0.5, 0.525, 0.1185];  % Second layer
                otherwise
                    targetPos = [];
            end
        end

        function finalPos = getMotomanFinalPosition(self, bookIndex)
            % Place at final positions (book centers)
            if bookIndex == 4
                finalPos = [0, 1.05, 0.0395];   % Bottom layer
            else
                finalPos = [0, 1.05, 0.1185];   % Second layer
            end
        end

        % KUKA books (picks books 1, 2 from left stack)
        function targetPos = getKukaTargetPosition(self, bookIndex)
            % Pick from where UR3 placed them (book centers)
            switch bookIndex
                case 1
                    targetPos = [-0.5, -0.25*2.1, 0.0395];  % Bottom layer
                case 2
                    targetPos = [-0.5, -0.25*2.1, 0.1185];  % Second layer
                otherwise
                    targetPos = [];
            end
        end

        function finalPos = getKukaFinalPosition(self, bookIndex)
            % Place at final positions (book centers)
            if bookIndex == 1
                finalPos = [0, -1.05, 0.0395];   % Bottom layer
            else
                finalPos = [0, -1.05, 0.1185];   % Second layer
            end
        end

        % AUBO books (picks books 5, 6 from center stack)
        function targetPos = getAuboTargetPosition(self, bookIndex)
            % Pick from where UR3 placed them (book centers)
            switch bookIndex
                case 5
                    targetPos = [0, 0, 0.0395];   % Bottom layer
                case 6
                    targetPos = [0, 0, 0.1185];   % Second layer
                otherwise
                    targetPos = [];
            end
        end

        function finalPos = getAuboFinalPosition(self, bookIndex)
            % Place at final positions (book centers)
            if bookIndex == 5
                finalPos = [1.5, 0, 0.0395];   % Bottom layer
            else
                finalPos = [1.5, 0, 0.1185];   % Second layer
            end
        end
    end
end