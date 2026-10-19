function stim_list = create_stimuli_list_balanced(subj_id)
% CREATE_STIMULI_LIST_BALANCED - Targets and foils for one participant
%
% 1. Loads the 11 concept sets (Stimulus_lists/concept_sets.csv, made once
%    with create_concept_sets.m).
% 2. Picks this participant's set: participants 1-11 get sets 1-11,
%    participants 12-22 get sets 1-11 again.
% 3. The 15 concepts in that set are high interference (10 targets + 10 foils
%    each); the other 150 concepts are low interference (1 target + 1 foil).
%
% Which images are targets and foils follows a fixed rotation, so that after
% 22 participants every image has been a target once and a foil once in
% each condition:
%
%   - Each concept's 20 exemplars are put in a fixed random order (the same
%     for every participant): positions 1-20.
%   - High interference: positions 1-10 are targets and 11-20 foils in
%     round 1 (participants 1-11); swapped in round 2 (participants 12-22).
%   - Low interference: in each round, the 10 participants who have the
%     concept as low interference each get their own pair: position k as
%     target and position k+10 as foil (k = 1-10). So within a round the
%     low-interference targets/foils are exactly the high-interference
%     targets/foils, and the Day 2 test pairs are the same in both
%     conditions. Target and foil swap in round 2.
%
% Test pairs (column 'pair'): a target and a foil with the same pair number
% are tested against each other in the Day 2 2AFC. High interference: rotation
% position i is paired with i+10 (pairs 1-10); low interference: the
% participant's single target and foil (pair 1), i.e. also position k with
% k+10. Pairs stay the same in round
% 2, only target and foil swap, so every pair is tested once in each direction.
%
% Only participants 1-22 (one full cycle) are set up so far.
%
% Output: table written to Stimulus_lists/stimuli_sub-XXX.csv
% (this file lives in Stimulus_lists/functions/)

if subj_id < 1 || subj_id > 22
    error('Only participants 1-22 are set up (first cycle).');
end

% Paths: this file is in <root>/Stimulus_lists/functions/
lists_dir = fileparts(fileparts(mfilename('fullpath')));   % <root>/Stimulus_lists
root      = fileparts(lists_dir);                           % experiment root
pool = readtable(fullfile(root, 'Stimuli', 'Selection20_resized', 'stimuli_list.csv'), 'TextType', 'char');
sets = readtable(fullfile(lists_dir, 'concept_sets.csv'), 'TextType', 'char');

% This participant's set and round
set_nr = mod(subj_id - 1, 11) + 1;     % 1-11
round2 = subj_id > 11;                 % false for 1-11, true for 12-22

% Fixed exemplar order per concept (same for every participant)
concepts = unique(pool.subcategory);
rng(2026);
order = cell(numel(concepts), 1);
for i = 1:numel(concepts)
    order{i} = randperm(20);
end

stim_list = table();

for i = 1:numel(concepts)
    imgs = pool(strcmp(pool.subcategory, concepts{i}), :);
    imgs = sortrows(imgs, 'exemplar');
    imgs = imgs(order{i}, :);                          % rows now in rotation order 1-20

    concept_set = sets.concept_set(strcmp(sets.subcategory, concepts{i}));

    if concept_set == set_nr
        % High interference: first half vs second half
        condition = 'high';
        targets = imgs(1:10, :);
        foils   = imgs(11:20, :);
    else
        % Low interference: participant's position among the 10 participants
        % in this round who have the concept as low interference
        condition = 'low';
        pos = set_nr - (set_nr > concept_set);         % 1-10
        targets = imgs(pos, :);                         % same pair as high
        foils   = imgs(pos + 10, :);                    % interference pair pos
    end

    if round2
        [targets, foils] = deal(foils, targets);        % swap roles in round 2
    end

    pick = [targets; foils];
    n = height(targets);
    pick.condition = repmat({condition}, 2 * n, 1);
    pick.role      = [repmat({'target'}, n, 1); repmat({'foil'}, n, 1)];
    pick.pair      = [(1:n)'; (1:n)'];                % i-th target is tested against i-th foil
    stim_list = [stim_list; pick]; %#ok<AGROW>
end

stim_list.subject     = repmat(subj_id, height(stim_list), 1);
stim_list.concept_set = repmat(set_nr, height(stim_list), 1);
stim_list = stim_list(:, {'subject', 'concept_set', 'image_id', 'condition', 'role', ...
                          'category', 'subcategory', 'exemplar', 'pair', 'filename', 'path'});

% Quick check: 15 x 20 high + 150 x 2 low = 300 + 300 images
fprintf('Subject %d, set %d, round %d: %d high and %d low images\n', subj_id, set_nr, 1 + round2, ...
    sum(strcmp(stim_list.condition, 'high')), sum(strcmp(stim_list.condition, 'low')));

writetable(stim_list, fullfile(lists_dir, sprintf('stimuli_sub-%03d.csv', subj_id)));
end
