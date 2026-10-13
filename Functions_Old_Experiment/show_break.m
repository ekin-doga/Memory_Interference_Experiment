function show_break(window, presenttext, deviceIndex, trigger, trig_codes)
% SHOW_BREAK - Display a centred text message and wait for a key press.
% If ESC is pressed, the experiment is terminated safely.
%
% INPUTS:
%   window      - PTB window pointer
%   presenttext - Text string to display
%   deviceIndex - Keyboard device index ([] for any)
%   trigger     - ViewPixxTrigger object
%   trig_codes  - Trigger code values struct (cfg.triggers)

% Draw centered text
Screen('TextSize', window, 24);
DrawFormattedText(window, presenttext, 'center', 'center', [0 0 0], 60);
trigger.drawTriggerPixel(trig_codes.block_text)
fprintf('Block text is up — trigger %d\n', trig_codes.block_text)
Screen('Flip', window);

% --- Wait for key press ---
if nargin < 3 || isempty(deviceIndex)
    deviceIndex = [];
end

KbReleaseWait(deviceIndex);

while true
    [keyIsDown, ~, keyCode] = KbCheck(deviceIndex);

    if keyIsDown
        pressedKeys = find(keyCode);
        key = pressedKeys(1);

        if key == KbName('ESCAPE')
            trigger.sendTrigger(trig_codes.ESC)
            sca;
            ShowCursor;
            error('Experiment terminated by user');
        else
            break;
        end
    end

    WaitSecs(0.001);
end
end
