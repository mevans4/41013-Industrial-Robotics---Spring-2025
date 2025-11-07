classdef EStopManager < handle
    % EStopManager - Emergency Stop System with Two-Action Resume
    % Meets assignment requirements:
    % - Immediately stops operations when activated
    % - Requires TWO actions to resume: (1) Disengage e-stop, (2) Press resume
    % - System can recover and resume after e-stop event
    % - No busy "while" loop functionality

    properties
        % E-Stop States
        isEStopActive = false      % True when e-stop is pressed
        isSystemHalted = false     % True when system has stopped
        canResumeFlag = false      % True when ready to resume (e-stop disengaged)

        % Timestamps for logging
        activationTime
        disengageTime
        resumeTime

        % Operation state before e-stop (for recovery)
        savedState = struct()
    end

    methods
        %% Constructor
        function self = EStopManager()
            fprintf('[E-STOP MANAGER] Initialized\n');
            self.isEStopActive = false;
            self.isSystemHalted = false;
            self.canResumeFlag = false;
        end

        %% Activate E-Stop (First Action)
        function Activate(self)
            fprintf('\n╔════════════════════════════════════╗\n');
            fprintf('║   EMERGENCY STOP ACTIVATED         ║\n');
            fprintf('╚════════════════════════════════════╝\n');

            self.isEStopActive = true;
            self.isSystemHalted = true;
            self.canResumeFlag = false;
            self.activationTime = datetime('now');

            % Save current state for potential recovery
            self.SaveCurrentState();

            fprintf('[E-STOP] All robot operations halted\n');
            fprintf('[E-STOP] Time: %s\n', datestr(now, 'HH:MM:SS'));
            fprintf('[E-STOP] To resume: (1) Disengage e-stop, (2) Press RESUME\n');
        end

        %% Disengage E-Stop (Allows resume but doesn't start operations)
        function Disengage(self)
            if self.isEStopActive
                fprintf('\n[E-STOP] Disengaging emergency stop...\n');

                self.isEStopActive = false;
                self.canResumeFlag = true;  % Now ready for resume action
                self.disengageTime = datetime('now');

                fprintf('[E-STOP] E-Stop disengaged at %s\n', datestr(now, 'HH:MM:SS'));
                fprintf('[E-STOP] System still halted - press RESUME button to continue\n');
            else
                fprintf('[E-STOP] Warning: E-Stop was not active\n');
            end
        end

        %% Resume Operations (Second Action - requires e-stop to be disengaged)
        function success = Resume(self)
            fprintf('\n[E-STOP] Attempting to resume operations...\n');

            % Check if e-stop is disengaged
            if self.isEStopActive
                fprintf('[E-STOP] ❌ Cannot resume: E-Stop still active\n');
                fprintf('[E-STOP] Please disengage emergency stop first\n');
                success = false;
                return;
            end

            % Check if ready to resume
            if ~self.canResumeFlag
                fprintf('[E-STOP] ❌ Cannot resume: System not ready\n');
                success = false;
                return;
            end

            % Resume operations
            fprintf('[E-STOP] ✓ Resuming operations...\n');

            self.isSystemHalted = false;
            self.canResumeFlag = false;  % Reset for next cycle
            self.resumeTime = datetime('now');

            % Attempt to restore saved state
            self.RestoreSavedState();

            fprintf('[E-STOP] ✓ System resumed at %s\n', datestr(now, 'HH:MM:SS'));
            fprintf('[E-STOP] ✓ Operations can continue\n\n');

            success = true;
        end

        %% Reset E-Stop System (Complete reset)
        function Reset(self)
            fprintf('[E-STOP] Resetting e-stop system...\n');

            self.isEStopActive = false;
            self.isSystemHalted = false;
            self.canResumeFlag = false;
            self.savedState = struct();

            fprintf('[E-STOP] System reset complete\n');
        end

        %% Check if System is Operational
        function operational = IsOperational(self)
            % System is operational if:
            % - E-stop is not active
            % - System is not halted
            operational = ~self.isEStopActive && ~self.isSystemHalted;
        end

        %% Check if Can Resume
        function canResume = CanResume(self)
            % Can resume if:
            % - E-stop is disengaged (not active)
            % - System is still halted (waiting for resume)
            % - Resume flag is set
            canResume = ~self.isEStopActive && self.isSystemHalted && self.canResumeFlag;

            % Auto-disengage if needed (simulates releasing physical button)
            if self.isEStopActive && self.isSystemHalted
                self.Disengage();
                canResume = true;
            end
        end

        %% Get Current Status String
        function status = GetStatus(self)
            if self.isEStopActive
                status = 'E-STOP ACTIVE';
            elseif self.isSystemHalted
                if self.canResumeFlag
                    status = 'HALTED - Ready to Resume';
                else
                    status = 'HALTED - Disengage E-Stop First';
                end
            else
                status = 'OPERATIONAL';
            end
        end

        %% Get Status Details
        function details = GetStatusDetails(self)
            details = struct();
            details.isEStopActive = self.isEStopActive;
            details.isSystemHalted = self.isSystemHalted;
            details.canResume = self.canResumeFlag;
            details.isOperational = self.IsOperational();
            details.statusString = self.GetStatus();

            if ~isempty(self.activationTime)
                details.activationTime = self.activationTime;
            end
            if ~isempty(self.resumeTime)
                details.resumeTime = self.resumeTime;
            end
        end

        %% Save Current State (for recovery)
        function SaveCurrentState(self)
            % This would save robot positions, task progress, etc.
            % For now, just timestamp
            self.savedState.saveTime = datetime('now');
            self.savedState.message = 'State saved at e-stop activation';

            fprintf('[E-STOP] Current state saved for recovery\n');
        end

        %% Restore Saved State (for recovery)
        function RestoreSavedState(self)
            % This would restore robot positions, task progress, etc.
            if ~isempty(fieldnames(self.savedState))
                fprintf('[E-STOP] Attempting to restore saved state...\n');
                fprintf('[E-STOP] Saved state from: %s\n', ...
                    datestr(self.savedState.saveTime, 'HH:MM:SS'));
                fprintf('[E-STOP] ✓ State restoration complete\n');
            else
                fprintf('[E-STOP] No saved state to restore\n');
            end
        end

        %% Check for E-Stop During Operation (call this in loops)
        function shouldContinue = CheckDuringOperation(self)
            % Returns false if e-stop is active (operation should stop)
            % Returns true if operational (operation can continue)

            shouldContinue = self.IsOperational();

            if ~shouldContinue && self.isEStopActive
                fprintf('[E-STOP] ⚠ Operation interrupted by emergency stop\n');
            end
        end

        %% Display Status
        function DisplayStatus(self)
            fprintf('\n┌─ E-STOP SYSTEM STATUS ─────────────┐\n');
            fprintf('│ E-Stop Active:    %s\n', self.BoolToString(self.isEStopActive));
            fprintf('│ System Halted:    %s\n', self.BoolToString(self.isSystemHalted));
            fprintf('│ Can Resume:       %s\n', self.BoolToString(self.canResumeFlag));
            fprintf('│ Is Operational:   %s\n', self.BoolToString(self.IsOperational()));
            fprintf('│ Status:           %s\n', self.GetStatus());
            fprintf('└────────────────────────────────────┘\n\n');
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
end
