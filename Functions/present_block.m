function seq = present_block(E, seq, b)
% PRESENT_BLOCK - Shows all trials of block b
%
% Each trial: image (cfg.stim_dur) without fixation point, then fixation
% point only for the trial's ISI. Starts
% with 1 s of fixation. Stores the measured onset/offset of each image in
% seq, saves the results .mat after every image (during the ISI), and prints the
% measured image durations. Images that already have an offset (when
% resuming) are skipped.
%
% Key presses are collected with a PTB key queue, so a press is never missed,
% also not during the image. The first space press per trial goes into
% seq.key_time (GetSecs time) and seq.key_rt (relative to that trial's
% image onset); a press during the image or ISI of trial t counts for trial t.
% Hits/false alarms for the catch trials are scored afterwards with
% score_catch (a summary is printed after every block). After every block the
% results CSV (E.results_csv) is rewritten with all trials so far, scored, so
% an up-to-date CSV exists at every break (unshown trials have NaN onsets).
%
% INPUTS:
%   E - struct from run_encoding (win, scr, cfg, tex, img_rect, ...)
%   seq - trial sequence (from create_sequence)
%   b   - block number
%
% ESC during the block stops the session (error 'encoding:quit').
%
% EEG triggers (codes in get_cfg, cfg.triggers; every flip goes through
% flip_trig, so each code is followed by 0 one frame later):
%   block_start.<cond>  1 s fixation before the first image
%   seq.trig_image      image onset (target 128 + category number, flower 160)
%   seq.trig_fix        image offset = fixation (ISI) onset
%   (both columns are made by add_triggers_encoding)
%   block_end           after the last ISI of the block
% Space presses send no trigger (their time is in seq.key_time).

cfg    = E.cfg;
win    = E.win;
ifi    = E.scr.ifi;
trials = find(seq.block == b & isnan(seq.offset))';   % images not shown yet

% for the progress print: part (1st/2nd condition), block within the
% condition, and the image number counting targets only (1-150)
in_block   = find(seq.block == b);
target_nr  = zeros(height(seq), 1);
target_nr(in_block) = cumsum(~seq.is_catch(in_block));
n_targets  = sum(~seq.is_catch(in_block));
part       = 1 + ~strcmp(seq.condition{in_block(1)}, seq.condition{1});   % 1 or 2
n_blocks_c = max(seq.repeat);
cond       = seq.condition{in_block(1)};                  % 'high' or 'low'
tr         = cfg.triggers;

KbQueueCreate(cfg.deviceIndex);
KbQueueStart(cfg.deviceIndex);
queue_cleanup = onCleanup(@() KbQueueRelease(cfg.deviceIndex)); %#ok<NASGU>

E.draw_fix();
vbl = flip_trig(win, cfg, tr.block_start.(cond));
next_onset = vbl + 1.0;                       % 1 s fixation before the block

for t = trials
    % image (no fixation point on top)
    Screen('DrawTexture', win, E.tex(t), [], E.img_rect);
    seq.onset(t) = flip_trig(win, cfg, seq.trig_image(t), next_onset - ifi/2);

    % fixation point only, after stim_dur
    E.draw_fix();
    seq.offset(t) = flip_trig(win, cfg, seq.trig_fix(t), seq.onset(t) + cfg.stim_dur - ifi/2);
    next_onset = seq.offset(t) + seq.ISI(t);

    % save during the ISI, so a crash or ESC loses at most this image
    save_results(E, seq);

    % progress print (command window)
    if seq.is_catch(t)
        fprintf('Condition %d (%s) | block %d/%d | catch (flower)\n', ...
            part, seq.condition{t}, seq.repeat(t), n_blocks_c);
    else
        fprintf('Condition %d (%s) | block %d/%d | trial %d/%d\n', ...
            part, seq.condition{t}, seq.repeat(t), n_blocks_c, target_nr(t), n_targets);
    end

    % collect key presses while waiting (ESC stops, space = catch response)
    while GetSecs < next_onset - 0.05
        [pressed, first_press] = KbQueueCheck(cfg.deviceIndex);
        if pressed
            if first_press(cfg.keys.Quit)
                error('encoding:quit', 'Session stopped with ESC (block %d, trial %d).', b, t);
            end
            if first_press(cfg.keys.respond) && isnan(seq.key_time(t))
                seq.key_time(t) = first_press(cfg.keys.respond);
                seq.key_rt(t)   = seq.key_time(t) - seq.onset(t);
            end
        end
        WaitSecs(0.001);
    end
end
save_results(E, seq);   % includes a press during the last ISI

% end of block (same fixation screen, so nothing changes for the participant)
E.draw_fix();
flip_trig(win, cfg, tr.block_end);

all_trials = find(seq.block == b);
dur = seq.offset(all_trials) - seq.onset(all_trials);
fprintf('Block %d (%s) done. Image duration: mean %.3f s, min %.3f, max %.3f\n', ...
    b, seq.condition{all_trials(1)}, mean(dur), min(dur), max(dur));
[seq_scored, summary] = score_catch(seq, cfg, b);
writetable(seq_scored, E.results_csv);   % CSV with everything so far, at every break
fprintf('  Attention check: %d of %d flowers detected, %d false alarms, mean RT %.3f s\n', ...
    summary.n_hit, summary.n_catch, summary.n_false_alarm, summary.mean_rt);
end


function save_results(E, seq)
cfg = E.cfg;  scr = E.scr;  stim_list = E.stim_list; %#ok<NASGU>
subj_id = seq.subj_id(1);  session_date = seq.session_date{1}; %#ok<NASGU>
save(E.results_file, 'seq', 'cfg', 'scr', 'stim_list', 'subj_id', 'session_date');
end
