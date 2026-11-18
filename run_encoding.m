% RUN_ENCODING -
%
%   1. get_cfg                       - settings
%   2. create_participant / ask_resume - participant folder; resume or overwrite earlier data
%   3. load Stimulus_lists/stimuli_sub-XXX.csv - targets/foils for this participant
%   4. create_sequence               - trial order; one condition per block, conditions
%                                      alternate every cfg.blocks_per_switch blocks
%      add_triggers_encoding         - expected EEG trigger codes per trial
%   5. ask_eeg_started / set_screen  - confirm the EEG recording runs, open the
%                                      window, preload the images
%   6. present_block                 - every block, with a break screen in between
%                                      (halfway: cfg.enc.half_break_text)

%   (odd subj_id: high first; even subj_id: low first) 
%   


clearvars; sca;

%% ===== SET THESE BEFORE EACH RUN =====
subj_id  = 1;      % participant number
windowed = false;    % true = 900x700 test window, false = fullscreen
%% ======================================

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'Functions'));

%% 1. Settings
cfg = get_cfg(subj_id);

%% 2. Participant folder and output files (if data exists: resume, overwrite or quit)
sub_dir = create_participant(subj_id, cfg);
[resume, session_date] = ask_resume(sub_dir, subj_id, 'encoding');
prefix        = fullfile(sub_dir, sprintf('sub-%03d_encoding', subj_id));
sequence_file = sprintf('%s_sequence_%s.csv', prefix, session_date);
results_file  = sprintf('%s_results_%s.mat', prefix, session_date);
results_csv   = sprintf('%s_results_%s.csv', prefix, session_date);
trigger_file  = sprintf('%s_triggers_%s.csv', prefix, session_date);   % every EEG code sent (trigger_log)

%% 3. Stimulus list and 4. sequence
list_file = fullfile(root, 'Stimulus_lists', sprintf('stimuli_sub-%03d.csv', subj_id));
if ~isfile(list_file)
    error('No stimulus list for participant %d (%s). Make it first with create_stimuli_list_balanced(%d).', ...
        subj_id, list_file, subj_id);
end
stim_list = readtable(list_file, 'TextType', 'char');
fprintf('Loaded %s (concept set %d)\n', list_file, stim_list.concept_set(1));
seq       = create_sequence(stim_list, cfg, subj_id);
seq       = add_triggers_encoding(seq, cfg);   % expected EEG trigger codes (trig_image, trig_fix)
seq.onset  = nan(height(seq), 1);    % measured image onset (GetSecs time)
seq.offset = nan(height(seq), 1);    % measured image offset
seq.key_time = nan(height(seq), 1);  % first space press during this trial (GetSecs time)
seq.key_rt   = nan(height(seq), 1);  % key_time - onset
seq = addvars(seq, repmat(subj_id, height(seq), 1), repmat({session_date}, height(seq), 1), ...
    'Before', 1, 'NewVariableNames', {'subj_id', 'session_date'});

if resume
    % continue with the saved sequence: images with a measured offset are done
    old = load(results_file, 'seq');
    if height(old.seq) ~= height(seq) || ~isequal(old.seq.image_id, seq.image_id)
        error(['The saved results of participant %d do not match the sequence made now ' ...
               '(was get_cfg changed, e.g. max_images_per_block, repeat or blocks_per_switch?).'], subj_id);
    end
    seq = add_triggers_encoding(old.seq, cfg);   % (re)adds the trigger columns
    n_done = sum(~isnan(seq.offset));
    if n_done == height(seq)
        error('Participant %d already finished encoding; nothing to resume.', subj_id);
    end
    fprintf('Resuming: %d of %d images already shown, continuing with image %d.\n', ...
        n_done, height(seq), n_done + 1);
else
    writetable(seq, sequence_file);
end

pool_dir = fullfile(cfg.stimuli_dir, 'Selection20_resized');

% backup log of every trigger code sent (appended to on resume)
trigger_log('open', trigger_file, cfg, subj_id, session_date, 'encoding');

