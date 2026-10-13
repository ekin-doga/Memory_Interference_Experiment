function [set1, set2] = select_stimuli_new(cfg)
% SELECT_STIMULI_NEW - Selects stimuli for the new experiment
%
% Set 1: 120 images (3 categories × 10 typicality bins × 1 per bin)
%        The same images are shown in every block, in a different random order.
%
% Set 2: 3 attention-check images (bathroom images, manually specified in cfg).
%        These are fixed across participants and blocks.
%
% INPUTS:
%   cfg  - Configuration struct from get_cfg()
%
% OUTPUTS:
%   set1 - Table of Set 1 stimuli with columns:
%            id, category, stimulus, p_typicality, block
%   set2 - Table of Set 2 (attention-check) stimuli with columns:
%            id, category, stimulus, is_attn_check

%% =========================================================================
%  1. LOAD STIMULUS DATABASE
% ==========================================================================

images_all = readtable(cfg.path_to_table);
images_all.id = (1:height(images_all))';

scene_categories = unique(images_all.category);
n_categories = length(scene_categories);

if n_categories ~= cfg.n_categories
    warning('Database has %d categories, cfg expects %d.', n_categories, cfg.n_categories);
end

%% =========================================================================
%  2. SELECT SET 1 — 4 images per category per typicality bin per block
% ==========================================================================

rng(cfg.seed);

set1 = table();

for c = 1:n_categories
    cat_mask = strcmp(images_all.category, scene_categories{c});
    images_cat = images_all(cat_mask, :);

    for t = 1:cfg.n_bins
        bin_mask = images_cat.p_typicality == t;
        images_bin = images_cat(bin_mask, :);

        n_needed = cfg.n_per_bin;

        if height(images_bin) < n_needed
            error('Not enough images in category "%s", bin %d. Need %d, have %d.', ...
                scene_categories{c}, t, n_needed, height(images_bin));
        end

        % Sample without replacement
        selected_idx = randperm(height(images_bin), n_needed);
        selected = images_bin(selected_idx, :);

        % Extract bare filename from stimulus path
        % e.g. 'stimuli/bedroom/img_c2pbs.png' → 'img_c2pbs.png'
        for s = 1:height(selected)
            [~, fname, ext] = fileparts(selected.stimulus{s});
            selected.stimulus{s} = [fname, ext];
        end

        % All images appear in every block (no block label needed)
        selected.block = zeros(n_needed, 1);

        set1 = [set1; selected];
    end
end

% Sort for readability
set1 = sortrows(set1, {'block', 'category', 'p_typicality'});

fprintf('Set 1 selected: %d images total (%d per block)\n', ...
    height(set1), cfg.n_set1_per_block);

%% =========================================================================
%  3. BUILD SET 2 — Fixed attention-check images (manually specified)
% ==========================================================================

n_attn = length(cfg.attn_check_images);
set2 = table();
set2.id       = ((height(images_all) + 1) : (height(images_all) + n_attn))';
set2.category = repmat({cfg.attn_check_category}, n_attn, 1);
set2.stimulus = cfg.attn_check_images(:);
set2.is_attn_check = true(n_attn, 1);

fprintf('Set 2 (attention checks): %d images\n', n_attn);

end
