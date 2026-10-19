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
% High-interference blocks follow cfg.high_order:
%   'random'  - fully shuffled (default)
%   'grouped' - the exemplars of each concept are shown back to back; the
%               concept order and the exemplar order within each concept are
%               reshuffled in every repetition. A block never starts with the
%               concept that ended the previous block.
%
% INPUTS:
%   stim_list - table from create_stimuli_list_balanced
%   cfg       - config from get_cfg (uses repeat, ISI_vals)
%   subj_id   - participant number (seed: subj_id + 1)
%
% Attention check: every block also gets catch trials (flower images from
% cfg.catch; numel(cfg.catch.files) * cfg.catch.per_image per block, the same
% in both conditions). The block is cut into as many equal segments as there
% are catch trials and each catch trial goes at a random spot in its own
% segment, so they are spread over the block, never back to back and never
% the first or last trial. In 'grouped' high blocks a catch trial only goes
% between two concepts. Which flower goes where is random.
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

blocks  = cell(cfg.repeat * numel(cond_order), 1);
b       = 0;
last_id = '';
last_concept = '';

if ~isfield(cfg, 'high_order') || isempty(cfg.high_order)
    cfg.high_order = 'random';
end
if ~any(strcmp(cfg.high_order, {'random', 'grouped'}))
    error('cfg.high_order must be ''random'' or ''grouped'' (got ''%s'').', cfg.high_order);
end

for c = 1:numel(cond_order)
    imgs_c = targets(strcmp(targets.condition, cond_order{c}), :);

    for r = 1:cfg.repeat
        b = b + 1;

        if strcmp(cond_order{c}, 'high') && strcmp(cfg.high_order, 'grouped')
            % concepts in random order, each concept's exemplars back to back
            p = grouped_order(imgs_c, last_concept);
        else
            % shuffle; reshuffle if the block would start with the previous image
            p = randperm(height(imgs_c));
            while strcmp(imgs_c.image_id{p(1)}, last_id)
                p = randperm(height(imgs_c));
            end
        end
        imgs = imgs_c(p, :);

        % testing cap: only the first N images of the shuffled block
        if ~isempty(cfg.max_images_per_block)
            imgs = imgs(1:min(cfg.max_images_per_block, height(imgs)), :);
        end

        % attention check: mix in the catch images
        grouped = strcmp(cond_order{c}, 'high') && strcmp(cfg.high_order, 'grouped');
        imgs = add_catch(imgs, cfg, grouped);

        n = height(imgs);
        imgs.repeat         = repmat(r, n, 1);
        imgs.block          = repmat(b, n, 1);
        imgs.trial_in_block = (1:n)';
        blocks{b} = imgs;
        last_id   = imgs.image_id{end};
        last_concept = imgs.subcategory{end};
    end
end

seq = vertcat(blocks{:});
seq.trial = (1:height(seq))';
seq.ISI   = reshape(cfg.ISI_vals(randi(numel(cfg.ISI_vals), height(seq), 1)), [], 1);

seq = seq(:, {'trial', 'block', 'condition', 'repeat', 'trial_in_block', 'is_catch', 'image_id', ...
              'category', 'subcategory', 'exemplar', 'filename', 'path', 'ISI'});

fprintf(['Sequence: %s first, then %s; %d blocks per condition, %d images per block ' ...
         '(incl. %d catch), %d trials (high blocks: %s)\n'], ...
    cond_order{1}, cond_order{2}, cfg.repeat, height(blocks{1}), sum(blocks{1}.is_catch), ...
    height(seq), cfg.high_order);
if ~isempty(cfg.max_images_per_block)
    warning('TEST MODE: blocks are capped at %d images (cfg.max_images_per_block).', cfg.max_images_per_block);
end
fprintf('Estimated duration without breaks: %.0f min\n', ...
    height(seq) * (cfg.stim_dur + mean(cfg.ISI_vals)) / 60);
end


function p = grouped_order(imgs, last_concept)
% GROUPED_ORDER - Row order with each concept's exemplars back to back
% Concept order is random, and so is the exemplar order within each concept.
% The first concept is never the one that ended the previous block.
concepts = unique(imgs.subcategory);
order = concepts(randperm(numel(concepts)));
while numel(order) > 1 && strcmp(order{1}, last_concept)
    order = concepts(randperm(numel(concepts)));
end
p = [];
for k = 1:numel(order)
    idx = find(strcmp(imgs.subcategory, order{k}));
    p = [p; idx(randperm(numel(idx)))]; %#ok<AGROW>
end
end


function imgs = add_catch(imgs, cfg, grouped)
% ADD_CATCH - Inserts the catch trials (flowers) into one block
% Slot j means: the catch trial comes right after image j (j = 1..n-1), so
% it is never the first or last trial. The n-1 slots are cut into k equal
% segments and each catch trial gets a random slot in its own segment, so
% they are spread over the block and never back to back. In grouped blocks
% only slots between two concepts are used (if a segment has none, which
% only happens in test mode, any slot in it is used).
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

if grouped
    ok = [~strcmp(imgs.subcategory(1:end-1), imgs.subcategory(2:end)); false];
else
    ok = true(n, 1);
end
edges = round(linspace(0, n - 1, k + 1));
slots = zeros(k, 1);
for s = 1:k
    seg  = (edges(s) + 1):edges(s + 1);
    cand = seg(ok(seg));
    if isempty(cand)
        cand = seg;
    end
    slots(s) = cand(randi(numel(cand)));
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
