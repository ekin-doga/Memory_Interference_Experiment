function draw_trigger(win, cfg, code)
% DRAW_TRIGGER - Trigger pixel for the NEXT Screen('Flip')
%
% Call right before every Flip. The ViewPixx sends the code encoded in the
% top-left pixel at the moment that frame appears, so the trigger is
% time-locked to what the flip shows (e.g. image onset).
%
%   code = 0                    -> black pixel (no trigger)
%   cfg.triggers.enabled false  -> always a black pixel (no triggers yet)
%
% Drawing the black pixel on every frame matters: otherwise the pixel shows
% the gray background, which the ViewPixx would read as a trigger code.

if ~cfg.triggers.enabled || code == 0
    Screen('FillRect', win, [0 0 0], [0 0 1 1]);
    return;
end

% TODO when triggers are set up: port the RGB encoding from
% Functions_Old_Experiment/ViewPixxTrigger.m (drawTriggerPixelInternal).
% Note: colours here are in the 0-1 range (PsychDefaultSetup(2)), so the
% RGB values from that function (0-255) must be divided by 255.
error('draw_trigger:notImplemented', ...
    'cfg.triggers.enabled is true, but the ViewPixx pixel encoding is not added yet (see draw_trigger.m).');
end
