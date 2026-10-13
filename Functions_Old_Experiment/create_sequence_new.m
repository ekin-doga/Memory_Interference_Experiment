function [all_trials] = create_sequence_new(set1, set2, cfg)
% CREATE_SEQUENCE_NEW - Generates trial sequence for the new experiment
%
% Each block consists of:
%   - All Set 1 images (120), same images every block in a different random order
%   - Set 2 attention-check images interspersed, totalling ~10% of trials
%     The 3 attention-check images are distributed as evenly as possible
%     across the n_attn_per_block insertion slots.
%     Attention checks are "old" on their 2nd+ presentation and "new" on
%     their first appearance in a given block.
%
% INPUTS:
%   set1  - Table from select_stimuli_new (Set 1 images)
%   set2  - Table from select_stimuli_new (Set 2 attention-check images)
%   cfg   - Configuration struct from get_cfg()
%
% OUTPUT:
%   all_trials - Trial table with columns:
%     trial, block, im_idx, image_id, category, stimulus, p_typicality,
%     is_attn_check, presentation, ISI, trigger_id
%
% TRIGGER ID ENCODING (category_base + typicality_bin):
%   Bedrooms bin 1-10:     11, 12, 13, 14, 15, 16, 17, 18, 19, 20
%   Kitchens bin 1-10:     21, 22, 23, 24, 25, 26, 27, 28, 29, 30
%   Living rooms bin 1-10: 31, 32, 33, 34, 35, 36, 37, 38, 39, 40
%   Attention check:       50

rng(cfg.seed + 1);  % Offset seed from selection seed

n_blocks    = cfg.n_blocks;
n_attn      = cfg.n_attn_per_block;   % ~13 attention-check insertions per block
n_attn_imgs = height(set2);           % 3 distinct images

all_trials = table();

for block_i = 1:n_blocks

    %% --- Set 1 trials for this block ---
    % Same images every block, reshuffled each time
    s1_block = set1(randperm(height(set1)), :);

    % Build Set 1 trial rows
    n_s1 = height(s1_block);
    s1_trials = table();
    s1_trials.im_idx       = (1:n_s1)';
    s1_trials.image_id     = s1_block.id;
    s1_trials.category     = s1_block.category;
    s1_trials.stimulus     = s1_block.stimulus;
    s1_trials.p_typicality = s1_block.p_typicality;
    s1_trials.is_attn_check = false(n_s1, 1);
    s1_trials.presentation  = ones(n_s1, 1);  % Always first presentation

    %% --- Set 2 (attention check) trial rows ---
    % Distribute n_attn slots evenly across the 3 images
    % E.g., if n_attn=13: images get [5 4 4] or similar
    counts = repmat(floor(n_attn / n_attn_imgs), n_attn_imgs, 1);
    remainder = mod(n_attn, n_attn_imgs);
    counts(1:remainder) = counts(1:remainder) + 1;

    % Build attention-check rows (presentation assigned after interleaving)
    attn_rows = table();
    for img_i = 1:n_attn_imgs
        n_reps = counts(img_i);
        rows = table();
        rows.im_idx        = repmat(n_s1 + img_i, n_reps, 1);  % index after set1
        rows.image_id      = repmat(set2.id(img_i), n_reps, 1);
        rows.category      = repmat(set2.category(img_i), n_reps, 1);
        rows.stimulus      = repmat(set2.stimulus(img_i), n_reps, 1);
        rows.p_typicality  = zeros(n_reps, 1);   % not applicable
        rows.is_attn_check = true(n_reps, 1);
        rows.presentation  = zeros(n_reps, 1);   % placeholder; set after interleaving
        attn_rows = [attn_rows; rows];
    end

    % Shuffle attention-check rows before insertion
    attn_rows = attn_rows(randperm(height(attn_rows)), :);

    %% --- Interleave: scatter attention checks into Set 1 stream ---
    % Pick n_attn random insertion positions within the combined sequence
    total_trials = n_s1 + n_attn;
    insert_positions = sort(randperm(total_trials, n_attn));

    % Build final ordered sequence
    block_trials = table();
    s1_idx   = 1;
    attn_idx = 1;

    for pos = 1:total_trials
        if any(insert_positions == pos) && attn_idx <= height(attn_rows)
            block_trials = [block_trials; attn_rows(attn_idx, :)];
            attn_idx = attn_idx + 1;
        else
            block_trials = [block_trials; s1_trials(s1_idx, :)];
            s1_idx = s1_idx + 1;
        end
    end

    % Handle any leftover s1 trials (if insert_positions caused misalignment)
    while s1_idx <= height(s1_trials)
        block_trials = [block_trials; s1_trials(s1_idx, :)];
        s1_idx = s1_idx + 1;
    end

    % Recompute presentation counter in sequence order (per image_id)
    seen = containers.Map('KeyType', 'int32', 'ValueType', 'int32');
    for i = 1:height(block_trials)
        img_id = block_trials.image_id(i);
        if isKey(seen, img_id)
            seen(img_id) = seen(img_id) + 1;
        else
            seen(img_id) = 1;
        end
        block_trials.presentation(i) = seen(img_id);
    end

    n_block_trials = height(block_trials);
    block_trials.block = repmat(block_i, n_block_trials, 1);
    trial_offset = height(all_trials);
    block_trials.trial = (trial_offset + 1 : trial_offset + n_block_trials)';

    all_trials = [all_trials; block_trials];
end

%% --- Assign per-trial ISI ---
n_total = height(all_trials);
isi_idx = randi(length(cfg.ISI_vals), n_total, 1);
all_trials.ISI = cfg.ISI_vals(isi_idx)';

%% --- Assign trigger IDs ---
% Encoding: category_base + typicality_bin
%   Bedrooms:     10 + bin  →  11-20
%   Kitchens:     20 + bin  →  21-30
%   Living rooms: 30 + bin  →  31-40
%   Attn check:   50

cat_base_map = containers.Map(...
    {'bedrooms', 'kitchens', 'living_rooms'}, ...
    {cfg.triggers.base_bedrooms, cfg.triggers.base_kitchens, cfg.triggers.base_livingrooms});

all_trials.trigger_id = zeros(height(all_trials), 1);

for i = 1:height(all_trials)
    if all_trials.is_attn_check(i)
        all_trials.trigger_id(i) = cfg.triggers.attn_check;
    else
        if iscell(all_trials.category)
            cat_name = all_trials.category{i};
        else
            cat_name = char(all_trials.category(i));
        end
        all_trials.trigger_id(i) = cat_base_map(cat_name) + all_trials.p_typicality(i);
    end
end

fprintf('Sequence generated: %d total trials across %d block(s)\n', ...
    height(all_trials), n_blocks);
fprintf('  Set 1 trials per block: %d\n', cfg.n_set1_per_block);
fprintf('  Attention-check insertions per block: %d (%.1f%% of total)\n', ...
    n_attn, 100 * n_attn / (cfg.n_set1_per_block + n_attn));

end
