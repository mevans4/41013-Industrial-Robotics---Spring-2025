classdef BookSpawner
    methods (Static)
        function spawnBooks(customPositions)
            % spawnBooks - Spawn 6 books (2 green, 2 blue, 2 red)
            %
            % Usage:
            %   BookSpawner.spawnBooks()  - Use default positions
            %   BookSpawner.spawnBooks(customPositions) - Use custom positions
            %
            % customPositions: Optional struct with fields:
            %   .green = [2x3] matrix of [x, y, z] positions
            %   .blue  = [2x3] matrix of [x, y, z] positions
            %   .red   = [2x3] matrix of [x, y, z] positions
            %
            % Example:
            %   customPos.green = [-1.5, 0.2, 0.0; -1.5, -0.2, 0.0];
            %   customPos.blue  = [-1.5, 0.2, 0.079; -1.5, -0.2, 0.079];
            %   customPos.red   = [-1.5, 0.2, 0.158; -1.5, -0.2, 0.158];
            %   BookSpawner.spawnBooks(customPos);

            % Default positions (can be changed here)
            if nargin < 1 || isempty(customPositions)
                customPositions = BookSpawner.getDefaultPositions();
            end

            fprintf('Spawning books at configured positions...\n');

            % BOOK PLACEMENT - Green Books
            book_data_green = [
                customPositions.green(1, :), 0, 1, 0;   % Green color
                customPositions.green(2, :), 0, 1, 0;
                ];

            for i = 1:size(book_data_green, 1)
                posG = book_data_green(i, 1:3);
                colourG = book_data_green(i, 4:6);
                book_handle_G = PlaceObject('Environment\greenBook.ply', posG);
                set(book_handle_G, 'FaceColor', colourG);
                set(book_handle_G,'EdgeColor',  'none');
                fprintf('  ✓ Green book %d at [%.3f, %.3f, %.3f]\n', i, posG(1), posG(2), posG(3));
            end

            % BOOK PLACEMENT - Blue Books
            book_data_blue = [
                customPositions.blue(1, :), 0, 0, 1;   % Blue color
                customPositions.blue(2, :), 0, 0, 1;
                ];

            for i = 1:size(book_data_blue, 1)
                posB = book_data_blue(i, 1:3);
                colourB = book_data_blue(i, 4:6);
                book_handle_B = PlaceObject('Environment\blueBook.ply', posB);
                set(book_handle_B, 'FaceColor', colourB);
                set(book_handle_B,'EdgeColor', 'none');
                fprintf('  ✓ Blue book %d at [%.3f, %.3f, %.3f]\n', i, posB(1), posB(2), posB(3));
            end

            % BOOK PLACEMENT - Red Books
            book_data_red = [
                customPositions.red(1, :), 1, 0, 0;   % Red color
                customPositions.red(2, :), 1, 0, 0;
                ];

            for i = 1:size(book_data_red, 1)
                posR = book_data_red(i, 1:3);
                colourR = book_data_red(i, 4:6);
                book_handle_R = PlaceObject('Environment\redBook.ply', posR);
                set(book_handle_R, 'FaceColor', colourR);
                set(book_handle_R,'EdgeColor', 'none');
                fprintf('  ✓ Red book %d at [%.3f, %.3f, %.3f]\n', i, posR(1), posR(2), posR(3));
            end

            fprintf('All books spawned successfully!\n');
        end

        function defaultPos = getDefaultPositions()
            % getDefaultPositions - Returns default book positions
            % This can be edited to change starting positions for all books

            defaultPos.green = [
                -1.75,  0.2, 0.079*0;   % Book 1
                -1.75, -0.2, 0.079*0;   % Book 2
                ];

            defaultPos.blue = [
                -1.75,  0.2, 0.079*1;   % Book 3
                -1.75, -0.2, 0.079*1;   % Book 4
                ];

            defaultPos.red = [
                -1.75,  0.2, 0.079*2;   % Book 5
                -1.75, -0.2, 0.079*2;   % Book 6
                ];
        end
        
        function drawBookStartMarkers()

            book_starter_size = 0.3;
            books1_pos_x = -1.75;
            books1_pos_y = 0.2;

            rectangle('Position', [books1_pos_x-book_starter_size/2, books1_pos_y-book_starter_size/2, book_starter_size, book_starter_size], ...
                'FaceColor', 'white', 'EdgeColor', 'black', 'LineWidth', 2);
            rectangle('Position', [books1_pos_x-book_starter_size/2, -books1_pos_y-book_starter_size/2, book_starter_size, book_starter_size], ...
                'FaceColor', 'white', 'EdgeColor', 'black', 'LineWidth', 2);
        end
    end
end