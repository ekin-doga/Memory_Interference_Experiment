function [idx, t_press] = wait_for_keys(cfg, keys)
% WAIT_FOR_KEYS - Wait for a key press; ESC stops the session
%
%   wait_for_keys(cfg)        - any key (start, break and resume screens)
%   wait_for_keys(cfg, keys)  - only one of the given keys; others are ignored
%                               (Day 2 choice screen)
% ESC always stops the session (error 'session:quit'; run_encoding and
% run_memory catch it and keep the data so far).
%
% INPUTS:
%   cfg  - config from get_cfg (uses cfg.deviceIndex, cfg.keys.Quit)
%   keys - optional vector of key codes, e.g. cfg.keys.choice
%
% OUTPUTS:
%   idx     - which of the keys was pressed (1 = keys(1), 2 = keys(2), ...);
%             without keys: the key code of the pressed key
%   t_press - GetSecs time of the key press

if nargin < 2
    keys = [];
end

KbReleaseWait(cfg.deviceIndex);      % previous key must be released first
while true
    [down, t_press, code] = KbCheck(cfg.deviceIndex);
    if down
        if code(cfg.keys.Quit)
            error('session:quit', 'Session stopped with ESC.');
        end
        if isempty(keys)
            idx = find(code, 1);
            return;
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
