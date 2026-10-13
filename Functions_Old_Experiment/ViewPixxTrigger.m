classdef ViewPixxTrigger
    % ViewPixxTrigger - Complete trigger system for ViewPixx/BioSemi EEG
    %
    % Handles all trigger encoding and sending for the continuous recognition
    % experiment. Uses Biosemi cable pin mapping (pins 2-9 → 1-8).
    %
    % USAGE:
    %   trigger = ViewPixxTrigger(windowPtr);           % Enable triggers
    %   trigger = ViewPixxTrigger(windowPtr, false);    % Disable for debugging
    %   trigger.sendTrigger(6);                         % Send trigger code 6
    %
    % NOTE: Triggers appear in bits 8-15 of BioSemi Status channel

    properties
        windowPtr          % Psychtoolbox window pointer
        enabled            % Boolean: send triggers or skip (for debugging)
        triggerDuration    % How long to hold trigger (seconds, default: 0.010)
    end

    methods
        function obj = ViewPixxTrigger(windowPtr, enabled)
            % Constructor - Initialize trigger system
            %
            % INPUTS:
            %   windowPtr - PTB window pointer
            %   enabled   - (optional) true to send triggers, false to skip
            
            if nargin < 2
                enabled = true;
            end

            obj.windowPtr = windowPtr;
            obj.enabled = enabled;
            obj.triggerDuration = 0.010;  % 10ms trigger pulse
            
            if ~obj.enabled
                fprintf('ViewPixx triggers DISABLED (debugging mode)\n');
            end
        end

        function sendTrigger(obj, triggerCode)
            % Send a trigger pulse
            %
            % USAGE:
            %   trigger.sendTrigger(trigger.BLOCK_START);
            %
            % This method:
            %   1. Draws trigger pixel with correct RGB encoding
            %   2. Flips screen to send trigger
            %   3. Waits 10ms (trigger duration)
            %   4. Clears trigger pixel
            %   5. Flips again to clear
            
            if ~obj.enabled
                return;
            end

            % Draw trigger pixel
            obj.drawTriggerPixelInternal(triggerCode);
            Screen('Flip', obj.windowPtr);
            
            % Hold trigger for 10ms
            WaitSecs(obj.triggerDuration);
            
            % Clear trigger
            obj.drawTriggerPixelInternal(0);
            Screen('Flip', obj.windowPtr);
        end

        function drawTriggerPixel(obj, triggerCode)
            % Draw trigger pixel WITHOUT flipping
            %
            % Use this when you want the trigger to appear WITH a stimulus.
            % Call BEFORE Screen('Flip').
            %
            % EXAMPLE:
            %   Screen('DrawTexture', win, texture, ...);
            %   trigger.drawTriggerPixel(trigger.FIRST_PRESENTATION);
            %   Screen('Flip', win);  % Shows stimulus + trigger together
            
            if ~obj.enabled
                return;
            end

            obj.drawTriggerPixelInternal(triggerCode);
        end

    end

    methods (Access = private)
        function drawTriggerPixelInternal(obj, triggerCode)
            % Internal method: Encode trigger as RGB and draw pixel
            %
            % This handles the complex encoding required for Biosemi cable:
            %   - Converts trigger value (0-255) to binary
            %   - Shifts bits for cable pin mapping (pins 2-9 → 1-8)
            %   - Distributes bits across R, G, B channels
            %   - Draws single pixel at (0,0)
            
            % Validate trigger code
            if triggerCode > 255
                warning('Trigger code %d too large, clamping to 255', triggerCode);
                triggerCode = 255;
            end
            if triggerCode < 0
                error('Trigger code must be >= 0');
            end

            % Convert to 24-bit binary
            binaryCode = dec2bin(triggerCode, 24);
            binaryCode = str2num(binaryCode(:)); %

            % BIOSEMI CABLE SHIFT
            % Biosemi Presentation Cable has pins 2-9 → 1-8
            % This shifts all bits left by 1 position
            binaryCode = [binaryCode(2:end)' 0];

            % PIN MAPPING TO RGB CHANNELS
            % ViewPixx parallel port pins map to RGB values as follows:
            % RED:   pins [1,13,2,14,3,15,4,16]   → bits [1,2,4,8,16,32,64,128]
            % GREEN: pins [5,17,6,18,7,19,8,20]   → bits [1,2,4,8,16,32,64,128]
            % BLUE:  pins [9,21,10,22,11,23,12,24] → bits [1,2,4,8,16,32,64,128]

            redval   = [25 - [1,13,2,14,3,15,4,16];   [1,2,4,8,16,32,64,128]];
            greenval = [25 - [5,17,6,18,7,19,8,20];   [1,2,4,8,16,32,64,128]];
            blueval  = [25 - [9,21,10,22,11,23,12,24]; [1,2,4,8,16,32,64,128]];

            % Calculate RED channel value
            for i = redval(1, :)
                if ~binaryCode(i)
                    redval(2, redval(1, :) == i) = 0;
                end
            end

            % Calculate GREEN channel value
            for i = greenval(1, :)
                if ~binaryCode(i)
                    greenval(2, greenval(1, :) == i) = 0;
                end
            end

            % Calculate BLUE channel value
            for i = blueval(1, :)
                if ~binaryCode(i)
                    blueval(2, blueval(1, :) == i) = 0;
                end
            end

            % Sum to get final RGB values (0-255)
            RGBvals = [sum(redval(2, :)), sum(greenval(2, :)), sum(blueval(2, :))];

            % Draw trigger pixel at top-left corner (0,0)
            Screen('FillRect', obj.windowPtr, RGBvals, [0, 0, 1, 1]);
        end
    end
end
