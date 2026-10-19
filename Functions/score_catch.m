function [seq, summary] = score_catch(seq, cfg, blocks)
% SCORE_CATCH - Hits and false alarms for the attention check (Day 1)
%
% A catch trial (flower) is a hit if a space press falls between
% cfg.catch.rt_window(1) and (2) seconds after its image onset. The press can
% be logged on the catch trial itself or on one of the next two trials of
% the same block (a slow press lands in the next trial's row). Every logged
% press that is not used for a hit is a false alarm (only the first press
% per trial is logged, see present_block).
%
% INPUTS:
%   seq    - encoding sequence with onset, offset, key_time, is_catch
%   cfg    - config from get_cfg
%   blocks - (optional) only summarise these blocks; the columns are always
%            filled for the whole sequence
%
% OUTPUTS:
%   seq     - with columns catch_hit (catch trials: 1/0), catch_rt (s,
%             catch trials that were hit) and false_alarm (shown trials: 1/0)
%   summary - struct: n_catch, n_hit, hit_rate, n_false_alarm, mean_rt
%             (shown trials of the selected blocks only)
%
% For the EEG analysis, drop the catch trials and the trials with a key
% press (key_time not NaN) or right after one.

h = height(seq);
w = cfg.catch.rt_window;
seq.catch_hit   = nan(h, 1);
seq.catch_rt    = nan(h, 1);
seq.false_alarm = nan(h, 1);
used = false(h, 1);                              % press already counted as a hit

for i = find(seq.is_catch & ~isnan(seq.onset))'
    seq.catch_hit(i) = 0;
    for j = i:min(i + 2, h)
        if seq.block(j) ~= seq.block(i)
            break;
        end
        if ~isnan(seq.key_time(j)) && ~used(j)
            rt = seq.key_time(j) - seq.onset(i);
            if rt >= w(1) && rt <= w(2)
                seq.catch_hit(i) = 1;
                seq.catch_rt(i)  = rt;
                used(j) = true;
                break;
            end
        end
    end
end

shown = ~isnan(seq.offset);
seq.false_alarm(shown) = double(~isnan(seq.key_time(shown)) & ~used(shown));

if nargin < 3 || isempty(blocks)
    blocks = unique(seq.block);
end
sel = ismember(seq.block, blocks) & shown;
c   = sel & seq.is_catch;
summary.n_catch       = sum(c);
summary.n_hit         = sum(seq.catch_hit(c) == 1);
summary.hit_rate      = summary.n_hit / max(summary.n_catch, 1);
summary.n_false_alarm = sum(seq.false_alarm(sel) == 1);
summary.mean_rt       = mean(seq.catch_rt(c & seq.catch_hit == 1));   % NaN if no hits
end
