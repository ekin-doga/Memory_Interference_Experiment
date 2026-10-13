function sets = create_concept_sets(out_dir, pool_file)
% CREATE_CONCEPT_SETS - Splits the 165 concepts into 11 balanced sets of 15
%
% Run this ONCE before data collection. It writes the sets to
% <out_dir>/concept_sets.csv; create_stimuli_list_balanced.m then gives each
% participant one of these sets as their high-interference concepts.
%
% The sets are as equal as possible on:
%   1. Category mix   - each set holds each category in proportion to its
%                       size (e.g. 2-3 animals, 1 kitchenware item); exact.
%   2. Within-concept similarity - mean and spread of the conv2 and fc7
%                       within-concept z-scores (alexnet_tables/concept_similarity.csv)
%   3. Luminance / contrast - mean of the concept-level mean luminance and
%                       RMS contrast (image_luminance_contrast.csv)
%   4. No near-identical concepts in the same set - the 1% most similar
%                       concept pairs in fc7 (e.g. minivan / station_wagon,
%                       broccoli / cauliflower) never share a set
%                       (alexnet_tables/concept_distance_fc7.csv)
%
% Method: random category-stratified start, then simulated annealing over
% swaps of same-category concepts between sets (10 runs, best one kept).
% The seed is fixed, so rerunning gives the same sets.
%
% To protect the sets once data collection has started, the function will
% not overwrite an existing concept_sets.csv; delete or rename it first if
% you really want to rebuild.
%
% INPUTS:
%   out_dir   - Folder for the output CSVs (default: ../Stimulus_lists)
%   pool_file - CSV of all stimuli (default: ../Stimuli/Selection20_resized/stimuli_list.csv)
%
% OUTPUTS:
%   sets - Table with columns: subcategory, category, concept_set,
%          conv2_within_z, fc7_within_z, mean_luminance, rms_contrast
%   Files in out_dir:
%     concept_sets.csv          - one row per concept, with its set (1-11)
%     concept_sets_balance.csv  - per-set means / SDs and category counts

%% =========================================================================
%  1. SETTINGS AND DEFAULTS
% ==========================================================================

n_sets     = 11;    % 165 / 15
n_per_set  = 15;    % high-interference concepts per participant

this_dir = fileparts(mfilename('fullpath'));
stim_dir = fullfile(this_dir, '..', 'Stimuli', 'Selection20_resized');
if nargin < 1 || isempty(out_dir)
    out_dir = fullfile(this_dir, '..', 'Stimulus_lists');
end
if nargin < 2 || isempty(pool_file)
    pool_file = fullfile(stim_dir, 'stimuli_list.csv');
end

files.similarity = fullfile(stim_dir, 'alexnet_tables', 'concept_similarity.csv');
files.distance   = fullfile(stim_dir, 'alexnet_tables', 'concept_distance_fc7.csv');
files.luminance  = fullfile(stim_dir, 'image_luminance_contrast.csv');
sets_file        = fullfile(out_dir, 'concept_sets.csv');

if isfile(sets_file)
    error(['%s already exists. The sets should stay fixed once participants have been tested. ' ...
           'Delete or rename the file if you really want to rebuild them.'], sets_file);
end
if ~isfolder(out_dir)
    mkdir(out_dir);
end

%% =========================================================================
%  2. LOAD STIMULUS POOL
% ==========================================================================

opts = detectImportOptions(pool_file, 'Delimiter', ',');
opts = setvartype(opts, {'image_id', 'category', 'subcategory', 'filename', 'path', 'source'}, 'char');
pool = readtable(pool_file, opts);

concepts = unique(pool.subcategory);
if numel(concepts) ~= n_sets * n_per_set
    error('Pool has %d subcategories; %d sets of %d need %d.', ...
        numel(concepts), n_sets, n_per_set, n_sets * n_per_set);
end

%% =========================================================================
%  3. BUILD THE SETS
% ==========================================================================

fprintf('Building %d balanced concept sets (takes about a minute)...\n', n_sets);

rng(2026);                   % fixed seed: the sets are the same every time

n_restarts   = 10;           % independent optimisation runs; best one is kept
n_iter       = 15000;        % swap proposals per run
T_start      = 0.05;         % annealing start temperature
T_decay      = 0.9996;       % temperature multiplier per proposal
w_sd         = 0.5;          % weight of the similarity-spread term
w_conflict   = 10;           % penalty per near-identical pair sharing a set
conflict_pct = 1;            % % most similar concept pairs (fc7) that may not share a set

