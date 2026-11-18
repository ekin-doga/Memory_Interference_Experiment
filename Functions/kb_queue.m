function [pressed, first_press] = kb_queue(action)
% KB_QUEUE - PTB key queues on ALL keyboards (Day 1 key presses)
%
%   kb_queue('start')                     - create and start a queue on every keyboard
%   [pressed, first_press] = kb_queue('check')
%                                         - presses since the last check, all keyboards
%                                           merged (first_press: 1x256 GetSecs times,
%                                           0 = key not pressed), as KbQueueCheck
%   kb_queue('stop')                      - release all queues
%
% Why: KbQueueCreate without a device index listens to ONE keyboard only (the
% system default), while KbCheck without an index listens to all of them. With
% an experimenter keyboard and a participant keyboard, the pilot's break
% screens (KbCheck) worked but no space press during the blocks (key queue)
% was recorded. So here every keyboard gets its own queue and the presses are
% merged. On Windows PTB has one queue that already merges all keyboards.
%
% A queue keeps every press, also while the code waits for a flip (e.g.
% during the image), so no press is missed.

persistent devs
if isempty(devs)
    devs = {};
end

switch action
    case 'start'
        if ~isempty(devs)                 % a queue was left open (e.g. after an error)
            kb_queue('stop');
        end
        if IsWin
            devs = {[]};                  % Windows: one queue for all keyboards
        else
            idx = GetKeyboardIndices();
            if isempty(idx)
                devs = {[]};
            else
                devs = num2cell(idx);
            end
        end
        for k = 1:numel(devs)
            KbQueueCreate(devs{k});
            KbQueueStart(devs{k});
        end

    case 'check'
        first_press = zeros(1, 256);
        for k = 1:numel(devs)
            [~, f] = KbQueueCheck(devs{k});
            new = f > 0 & (first_press == 0 | f < first_press);   % earliest press per key
            first_press(new) = f(new);
        end
        pressed = any(first_press > 0);

    case 'stop'
        for k = 1:numel(devs)
            KbQueueRelease(devs{k});
        end
        devs = {};

    otherwise
        error('kb_queue:action', 'Unknown action "%s" (start, check or stop).', action);
end
end
