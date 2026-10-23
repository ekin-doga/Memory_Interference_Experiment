function seq = add_triggers_encoding(seq, cfg)
% ADD_TRIGGERS_ENCODING - Adds the expected EEG trigger codes to the Day 1 sequence
%
% Called in run_encoding right after create_sequence (and again after
% loading a sequence to resume), so the codes are in the sequence CSV and the
% results. present_block sends exactly these codes.
%
% Columns added (codes from cfg.triggers, see get_cfg / trigger_codes.txt):
%   trig_image - image onset: target 128 + category number (image_trigger),
%                catch flower cfg.triggers.catch_image
%   trig_fix   - fixation onset at image offset: fixation.<condition>
%
% Per block (not in the table): block_start.<condition> with the 1 s
% fixation before the first image, block_end after the last ISI.
% Errors if a category has no trigger code, so this is found before the
% screen opens.

n = height(seq);
trig_image = zeros(n, 1);
trig_fix   = zeros(n, 1);
for t = 1:n
    if seq.is_catch(t)
        trig_image(t) = cfg.triggers.catch_image;
    else
        trig_image(t) = image_trigger(cfg, seq.category{t}, false);
    end
    trig_fix(t) = cfg.triggers.fixation.(seq.condition{t});
end
seq.trig_image = trig_image;
seq.trig_fix   = trig_fix;
end
