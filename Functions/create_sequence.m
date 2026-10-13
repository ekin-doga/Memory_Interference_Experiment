function seq = create_sequence(stim_list, cfg, subj_id)
% CREATE_SEQUENCE - Encoding trial sequence for one participant
%
% Only targets are shown at encoding (foils are for the Day 2 test).
% The two conditions are kept completely separate: all blocks of one
% condition come first, then all blocks of the other. Each condition has
% cfg.repeat blocks, and each block shows all of that condition's 150
% targets once, in a new random order.
%
% Which condition comes first depends on subj_id:
%   odd  subj_id: high blocks, then low blocks
%   even subj_id: low blocks, then high blocks
% The first image of a block is never the same as the last image of the
% block before.
%
% INPUTS:
%   stim_list - table from create_stimuli_list_balanced
%   cfg       - config from get_cfg (uses repeat, ISI_vals)
%   subj_id   - participant number (seed: subj_id + 1)
%
% If cfg.max_images_per_block is set (testing), each block is cut to that
% many images.
%
% OUTPUT:
%   seq - table, one row per trial: trial, block, condition, repeat,
%         trial_in_block, image_id, category, subcategory, exemplar,
%         filename, path, ISI

rng(subj_id + 1);   % different seed from the stimulus selection

targets = stim_list(strcmp(stim_list.role, 'target'), :);
if mod(subj_id, 2) == 1
    cond_order = {'high', 'low'};
else
    cond_order = {'low', 'high'};
end

blocks  = cell(cfg.repeat * numel(cond_order), 1);
b       = 0;
last_id = '';

for c = 1:numel(cond_order)
    imgs_c = targets(strcmp(targets.condition, cond_order{c}), :);

    for r = 1:cfg.repeat
        b = b + 1;

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

        n = height(imgs);
        imgs.repeat         = repmat(r, n, 1);
        imgs.block          = repmat(b, n, 1);
        imgs.trial_in_block = (1:n)';
        blocks{b} = imgs;
        last_id   = imgs.image_id{end};
    end
end

seq = vertcat(blocks{:});
seq.trial = (1:height(seq))';
seq.ISI   = reshape(cfg.ISI_vals(randi(numel(cfg.ISI_vals), height(seq), 1)), [], 1);

seq = seq(:, {'trial', 'block', 'condition', 'repeat', 'trial_in_block', 'image_id', ...
              'category', 'subcategory', 'exemplar', 'filename', 'path', 'ISI'});

fprintf('Sequence: %s first, then %s; %d blocks per condition, %d images per block, %d trials\n', ...
    cond_order{1}, cond_order{2}, cfg.repeat, height(blocks{1}), height(seq));
if ~isempty(cfg.max_images_per_block)
    warning('TEST MODE: blocks are capped at %d images (cfg.max_images_per_block).', cfg.max_images_per_block);
end
fprintf('Estimated duration without breaks: %.0f min\n', ...
    height(seq) * (cfg.stim_dur + mean(cfg.ISI_vals)) / 60);
end
