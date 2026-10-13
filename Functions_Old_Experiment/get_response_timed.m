function [Report, RT] = get_response_timed(startTime, deadline, deviceIndex, Keys)
% GET_RESPONSE_TIMED - Poll for a key press within a fixed time window
%
% Participants press SPACE to indicate they recognise the repeating image.
% Returns Report = 1 + RT if space pressed, Report = 0 + RT = NaN if no press.
%
% INPUTS:
%   startTime   - Reference time (stimulus onset vbl)
%   deadline    - Response window duration in seconds (e.g. cfg.stim_dur)
%   deviceIndex - Keyboard device index ([] for any keyboard)
%   Keys        - Struct with fields: respond, Quit (from cfg.keys)

Report = 0;
RT     = NaN;

if isempty(deviceIndex)
    deviceIndex = -1;
end

endTime = startTime + deadline;

while GetSecs < endTime
    [keyIsDown, keyTime, keyCode] = KbCheck(deviceIndex);

    if keyIsDown
        pressedKeys = find(keyCode);

        if ~isempty(pressedKeys)
            key = pressedKeys(1);

            if key == Keys.Quit
                Report = 99;
                sca;
                ShowCursor;
                return;
            elseif key == Keys.respond
                Report = 1;
                RT     = keyTime - startTime;
                return;
            end
            % any other key: ignore and keep polling
        end
    end

    WaitSecs(0.001);
end

end
