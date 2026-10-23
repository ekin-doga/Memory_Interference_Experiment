function code = image_trigger(cfg, category, is_foil)
% IMAGE_TRIGGER - Trigger code for an image onset (both days)
%
%   target: cfg.triggers.target_base + category number (129-137)
%   foil:   cfg.triggers.foil_base   + category number (161-169, Day 2)
% Category numbers = position in cfg.triggers.category_names (1-9).
% (Catch flowers have their own code, cfg.triggers.catch_image.)
%
% INPUTS:
%   cfg      - config from get_cfg
%   category - category name as in the stimulus list, e.g. 'Animals'
%   is_foil  - true for a foil (Day 2), false for a target

k = find(strcmp(cfg.triggers.category_names, category), 1);
if isempty(k)
    error('image_trigger:category', ...
        'Category "%s" has no trigger code (cfg.triggers.category_names in get_cfg).', category);
end
if is_foil
    code = cfg.triggers.foil_base + k;
else
    code = cfg.triggers.target_base + k;
end
end
