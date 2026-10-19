% RUN_MEMORY - Day 2 memory test (2AFC with confidence rating)
%
%   1. get_cfg                  - settings (cfg.mem: timing, keys, texts)
%   2. participant folder       - Participants/sub-XXX from Day 1
%   3. load Stimulus_lists/stimuli_sub-XXX.csv
%   4. create_memory_sequence   - one trial per target-foil pair; conditions in
%                                 separate blocks, same order as at encoding
%   5. set_screen               - open the window, preload the images
%   6. run_memory_block         - per condition, with a break in between
%
% Output in Participants/sub-XXX/:
%   memory_sequence.csv  - planned trials (written before the session)
%   memory_results.mat   - mseq with responses, saved after every trial
%   memory_results.csv   - the same table as CSV, written at the end

clearvars; sca;

%% ===== SET THESE BEFORE EACH RUN =====
subj_id  = 1;       % participant number
windowed = true;    % true = 900x700 test window, false = fullscreen
%% ======================================

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'Functions'));

%% 1. Settings
cfg = get_cfg(subj_id);

%% 2. Participant folder (from Day 1) and results file
sub_dir = fullfile(cfg.participants_dir, sprintf('sub-%03d', subj_id));
if ~isfolder(sub_dir)
    r = input(sprintf('No Day 1 folder for participant %d. Continue anyway [y/n]? ', subj_id), 's');
    if ~strcmpi(r, 'y')
        error('Stopped: no Day 1 folder for participant %d.', subj_id);
    end
    mkdir(sub_dir);
end

results_file = fullfile(sub_dir, 'memory_results.mat');
if isfile(results_file)
    r = input('This participant already has memory data. Overwrite [y/n]? ', 's');
    if ~strcmpi(r, 'y')
        error('Participant %d already has memory data and you chose not to overwrite.', subj_id);
    end
end

%% 3. Stimulus list
list_file = fullfile(root, 'Stimulus_lists', sprintf('stimuli_sub-%03d.csv', subj_id));
if ~isfile(list_file)
    error('No stimulus list for participant %d (%s).', subj_id, list_file);
end
stim_list = readtable(list_file, 'TextType', 'char');

%% 4. Test sequence
mseq = create_memory_sequence(stim_list, cfg, subj_id);

% same condition order as Day 1?
enc_file = fullfile(sub_dir, 'sequence.csv');
if isfile(enc_file)
    enc = readtable(enc_file, 'TextType', 'char');
    if ~strcmp(enc.condition{1}, mseq.condition{1})
        warning('Day 1 started with %s, but the memory test starts with %s.', enc.condition{1}, mseq.condition{1});
    end
end

for v = {'onset1', 'offset1', 'onset2', 'choice_onset', 'choice', 'choice_rt', ...
         'correct', 'conf_onset', 'confidence', 'conf_rt'}
    mseq.(v{1}) = nan(height(mseq), 1);
end
writetable(mseq, fullfile(sub_dir, 'memory_sequence.csv'));

pool_dir = fullfile(cfg.stimuli_dir, 'Selection20_resized');

try
    %% 5. Screen
    [scr, win] = set_screen(2, double(windowed), cfg);
    ppd    = scr.pixperdeg;
    img_px = round(cfg.img_size_deg * ppd);

    E = struct();
    E.win          = win;
    E.scr          = scr;
    E.cfg          = cfg;
    E.stim_list    = stim_list;
    E.results_file = results_file;
    E.img_rect     = CenterRectOnPointd([0 0 img_px img_px], scr.center_X, scr.center_Y);
    E.draw_fix     = @() my_optimal_fixationpoint(win, scr.center_X, scr.center_Y, ...
                           cfg.fix_size_deg, cfg.fix_color, scr.bg, ppd);

    % preload every image once
    DrawFormattedText(win, 'Loading images...', 'center', 'center', 0);
    Screen('Flip', win);
    ids   = [mseq.first_id; mseq.second_id];
    paths = [mseq.first_path; mseq.second_path];
    [uids, first] = unique(ids);
    tex_map = containers.Map();
    for k = 1:numel(uids)
        tex_map(uids{k}) = Screen('MakeTexture', win, imread(fullfile(pool_dir, paths{first(k)})));
    end
    E.tex1 = cellfun(@(id) tex_map(id), mseq.first_id);
    E.tex2 = cellfun(@(id) tex_map(id), mseq.second_id);

    %% Instructions
    DrawFormattedText(win, cfg.mem.instruction_text, 'center', 'center', 0);
    draw_trigger(win, cfg, 0);
    Screen('Flip', win);
    wait_key(cfg);

    %% 6. Blocks (one per condition)
    n_blocks = max(mseq.block);
    for b = 1:n_blocks
        mseq = run_memory_block(E, mseq, b);

        if b < n_blocks
            DrawFormattedText(win, cfg.mem.part_break_text, 'center', 'center', 0);
            draw_trigger(win, cfg, 0);
            Screen('Flip', win);
            wait_key(cfg);
        end
    end

    DrawFormattedText(win, 'Done! Thank you very much.', 'center', 'center', 0);
    draw_trigger(win, cfg, 0);
    Screen('Flip', win);
    WaitSecs(2);

    Screen('Close');
    sca; ShowCursor; Priority(0);
    writetable(mseq, fullfile(sub_dir, 'memory_results.csv'));
    fprintf('Session finished. %.0f%% correct overall. Results saved to %s\n', ...
        100 * mean(mseq.correct, 'omitnan'), results_file);

catch err
    sca; ShowCursor; Priority(0);
    if ~any(strcmp(err.identifier, {'memory:quit', 'encoding:quit'}))
        rethrow(err);
    end
    disp(err.message);
    fprintf('All completed trials are saved in %s\n', results_file);
end
