function draw_trigger(win, cfg, code)
% DRAW_TRIGGER - Draws the trigger pixel (0,0) for the NEXT flip
%
% Do not call this directly in the session code: use flip_trig, which
% calls it on every flip and resets the pixel to 0 one frame after a code.
%
% On the ViewPixx (pixel mode) the colour of the top-left pixel goes to the
% EEG as a trigger on every frame. The gray background decodes to 6, so the
% pixel must be drawn on every flip, also when there is no trigger (code 0 =
% black).
%
%   code = 0                     -> black pixel (no trigger)
%   cfg.triggers.enabled = false -> always a black pixel
%
% Colours are in the 0-1 range (PsychDefaultSetup(2)), so the 0-255 values
% from trigger_rgb are divided by 255.

persistent rgb_table        % row k+1 = colour of code k (computed once)
if isempty(rgb_table)
    rgb_table = zeros(256, 3);
    for k = 0:255
        rgb_table(k + 1, :) = trigger_rgb(k);
    end
end

if ~cfg.triggers.enabled
    code = 0;
end
if code < 0 || code > 255 || code ~= round(code)
    error('draw_trigger:range', 'Trigger code must be an integer 0-255 (got %g).', code);
end

Screen('FillRect', win, rgb_table(code + 1, :) / 255, [0 0 1 1]);
end
