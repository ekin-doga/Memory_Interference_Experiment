function stim_list = create_stimuli_list_balanced(subj_id)
% CREATE_STIMULI_LIST_BALANCED - Targets and foils for one participant
%
%   High interference: 15 concepts  x 10 targets + 10 foils
%   Low interference:  150 concepts x 1 target  + 1 foil
%   Foils always come from the same concept as their targets.
%
% The 15 high-interference concepts are one of the 11 fixed, balanced
% concept sets in Stimulus_lists/concept_sets.csv (made once with
% create_concept_sets.m):
%   set = mod(subj_id - 1, 11) + 1
% so subjects 1-11 get sets 1-11, subject 12 gets set 1 again, and so on.
%
% Which exemplars become targets and foils is random, with subj_id as the
% seed, so a participant's list can always be regenerated exactly.
%
% INPUT:
%   subj_id - participant number
%
% OUTPUT:
%   stim_list - table with columns: subject, concept_set, image_id,
%               condition ('high'/'low'), role ('target'/'foil'), category,
%               subcategory, exemplar, filename, path
%               also written to Stimulus_lists/stimuli_sub-XXX.csv

%% Settings
n_high_per_sub = 10;    % targets (and foils) per high-interference concept
n_low_per_sub  = 1;     % targets (and foils) per low-interference concept
n_sets         = 11;

root      = fullfile(fileparts(mfilename('fullpath')), '..');
pool_file = fullfile(root, 'Stimuli', 'Selection20_resized', 'stimuli_list.csv');
out_dir   = fullfile(root, 'Stimulus_lists');
sets_file = fullfile(out_dir, 'concept_sets.csv');

if ~isfile(sets_file)
    error('%s not found. Run create_concept_sets() once first.', sets_file);
end

%% Load pool and concept sets
opts = detectImportOptions(pool_file, 'Delimiter', ',');
opts = setvartype(opts, {'image_id', 'category', 'subcategory', 'filename', 'path', 'source'}, 'char');
pool = readtable(pool_file, opts);

sopts = detectImportOptions(sets_file, 'Delimiter', ',');
sopts = setvartype(sopts, {'subcategory', 'category'}, 'char');
sets  = readtable(sets_file, sopts);

concepts = unique(pool.subcategory);
if ~isequal(sort(sets.subcategory), concepts)
    error('concept_sets.csv does not match the concepts in stimuli_list.csv.');
end

set_idx   = mod(subj_id - 1, n_sets) + 1;
high_subs = sets.subcategory(sets.concept_set == set_idx);

%% Pick targets and foils
rng(subj_id);
stim_list = table();

for s = 1:numel(concepts)
    if ismember(concepts{s}, high_subs)
        condition = 'high';
        n_per_sub = n_high_per_sub;
    else
        condition = 'low';
        n_per_sub = n_low_per_sub;
    end

    imgs = pool(strcmp(pool.subcategory, concepts{s}), :);
    if height(imgs) < 2 * n_per_sub
        error('Concept "%s" has %d images, needs %d.', concepts{s}, height(imgs), 2 * n_per_sub);
    end

    sel = imgs(randperm(height(imgs), 2 * n_per_sub), :);
    sel.condition = repmat({condition}, 2 * n_per_sub, 1);
    sel.role      = [repmat({'target'}, n_per_sub, 1); repmat({'foil'}, n_per_sub, 1)];
    stim_list = [stim_list; sel]; %#ok<AGROW>
end

stim_list.subject     = repmat(subj_id, height(stim_list), 1);
stim_list.concept_set = repmat(set_idx, height(stim_list), 1);
stim_list = stim_list(:, {'subject', 'concept_set', 'image_id', 'condition', 'role', ...
                          'category', 'subcategory', 'exemplar', 'filename', 'path'});
stim_list = sortrows(stim_list, {'condition', 'category', 'subcategory', 'role'}, ...
                     {'ascend', 'ascend', 'ascend', 'descend'});

%% Checks
is_high = strcmp(stim_list.condition, 'high');
assert(numel(unique(stim_list.image_id)) == height(stim_list), 'Duplicate images selected.');
assert(numel(high_subs) == 15, 'Concept set %d does not have 15 concepts.', set_idx);
assert(sum(is_high)  == 2 * 15  * n_high_per_sub, 'Wrong number of high-interference images.');
assert(sum(~is_high) == 2 * 150 * n_low_per_sub,  'Wrong number of low-interference images.');

%% Write
out_file = fullfile(out_dir, sprintf('stimuli_sub-%03d.csv', subj_id));
writetable(stim_list, out_file);

fprintf('Subject %d: concept set %d, %d images (%d high, %d low)\n', ...
    subj_id, set_idx, height(stim_list), sum(is_high), sum(~is_high));
fprintf('High-interference concepts: %s\n', strjoin(sort(high_subs)', ', '));
fprintf('Written to %s\n', out_file);
end