try
    %% 5. EEG recording and screen
    ask_eeg_started();                   % y/n/q in the command window (q = quit)
    if windowed && cfg.triggers.enabled
        warning(['Windowed mode: for testing only. Record EEG in fullscreen ' ...
                 '(the macOS compositor can change the trigger pixel and the timing).']);
    end
    [scr, win] = set_screen(2, double(windowed), cfg);
    ppd = scr.pixperdeg;

    img_px = round(cfg.img_size_deg * ppd);
    fprintf('Image %.1f deg = %d px, fixation point %.2f deg = %d px\n', ...
        cfg.img_size_deg, img_px, cfg.fix_size_deg, round(cfg.fix_size_deg * ppd));

    % everything the condition functions need
    E = struct();
    E.win          = win;
    E.scr          = scr;
    E.cfg          = cfg;
    E.stim_list    = stim_list;
    E.results_file = results_file;
    E.results_csv  = results_csv;        % also written after every block (at each break)
    E.img_rect     = CenterRectOnPointd([0 0 img_px img_px], scr.center_X, scr.center_Y);
    E.draw_fix     = @() my_optimal_fixationpoint(win, scr.center_X, scr.center_Y, ...
                           cfg.fix_size_deg, cfg.fix_color, scr.bg, ppd);

    % preload every image once (targets are shown cfg.repeat times, catch
    % flowers several times per block)
    DrawFormattedText(win, cfg.enc.loading_text, 'center', 'center', 0);
    flip_trig(win, cfg, 0);
    [ids, first] = unique(seq.image_id);
    tex_map = containers.Map();
    for k = 1:numel(ids)
        if seq.is_catch(first(k))
            img = imread(fullfile(cfg.catch.dir, seq.path{first(k)}));
        else
            img = imread(fullfile(pool_dir, seq.path{first(k)}));
        end
        tex_map(ids{k}) = Screen('MakeTexture', win, img);
    end
    E.tex = cellfun(@(id) tex_map(id), seq.image_id);   % texture per trial

    % the catch flowers, for the start and break screens
    E.catch_tex = zeros(1, numel(cfg.catch.files));
    for k = 1:numel(cfg.catch.files)
        E.catch_tex(k) = Screen('MakeTexture', win, imread(fullfile(cfg.catch.dir, cfg.catch.files{k})));
    end

    %% Start screen (after an interruption: the resume screen instead)
    % (trigger: experiment_start, or experiment_resume after an interruption)
    if resume
        show_text_with_catch(E, cfg.enc.resume_text, cfg.triggers.experiment_resume);
    else
        show_text_with_catch(E, cfg.enc.instruction_text, cfg.triggers.experiment_start);
    end
    wait_space_queue(cfg);               % SPACE only, via the same key queues as the blocks

    %% 6. Blocks in session order (conditions alternate, see create_sequence),
    % with a break screen between blocks; blocks already shown (resume) are skipped.
    % After the middle block the break says that half is done.
    n_blocks = max(seq.block);
    blocks = unique(seq.block)';
    blocks = blocks(arrayfun(@(b) any(isnan(seq.offset(seq.block == b))), blocks)); % not done yet
    for k = 1:numel(blocks)
        seq = present_block(E, seq, blocks(k));
        if k < numel(blocks)
            if blocks(k) == n_blocks / 2
                show_text_with_catch(E, cfg.enc.half_break_text);
            else
                show_text_with_catch(E, sprintf(cfg.enc.block_break_text, blocks(k), n_blocks));
            end
            wait_for_keys(cfg);
        end
    end

    DrawFormattedText(win, cfg.enc.end_text, 'center', 'center', 0);
    trigger_log('context', NaN, NaN);
    flip_trig(win, cfg, cfg.triggers.experiment_end);
    trigger_log('close');
    WaitSecs(2);

    Screen('Close');
    sca; ShowCursor; Priority(0); display_mode('restore');
    [seq, summary] = score_catch(seq, cfg);
    fprintf('Attention check: %d of %d flowers detected (%.0f%%), %d false alarms, mean RT %.3f s\n', ...
        summary.n_hit, summary.n_catch, 100 * summary.hit_rate, summary.n_false_alarm, summary.mean_rt);
    writetable(seq, results_csv);
    fprintf('Session finished. Results saved to %s (and .csv)\n', results_file);

catch err
    sca; ShowCursor; Priority(0); display_mode('restore');
    trigger_log('close');                % codes sent since the last save
    % seq in the workspace is only updated after a whole block; the file has
    % every image shown so far, so load it back
    if isfile(results_file)
        load(results_file, 'seq');
        % scored CSV with everything shown so far (otherwise the CSV would
        % only have the blocks finished before the stop); a problem here
        % must not hide the original error
        try
            writetable(score_catch(seq, cfg), results_csv);
            fprintf('Results CSV updated: %s\n', results_csv);
        catch csv_err
            warning('Could not write the results CSV: %s', csv_err.message);
        end
    end
    if ~strcmp(err.identifier, 'session:quit')
        rethrow(err);
    end
    disp(err.message);
    fprintf(['All images shown so far are saved in %s\n' ...
             'Run again with the same subj_id and choose r to resume.\n'], results_file);
end
