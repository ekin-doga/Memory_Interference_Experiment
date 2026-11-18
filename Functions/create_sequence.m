function seq = create_sequence(stim_list, cfg, subj_id)
% CREATE_SEQUENCE - Encoding trial sequence for one participant
%
% Only targets are shown at encoding (foils are for the Day 2 test).
% Each block contains one condition only. Each condition has cfg.repeat
% blocks, and each block shows all of that condition's 150 targets once, in
% a new random order. The conditions alternate in runs of
% cfg.blocks_per_switch blocks, e.g. repeat = 10, blocks_per_switch = 2:
%   H H L L H H L L ... (20 blocks)
% (blocks_per_switch = repeat: all blocks of one condition, then the other).
%
% Which condition comes first depends on subj_id (condition_order):
%   odd  subj_id: high first
%   even subj_id: low first
% Every block (high and low) is fully shuffled. The first image of a block
% is never the same as the last image of the block before.
%
% INPUTS:
%   stim_list - table from create_stimuli_list_balanced
%   cfg       - config from get_cfg (uses repeat, blocks_per_switch, ISI_vals, catch)
%   subj_id   - participant number (seed: subj_id + 1)
%
% Attention check: every block also gets catch trials (flower images from
% cfg.catch; numel(cfg.catch.files) * cfg.catch.per_image per block, the same
% in both conditions). The block is cut into as many equal segments as there
% are catch trials and each catch trial goes at a random spot in its own
% segment, so they are spread over the block, never back to back and never
% the first or last trial. Which flower goes where is random.
%
% If cfg.max_images_per_block is set (testing), each block is cut to that
% many images (catch trials are added on top).
%
% OUTPUT:
%   seq - table, one row per trial: trial, block, condition, repeat,
%         trial_in_block, is_catch, image_id, category, subcategory, exemplar,
%         filename, path, ISI. For catch trials category = 'Catch',
%         exemplar = NaN and path is relative to cfg.catch.dir (otherwise to
%         Stimuli/Selection20_resized).

rng(subj_id + 1);   % different seed from the stimulus selection

targets = stim_list(strcmp(stim_list.role, 'target'), :);
cond_order = condition_order(subj_id);   % same rule as the Day 2 memory test

% block order: runs of blocks_per_switch blocks, alternating conditions
bps = cfg.blocks_per_switch;
if ~isscalar(bps) || bps < 1 || bps ~= round(bps) || mod(cfg.repeat, bps) ~= 0
    error('cfg.blocks_per_switch (%g) must be a whole number that divides cfg.repeat (%d).', ...
        bps, cfg.repeat);
end
n_runs     = cfg.repeat / bps;
block_cond = repmat(kron(1:numel(cond_order), ones(1, bps)), 1, n_runs);   % e.g. 1 1 2 2 1 1 2 2 ...

blocks  = cell(numel(block_cond), 1);
n_done  = zeros(1, numel(cond_order));   % blocks so far per condition (-> repeat)
last_id = '';


for b = 1:numel(block_cond)
    c = block_cond(b);
    n_done(c) = n_done(c) + 1;
    imgs_c = targets(strcmp(targets.condition, cond_order{c}), :);

    % shuffle; reshuffle if the block would start with the previous image
    p = randperm(height(imgs_c));
    while strcmp(imgs_c.image_id{p(1)}, last_id)
        p = randperm(height(imgs_c));
    end
    imgs = imgs_c(p, :);

    % testing cap: only the first N images of the shuffled block
    if ~isempty(cfg.max_images_per_block)
        imgs = imgs(1:min(cfg.max_images_per_block, height(imgs)), :);
    end

    % attention check: mix in the catch images
    imgs = add_catch(imgs, cfg);

    n = height(imgs);
    imgs.repeat         = repmat(n_done(c), n, 1);   % repetition within the condition
    imgs.block          = repmat(b, n, 1);           % block number in the session
    imgs.trial_in_block = (1:n)';
    blocks{b} = imgs;
    last_id   = imgs.image_id{end};
end

seq = vertcat(blocks{:});
seq.trial = (1:height(seq))';
seq.ISI   = reshape(cfg.ISI_vals(randi(numel(cfg.ISI_vals), height(seq), 1)), [], 1);
seq.ISI(seq.is_catch) = cfg.catch.isi;   % fixed, longer ISI after every flower (space press)

seq = seq(:, {'trial', 'block', 'condition', 'repeat', 'trial_in_block', 'is_catch', 'image_id', ...
              'category', 'subcategory', 'exemplar', 'filename', 'path', 'ISI'});

letters = upper(cellfun(@(s) s(1), cond_order));      % 'HL' or 'LH'
fprintf(['Sequence: %d blocks per condition, switching every %d: %s\n' ...
         '          %d images per block (incl. %d catch), %d trials\n'], ...
    cfg.repeat, bps, strjoin(cellstr(letters(block_cond)'), ' '), height(blocks{1}), ...
    sum(blocks{1}.is_catch), height(seq));
if ~isempty(cfg.max_images_per_block)
    warning('TEST MODE: blocks are capped at %d images (cfg.max_images_per_block).', cfg.max_images_per_block);
end
fprintf('Estimated duration without breaks: %.0f min\n', ...
    (height(seq) * cfg.stim_dur + sum(seq.ISI) + max(seq.block) * cfg.block_start_fix) / 60);
end


function imgs = add_catch(imgs, cfg)
% ADD_CATCH - Inserts the catch trials (flowers) into one block
% Slot j means: the catch trial comes right after image j (j = 1..n-1), so
% it is never the first or last trial. The n-1 slots are cut into k equal
% segments and each catch trial gets a random slot in its own segment, so
% they are spread over the block and never back to back.
imgs.is_catch = false(height(imgs), 1);
files = cfg.catch.files;
k = numel(files) * cfg.catch.per_image;
n = height(imgs);
if k > n - 1                                     % only in test mode
    warning('Block of %d images is too short for %d catch trials; using %d.', n, k, max(n - 1, 0));
    k = max(n - 1, 0);
end
if k == 0
    return;
end

edges = round(linspace(0, n - 1, k + 1));
slots = zeros(k, 1);
for s = 1:k
    seg = (edges(s) + 1):edges(s + 1);
    slots(s) = seg(randi(numel(seg)));
end

% which flower in which slot: each flower per_image times, random order
which = repmat(1:numel(files), 1, cfg.catch.per_image);
which = which(randperm(numel(which)));
which = which(1:k);

c = repmat(imgs(1, :), k, 1);                    % same columns as the targets
for m = 1:k
    [~, name] = fileparts(files{which(m)});
    c.image_id{m}    = ['catch_' name];
    c.role{m}        = 'catch';
    c.category{m}    = 'Catch';
    c.subcategory{m} = 'flower';
    c.exemplar(m)    = NaN;
    c.pair(m)        = NaN;
    c.filename{m}    = files{which(m)};
    c.path{m}        = files{which(m)};          % relative to cfg.catch.dir
    c.is_catch(m)    = true;
end

[~, o] = sort([(1:n)'; slots + 0.5]);            % catch m right after image slots(m)
imgs = [imgs; c];
imgs = imgs(o, :);
end
