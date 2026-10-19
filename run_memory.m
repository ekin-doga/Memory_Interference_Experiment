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
%   sub-XXX_memory_sequence_<date>.csv - planned trials (written before the session)
%   sub-XXX_memory_results_<date>.mat  - mseq with responses, saved after every trial
%   sub-XXX_memory_results_<date>.csv  - the same table as CSV, written at the end
% <date> is the day the session started (yyyy-MM-dd); every row also has
% subj_id and session_date.

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

[resume, session_date] = ask_resume(sub_dir, subj_id, 'memory');
prefix        = fullfile(sub_dir, sprintf('sub-%03d_memory', subj_id));
sequence_file = sprintf('%s_sequence_%s.csv', prefix, session_date);
results_file  = sprintf('%s_results_%s.mat', prefix, session_date);
results_csv   = sprintf('%s_results_%s.csv', prefix, session_date);

%% 3. Stimulus list
list_file = fullfile(root, 'Stimulus_lists', sprintf('stimuli_sub-%03d.csv', subj_id));
if ~isfile(list_file)
    error('No stimulus list for participant %d (%s).', subj_id, list_file);
end
stim_list = readtable(list_file, 'TextType', 'char');

%% 4. Test sequence
mseq = create_memory_sequence(stim_list, cfg, subj_id);

% same condition order as Day 1?
enc_files = dir(fullfile(sub_dir, sprintf('sub-%03d_encoding_sequence_*.csv', subj_id)));
if isempty(enc_files)
    warning('No Day 1 encoding files found for participant %d.', subj_id);
else
    enc = readtable(fullfile(sub_dir, enc_files(end).name), 'TextType', 'char');
    if ~strcmp(enc.condition{1}, mseq.condition{1})
        warning('Day 1 started with %s, but the memory test starts with %s.', enc.condition{1}, mseq.condition{1});
    end
end

for v = {'onset1', 'offset1', 'onset2', 'choice_onset', 'choice', 'choice_rt', ...
         'correct', 'conf_onset', 'confidence', 'conf_rt'}
    mseq.(v{1}) = nan(height(mseq), 1);
end
mseq = addvars(mseq, repmat(subj_id, height(mseq), 1), repmat({session_date}, height(mseq), 1), ...
    'Before', 1, 'NewVariableNames', {'subj_id', 'session_date'});

if resume
    % continue with the saved sequence: trials with a confidence rating are done
    old = load(results_file, 'mseq');
    if height(old.mseq) ~= height(mseq) || ~isequal(old.mseq.first_id, mseq.first_id) ...
            || ~isequal(old.mseq.second_id, mseq.second_id)
        error(['The saved memory results of participant %d do not match the sequence made now ' ...
               '(was get_cfg changed, e.g. max_images_per_block?).'], subj_id);
    end
    mseq = old.mseq;
    n_done = sum(~isnan(mseq.confidence));
    if n_done == height(mseq)
        error('Participant %d already finished the memory test; nothing to resume.', subj_id);
    end
    fprintf('Resuming: %d of %d trials done, continuing with trial %d.\n', ...
        n_done, height(mseq), n_done + 1);
else
    writetable(mseq, sequence_file);
end

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
    Screen('Flip', win);
    wait_key(cfg);

    %% 6. Blocks (one per condition)
    blocks = unique(mseq.block)';
    blocks = blocks(arrayfun(@(b) any(isnan(mseq.confidence(mseq.block == b))), blocks)); % not done yet
    for k = 1:numel(blocks)
        mseq = run_memory_block(E, mseq, blocks(k));

        if k < numel(blocks)
            DrawFormattedText(win, cfg.mem.part_break_text, 'center', 'center', 0);
            Screen('Flip', win);
            wait_key(cfg);
        end
    end

    DrawFormattedText(win, 'Done! Thank you very much.', 'center', 'center', 0);
    Screen('Flip', win);
    WaitSecs(2);

    Screen('Close');
    sca; ShowCursor; Priority(0);
    writetable(mseq, results_csv);
    fprintf('Session finished. %.0f%% correct overall. Results saved to %s (and .csv)\n', ...
        100 * mean(mseq.correct, 'omitnan'), results_file);

catch err
    sca; ShowCursor; Priority(0);
    % mseq in the workspace is only updated after a whole block; the file has
    % every completed trial, so load it back
    if isfile(results_file)
        load(results_file, 'mseq');
    end
    if ~any(strcmp(err.identifier, {'memory:quit', 'encoding:quit'}))
        rethrow(err);
    end
    disp(err.message);
    fprintf(['All completed trials are saved in %s\n' ...
             'Run again with the same subj_id and choose r to resume.\n'], results_file);
end