n = numel(concepts);

% ---- Concept categories ----
cat_of = cell(n, 1);
for k = 1:n
    cat_of(k) = pool.category(find(strcmp(pool.subcategory, concepts{k}), 1));
end
[cat_names, ~, cat_idx] = unique(cat_of);
n_cat = numel(cat_names);

% ---- Concept features: conv2 / fc7 within-concept similarity ----
sopts = detectImportOptions(files.similarity, 'Delimiter', ',');
sopts.VariableNames{1} = 'subcategory';             % first column has no header
sopts = setvartype(sopts, {'subcategory', 'category'}, 'char');
simT  = readtable(files.similarity, sopts);
[ok, loc] = ismember(concepts, simT.subcategory);
if ~all(ok)
    error('Missing in concept_similarity.csv: %s', strjoin(concepts(~ok)', ', '));
end
conv2_z = simT.conv2_within_z(loc);
fc7_z   = simT.fc7_within_z(loc);

% ---- Concept features: luminance / contrast (mean over the 20 images) ----
lopts = detectImportOptions(files.luminance, 'Delimiter', ',');
lopts = setvartype(lopts, {'subcategory'}, 'char');
lumT  = readtable(files.luminance, lopts);
lum = zeros(n, 1);
con = zeros(n, 1);
for k = 1:n
    m = strcmp(lumT.subcategory, concepts{k});
    if ~any(m)
        error('Missing in image_luminance_contrast.csv: %s', concepts{k});
    end
    lum(k) = mean(lumT.mean_luminance(m));
    con(k) = mean(lumT.rms_contrast(m));
end

F  = [conv2_z, fc7_z, lum, con];
Fz = (F - mean(F)) ./ std(F);                        % z-score across concepts
feature_names = {'conv2_within_z', 'fc7_within_z', 'mean_luminance', 'rms_contrast'};

% ---- Forbidden pairs: most similar concept pairs in fc7 ----
distT = readtable(files.distance, 'ReadRowNames', true, 'VariableNamingRule', 'preserve');
[ok, loc] = ismember(concepts, distT.Properties.RowNames);
if ~all(ok)
    error('Missing in concept_distance_fc7.csv: %s', strjoin(concepts(~ok)', ', '));
end
[ok_c, loc_c] = ismember(concepts, distT.Properties.VariableNames);
if ~all(ok_c)
    error('Column names of concept_distance_fc7.csv do not match its row names.');
end
Dm   = distT{loc, loc_c};
upper = triu(true(n), 1);
dsorted = sort(Dm(upper));
thr  = dsorted(max(1, round(conflict_pct / 100 * numel(dsorted))));   % percentile without toolbox
Cpair = double(Dm <= thr & upper);
Cpair = Cpair + Cpair';                              % symmetric, zero diagonal
fprintf('  %d concept pairs may not share a set (fc7 distance <= %.3f)\n', sum(Cpair(:)) / 2, thr);

% ---- How many concepts of each category go into each set ----
n_per_cat = accumarray(cat_idx, 1);

% ---- Random stratified baseline (for comparison in the summary) ----
n_base = 1000;
base_range = zeros(n_base, size(Fz, 2));
base_conf  = zeros(n_base, 1);
for b = 1:n_base
    s = initial_assignment(make_quota(n_per_cat, n_sets), cat_idx, n_cat, n_sets);
    [~, M, ~, nc] = set_cost(membership(s, n_sets), Fz, Cpair, w_sd, w_conflict);
    base_range(b, :) = max(M) - min(M);
    base_conf(b) = nc;
end

% ---- Simulated annealing over within-category swaps ----
best_cost = inf;
for r = 1:n_restarts
    s = initial_assignment(make_quota(n_per_cat, n_sets), cat_idx, n_cat, n_sets);
    A = membership(s, n_sets);
    c = set_cost(A, Fz, Cpair, w_sd, w_conflict);
    T = T_start;
    for it = 1:n_iter
        i    = randi(n);
        cand = find(cat_idx == cat_idx(i) & s ~= s(i));
        if ~isempty(cand)
            j  = cand(randi(numel(cand)));
            s2 = s;  s2([i j])   = s([j i]);
            A2 = A;  A2([i j], :) = A([j i], :);
            c2 = set_cost(A2, Fz, Cpair, w_sd, w_conflict);
            if c2 < c || rand < exp((c - c2) / T)
                s = s2;  A = A2;  c = c2;
            end
        end
        T = T * T_decay;
    end
    fprintf('  run %2d/%d: cost %.4f\n', r, n_restarts, c);
    if c < best_cost
        best_cost = c;
        best_s    = s;
    end
end

[~, M, S, nc] = set_cost(membership(best_s, n_sets), Fz, Cpair, w_sd, w_conflict);
if nc > 0
    warning('%d near-identical concept pairs still share a set.', nc);
end

% ---- Output table ----
sets = table(concepts, cat_of, best_s, conv2_z, fc7_z, lum, con, ...
    'VariableNames', {'subcategory', 'category', 'concept_set', feature_names{:}});
sets = sortrows(sets, {'concept_set', 'category', 'subcategory'});

% ---- Balance summary (raw units) ----
bal = table((1:n_sets)', 'VariableNames', {'concept_set'});
for f = 1:numel(feature_names)
    bal.(['mean_' feature_names{f}]) = accumarray(best_s, F(:, f), [], @mean);
end
bal.sd_conv2_within_z = accumarray(best_s, F(:, 1), [], @std);
bal.sd_fc7_within_z   = accumarray(best_s, F(:, 2), [], @std);
for c = 1:n_cat
    bal.(['n_' matlab.lang.makeValidName(cat_names{c})]) = accumarray(best_s(cat_idx == c), 1, [n_sets 1]);
end
writetable(bal, fullfile(out_dir, 'concept_sets_balance.csv'));

fprintf('\n  Range of set means (max - min, in SDs across concepts):\n');
fprintf('  %-16s %10s %20s\n', 'feature', 'balanced', 'random (median)');
opt_range = max(M) - min(M);
for f = 1:numel(feature_names)
    fprintf('  %-16s %10.3f %20.3f\n', feature_names{f}, opt_range(f), median(base_range(:, f)));
end
fprintf('  %-16s %10d %20.1f\n', 'conflict pairs', nc, mean(base_conf));
fprintf('  Spread of conv2 / fc7 SD across sets: %.3f / %.3f\n\n', max(S(:, 1)) - min(S(:, 1)), max(S(:, 2)) - min(S(:, 2)));

writetable(sets, sets_file);
fprintf('Concept sets written to %s\n', sets_file);
fprintf('Balance summary written to %s\n', fullfile(out_dir, 'concept_sets_balance.csv'));

end


%% =========================================================================
%  LOCAL FUNCTIONS
% ==========================================================================

function Q = make_quota(n_per_cat, n_sets)
% Q(c, k) = number of concepts of category c in set k. Every category is
% spread as evenly as possible, and every set gets the same total.
base  = floor(n_per_cat / n_sets);
extra = n_per_cat - base * n_sets;
Q     = repmat(base, 1, n_sets);
set_load = zeros(1, n_sets);
[~, ord] = sort(extra, 'descend');
for c = ord'
    p = randperm(n_sets);
    [~, o] = sort(set_load(p));                 % least-loaded sets first, ties random
    give = p(o(1:extra(c)));
    Q(c, give) = Q(c, give) + 1;
    set_load(give) = set_load(give) + 1;
end
end


function s = initial_assignment(Q, cat_idx, n_cat, n_sets)
% Random assignment of concepts to sets that satisfies the quota Q
s = zeros(numel(cat_idx), 1);
for c = 1:n_cat
    idx = find(cat_idx == c);
    idx = idx(randperm(numel(idx)));
    s(idx) = repelem((1:n_sets)', Q(c, :)');
end
end


function A = membership(s, n_sets)
A = double(s == (1:n_sets));                % concepts x sets, 0/1
end


function [c, M, S, n_conf] = set_cost(A, Fz, Cpair, w_sd, w_conflict)
% Cost = variance of set means across sets (all features)
%      + w_sd * variance of set SDs across sets (similarity features)
%      + w_conflict * number of near-identical pairs sharing a set
nk = sum(A, 1)';                            % set sizes
M  = (A' * Fz) ./ nk;
S  = sqrt(max((A' * Fz.^2 - nk .* M.^2) ./ (nk - 1), 0));
n_conf = sum(sum((A' * Cpair) .* A')) / 2;
c = sum(var(M)) + w_sd * sum(var(S(:, 1:2))) + w_conflict * n_conf;
end
