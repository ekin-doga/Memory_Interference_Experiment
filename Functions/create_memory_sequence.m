function mseq = create_memory_sequence(stim_list, cfg, subj_id)
% CREATE_MEMORY_SEQUENCE - Day 2 2AFC test trials for one participant
%
% One trial per target-foil pair: the target and the foil of the same
% concept with the same 'pair' number (from the participant's stimulus
% list) are shown one after the other, and the participant chooses which
% one they saw on Day 1.
%
%   - The two conditions are tested in separate blocks, in the same order
%     as at encoding (condition_order: odd subj_id high first, even low first).
%   - Trial order within a block is random.
%   - The target comes first in exactly half of the trials of each block
%     (75 of 150), randomly assigned.
%
% If cfg.max_images_per_block is set (test mode), each block is cut to that
% many trials (the 50/50 target-first balance is then only approximate).
%
% INPUTS:
%   stim_list - participant's list (Stimulus_lists/stimuli_sub-XXX.csv)
%   cfg       - config from get_cfg
%   subj_id   - participant number (seed: subj_id + 2)
%
% OUTPUT:
%   mseq - table, one row per trial: trial, block, condition, trial_in_block,
%          category, subcategory, pair, target_id, foil_id, target_exemplar,
%          foil_exemplar, target_first, first_id, second_id, first_path,
%          second_path, correct_choice (1 = first image, 2 = second image)

rng(subj_id + 2);   % separate from the encoding order (subj_id + 1)

cond_order = condition_order(subj_id);
blocks = cell(numel(cond_order), 1);

for b = 1:numel(cond_order)
    cond = cond_order{b};
    in_c = strcmp(stim_list.condition, cond);
    T = stim_list(in_c & strcmp(stim_list.role, 'target'), :);
    F = stim_list(in_c & strcmp(stim_list.role, 'foil'), :);

    % match every target with the foil of the same concept and pair number
    key_T = compose("%s#%d", string(T.subcategory), T.pair);
    key_F = compose("%s#%d", string(F.subcategory), F.pair);
    [found, loc] = ismember(key_T, key_F);
    if ~all(found) || numel(unique(loc)) ~= height(T) || height(F) ~= height(T)
        error('Targets and foils of the %s condition do not form complete pairs.', cond);
    end
    F = F(loc, :);

    % random trial order; target first in exactly half of the trials
    n = height(T);
    p = randperm(n);
    T = T(p, :);
    F = F(p, :);
    target_first = false(n, 1);
    target_first(randperm(n, floor(n / 2))) = true;

    % test mode: fewer trials
    if ~isempty(cfg.max_images_per_block)
        n = min(cfg.max_images_per_block, n);
        T = T(1:n, :);  F = F(1:n, :);  target_first = target_first(1:n);
    end

    blk = table();
    blk.block           = repmat(b, n, 1);
    blk.condition       = repmat({cond}, n, 1);
    blk.trial_in_block  = (1:n)';
    blk.category        = T.category;
    blk.subcategory     = T.subcategory;
    blk.pair            = T.pair;
    blk.target_id       = T.image_id;
    blk.foil_id         = F.image_id;
    blk.target_exemplar = T.exemplar;
    blk.foil_exemplar   = F.exemplar;
    blk.target_first    = target_first;

    blk.first_id    = T.image_id;   blk.first_id(~target_first)    = F.image_id(~target_first);
    blk.second_id   = F.image_id;   blk.second_id(~target_first)   = T.image_id(~target_first);
    blk.first_path  = T.path;       blk.first_path(~target_first)  = F.path(~target_first);
    blk.second_path = F.path;       blk.second_path(~target_first) = T.path(~target_first);
    blk.correct_choice = 2 - double(target_first);     % 1 = first image, 2 = second image

    blocks{b} = blk;
end

mseq = vertcat(blocks{:});
mseq.trial = (1:height(mseq))';
mseq = movevars(mseq, 'trial', 'Before', 1);

fprintf('Memory test: %s first, then %s; %d trials (%d target-first)\n', ...
    cond_order{1}, cond_order{2}, height(mseq), sum(mseq.target_first));
if ~isempty(cfg.max_images_per_block)
    warning('TEST MODE: memory blocks are capped at %d trials (cfg.max_images_per_block).', cfg.max_images_per_block);
end
end
