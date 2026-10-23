function mseq = add_triggers_memory(mseq, cfg)
% ADD_TRIGGERS_MEMORY - Adds the expected EEG trigger codes to the Day 2 sequence
%
% Called in run_memory right after create_memory_sequence (and again after
% loading a sequence to resume), so the codes are in the sequence CSV and the
% results. run_memory_block sends exactly these codes.
%
% Columns added, in the order of a trial (codes from cfg.triggers, see
% get_cfg / trigger_codes.txt):
%   trig_iti     - fixation before image 1: fixation.<condition>;
%                  block_start.<condition> for the first trial of a block
%   trig_image1  - image 1 onset: target 128 / foil 160 + category number
%   trig_isi     - fixation between the images: fixation.<condition>
%   trig_image2  - image 2 onset
%   trig_choice  - choice screen: mem_choice_screen
% Per block (not in the table): block_end after the last trial.
% When resuming in the middle of a block, the first trial after the restart
% sends block_start instead of its trig_iti (marks the restart in the EEG).
% Errors if a category has no trigger code, so this is found before the
% screen opens.

tr = cfg.triggers;
n  = height(mseq);
[trig_iti, trig_image1, trig_isi, trig_image2] = deal(zeros(n, 1));
for t = 1:n
    cond = mseq.condition{t};
    if mseq.trial_in_block(t) == 1
        trig_iti(t) = tr.block_start.(cond);
    else
        trig_iti(t) = tr.fixation.(cond);
    end
    trig_image1(t) = image_trigger(cfg, mseq.category{t}, ~mseq.target_first(t));
    trig_isi(t)    = tr.fixation.(cond);
    trig_image2(t) = image_trigger(cfg, mseq.category{t},  mseq.target_first(t));
end
mseq.trig_iti    = trig_iti;
mseq.trig_image1 = trig_image1;
mseq.trig_isi    = trig_isi;
mseq.trig_image2 = trig_image2;
mseq.trig_choice = repmat(tr.mem_choice_screen, n, 1);
end
