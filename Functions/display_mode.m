function display_mode(action, screen_ID, hz)
% DISPLAY_MODE - Switches the refresh rate for the session and restores it afterwards
%
%   display_mode('set', screen_ID, hz)  - before the window opens (set_screen):
%                                         switch screen_ID to hz, if it runs at
%                                         another rate; the old mode is remembered
%   display_mode('restore')             - after sca (end of session or error):
%                                         switch back to the remembered mode, so
%                                         the next user of the lab PC finds the
%                                         display as it was
%
% Uses Screen('Resolution'): same resolution, only the refresh rate changes.
% Works on Linux (XRandR) and usually on macOS/Windows. If the display does
% not offer that rate, PTB raises an error and the session does not start.
% set_screen measures the real rate after opening the window and stops if it
% is still not cfg.refresh_hz.

persistent old_mode old_screen

switch action
    case 'set'
        cur = Screen('Resolution', screen_ID);
        if abs(cur.hz - hz) <= 1
            return;                              % already at that rate
        end
        fprintf('Switching screen %d from %g Hz to %g Hz (%d x %d)...\n', ...
            screen_ID, cur.hz, hz, cur.width, cur.height);
        old_mode   = Screen('Resolution', screen_ID, cur.width, cur.height, hz);
        old_screen = screen_ID;
        WaitSecs(2);                             % let the display settle in the new mode

    case 'restore'
        if isempty(old_mode)
            return;
        end
        try
            Screen('Resolution', old_screen, old_mode);
            fprintf('Screen %d set back to %g Hz.\n', old_screen, old_mode.hz);
        catch err
            warning('Could not set the screen back to %g Hz: %s', old_mode.hz, err.message);
        end
        old_mode = [];

    otherwise
        error('display_mode:action', 'Unknown action "%s" (set or restore).', action);
end
end
