classdef BookManager < handle
    properties
        originalBookHandles = {};
        bookHeights = 0.079;
        currentBookIndex = 1;
        booksPlaced = 0;

        hardcodedBooks = {
            [-1.75,  0.2, 0.079*2, 3];
            [-1.75, -0.2, 0.079*2, 3];
            [-1.75,  0.2, 0.079*1, 2];
            [-1.75, -0.2, 0.079*1, 2];
            [-1.75,  0.2, 0.079*0, 1];
            [-1.75, -0.2, 0.079*0, 1]
            };
    end

    methods
        function self = BookManager()
            self.originalBookHandles = {};
            self.currentBookIndex = 1;
            self.booksPlaced = 0;
        end

        function storeBookHandles(self)
            fprintf('Setting up book positions...\n');

            allObjs = findobj('Type', 'patch');
            actualBooks = {};

            for i = 1:length(allObjs)
                obj = allObjs(i);
                verts = get(obj, 'Vertices');

                if isempty(verts)
                    continue;
                end

                objPos = mean(verts, 1);
                isInBookArea = abs(objPos(1) - (-1.75)) < 0.3;

                if isInBookArea
                    minVerts = min(verts);
                    maxVerts = max(verts);
                    topSurfacePos = [objPos(1), objPos(2), maxVerts(3)];

                    actualBooks{end+1} = struct(...
                        'handle', obj, ...
                        'position', objPos, ...
                        'originalVerts', verts, ...
                        'topSurfacePosition', topSurfacePos);
                end
            end

            fprintf('Found %d books\n', length(actualBooks));
            self.matchBooksToPositions(actualBooks);

            fprintf('Book order:\n');
            for i = 1:length(self.originalBookHandles)
                bookInfo = self.originalBookHandles{i};
                fprintf('  %d. %s book at [%.3f, %.3f, %.3f]\n', ...
                    i, self.colorIndexToString(bookInfo.colorIndex), ...
                    bookInfo.position(1), bookInfo.position(2), bookInfo.position(3));
            end
        end

        function matchBooksToPositions(self, actualBooks)
            if length(actualBooks) ~= 6
                fprintf('Warning: Expected 6 books, found %d\n', length(actualBooks));

                for i = 1:min(length(actualBooks), 6)
                    hardcoded = self.hardcodedBooks{i};
                    actualBook = actualBooks{i};

                    bookInfo = struct(...
                        'handle', actualBook.handle, ...
                        'originalVerts', actualBook.originalVerts, ...
                        'position', actualBook.position, ...
                        'topSurfacePosition', actualBook.topSurfacePosition, ...
                        'colorIndex', hardcoded(4), ...
                        'height', hardcoded(3));

                    self.originalBookHandles{end+1} = bookInfo;
                end
            else
                for i = 1:6
                    hardcoded = self.hardcodedBooks{i};
                    actualBook = actualBooks{i};

                    bookInfo = struct(...
                        'handle', actualBook.handle, ...
                        'originalVerts', actualBook.originalVerts, ...
                        'position', [hardcoded(1), hardcoded(2), hardcoded(3)], ...
                        'topSurfacePosition', [hardcoded(1), hardcoded(2), hardcoded(3) + 0.01], ...
                        'colorIndex', hardcoded(4), ...
                        'height', hardcoded(3));

                    self.originalBookHandles{end+1} = bookInfo;
                end
            end
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