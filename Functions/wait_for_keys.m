function [idx, t_press] = wait_for_keys(cfg, keys)
% WAIT_FOR_KEYS - Wait until one of the given keys is pressed
%
% Other keys are ignored. ESC stops the session (error 'memory:quit').
%
% INPUTS:
%   cfg  - config from get_cfg (uses cfg.deviceIndex, cfg.keys.Quit)
%   keys - vector of key codes, e.g. cfg.keys.choice
%
% OUTPUTS:
%   idx     - which of the keys was pressed (1 = keys(1), 2 = keys(2), ...)
%   t_press - GetSecs time of the key press

KbReleaseWait(cfg.deviceIndex);      % previous key must be released first
while true
    [down, t_press, code] = KbCheck(cfg.deviceIndex);
    if down
        if code(cfg.keys.Quit)
            error('memory:quit', 'Session stopped with ESC.');
        end
        hit = find(code(keys), 1);
        if ~isempty(hit)
            idx = hit;
            return;
        end
    end
    WaitSecs(0.001);
end
end
