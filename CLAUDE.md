# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Stimulus preparation and Psychtoolbox presentation code for an EEG memory-interference experiment (Day 1 encoding; foils are reserved for a Day 2 test). There is no build, lint or test tooling. Code is MATLAB plus Python Jupyter notebooks for stimulus checks. Text shown to participants is in English for now (all participant-facing text is in `get_cfg.m`: Day 1 in `cfg.enc.*_text`, Day 2 in `cfg.mem.*_text`).

## Design

- Pool: 165 concepts (`subcategory`) × 20 exemplars = 3,300 images, in 9 categories.
- Per participant:
  - **High interference (HI):** 15 concepts × 10 targets + 10 foils.
  - **Low interference (LI):** the other 150 concepts × 1 target + 1 foil.
  - Foils always come from the same concept as their targets.
- Balanced scheme (`create_stimuli_list_balanced.m`): the 165 concepts are split once into 11 fixed sets of 15. A participant's HI set is `mod(subj_id - 1, 11) + 1`. The sets are balanced on category mix (exact), AlexNet conv2/fc7 within-concept similarity, and luminance/contrast. The 1% most similar fc7 concept pairs never share a set. Sets are built by simulated annealing with a fixed seed.
- Targets/foils follow a fixed rotation over 22 participants (one cycle): every image is a target once and a foil once per condition. Within a round (participants 1–11 or 12–22), the LI targets/foils of a concept are exactly its HI targets/foils (positions 1–10 vs 11–20, swapped in round 2), so both conditions use the same images and the same Day 2 test pairs. Lists for participants 1–22 are pre-generated in `Stimulus_lists/` and frozen; `create_stimuli_list_balanced` errors for `subj_id` > 22 (second cycle not set up yet).

## Running

The encoding session is started by `run_encoding.m` in the repo root. Set `subj_id` and `windowed` at the top, then run it. It adds `Functions/` to the path and runs these steps:

`get_cfg` → `create_participant` (creates `Participants/sub-XXX/`, which is git-ignored) → `ask_resume` → load the pre-made `Stimulus_lists/stimuli_sub-XXX.csv` (errors if missing; lists are never regenerated during a session) → `create_sequence` → `set_screen` (preloads textures) → `present_block` for every block in session order, with a break screen between blocks; after the middle block (block `N/2`) the break shows `cfg.enc.half_break_text` ("half of the experiment is done") instead.

- **Block / condition order:** every block holds one condition. Each condition has `cfg.repeat` blocks, and each block shows that condition's 150 targets once in a new random order. Conditions alternate in runs of `cfg.blocks_per_switch` blocks (must divide `cfg.repeat`), e.g. repeat 10, switch 2 → H H L L H H L L … (20 blocks); `blocks_per_switch = repeat` = all of one condition, then the other. Odd `subj_id` starts with high, even with low (`condition_order.m`). `seq.block` = block number in the session, `seq.repeat` = repetition within the condition.
- **Order within blocks:** every block (high and low) is fully shuffled; a block never starts with the image that ended the previous block. (A `'grouped'` option that showed a concept's exemplars back to back was removed: for RSA it confounds within-concept similarity with temporal proximity.)
- **Attention check (catch trials):** every encoding block gets `numel(cfg.catch.files) * cfg.catch.per_image` flower images (4 per block by default, same flowers and number in both conditions; settings in `cfg.catch` in `get_cfg.m`). Participants press **space** when they see a flower. `add_catch` in `create_sequence.m` spreads them over the block (one per equal segment): never first/last, never back to back. The ISI after a flower is fixed at `cfg.catch.isi` (1.5 s; other trials: `cfg.ISI_vals`, 1.0/1.1/1.2 s), so the space press is further from the next image. Each block starts with `cfg.block_start_fix` (1.5 s) of fixation after the break key press. Catch rows have `is_catch = 1`, `category = 'Catch'`, and `path` relative to `Stimuli/Catch/`. `present_block` logs key presses with PTB key queues on **all** keyboards (`kb_queue.m`; a queue without a device index listens to the default keyboard only, which lost every press in the pilot with separate experimenter and participant keyboards) (first space press per trial in `key_time`/`key_rt`; a press during image or ISI of trial t counts for t) and prints a hit/false-alarm summary per block. `score_catch.m` scores them (hit = press 0.15–2 s after catch onset, `cfg.catch.rt_window`; any other press = false alarm) and adds `catch_hit`, `catch_rt`, `false_alarm`; `run_encoding` runs it before writing the results CSV. For EEG, drop catch trials and trials with or right after a key press. The start/resume screen continues only on **space**, read through the same queues (`wait_space_queue.m`), so a keyboard the queues don't receive is noticed before the first block. The start screen and every break screen (after every block; "Block k of N done", counted over the session) show the instruction with the 4 flowers in a row directly underneath, text and flowers centred together (`show_text_with_catch.m`; size `cfg.catch.example_size_deg`, gap below the text `cfg.catch.example_gap_deg`; shrunk with a warning only if it doesn't fit the window).
- **Output** (in `Participants/sub-XXX/`): files are named `sub-XXX_encoding_<type>_<date>` with the date the session started (yyyy-MM-dd): `_sequence_<date>.csv` (planned), `_results_<date>.mat` (saved after every image, during the ISI) and `_results_<date>.csv` (rewritten after every block, i.e. at each break, at the end, and when the session stops with ESC or an error; scored with `score_catch`). Every row has `subj_id` and `session_date`; the .mat also holds `subj_id` and `session_date`. The measured image onset/offset is stored in `seq`. Pressing ESC (in a block or on any text screen, via `wait_for_keys`) raises the error `session:quit` (Day 1 and Day 2). `run_encoding` / `run_memory` catch it and keep everything shown so far.
- **Resume:** rerunning with the same `subj_id` asks resume/overwrite/quit `[r/o/q]` (in `ask_resume`, shared with Day 2). Resume keeps writing to the same files (original date); overwrite deletes that part's old files and starts new ones with today's date. Resume loads `seq` from `results.mat` and continues with the first image without a measured offset (mid-block, mid-concept), after the usual block-start fixation (`cfg.block_start_fix`, 1.5 s). It errors if the saved sequence doesn't match the one made now (e.g. `get_cfg` changed). The same applies to `run_memory.m`: trials with a choice are done, and the session continues with the next trial.
- **Progress print:** after every image `present_block` prints to the command window, e.g. `Condition 1 (high) | block 3/10 | trial 47/150`. Condition = 1st or 2nd condition of this participant, block = repetition within that condition (`seq.repeat`), trial counts targets only (1–150); catch trials print `catch (flower)` instead.
- **Resume screen:** when resuming, Day 1 shows `cfg.enc.resume_text` (with the flowers) instead of the start screen; Day 2 shows `cfg.mem.resume_text` before the instructions.
- **Fixation point:** shown before and between images (ISI), never on top of an image (Day 1 and Day 2).
- **Refresh rate:** `cfg.refresh_hz` in `get_cfg.m` (default 120; 60 works too, all durations are whole frames at both). In fullscreen, `set_screen` switches the display to that rate before opening the window (`display_mode.m`, via `Screen('Resolution')`), and `run_encoding` / `run_memory` switch it back after `sca` (also after ESC or an error). The session stops if the measured rate still differs; windowed tests only warn and switch nothing. `set_screen` also warns if a duration is not a whole number of frames. `cfg.refresh_hz = []` leaves the display alone.
- **Background:** `cfg.bg_rgb` in `get_cfg.m`, 0–255 integers (default 128 gray, so no rounding); `set_screen` converts it to the 0–1 range.
- **Test mode:** if `cfg.max_images_per_block` in `get_cfg.m` is not `[]`, every block is cut to that many images. Set it back to `[]` for real sessions.

## Day 2 memory test (`run_memory.m`)

Set `subj_id` and `windowed` at the top, then run it. Steps: `get_cfg` → participant folder (from Day 1) → `ask_resume` → load `Stimulus_lists/stimuli_sub-XXX.csv` → `create_memory_sequence` → `set_screen` → `run_memory_block` per condition, with a break between conditions.

- **Task:** exemplar-level 2AFC. One trial per target–foil pair (same concept, same `pair` number). Fixation `cfg.mem.iti` → image 1 (`cfg.mem.img_dur`, 500 ms) → fixation (`cfg.mem.isi`, 1000 ms) → image 2 (500 ms) → choice screen "first or second?" (keys `cfg.mem.choice_keys`, no time limit). No confidence rating.
- **Order:** conditions in separate blocks, starting with the same condition as Day 1 (`condition_order.m`, shared with `create_sequence`). Random trial order within a block; the target is first in exactly half of each block's trials. Seed `subj_id + 2`.
- **Breaks:** only one, between the two conditions (self-paced). No breaks within a block.
- **Output** (in `Participants/sub-XXX/`): `sub-XXX_memory_sequence_<date>.csv` (planned trials), `sub-XXX_memory_results_<date>.mat` (saved after every trial), `sub-XXX_memory_results_<date>.csv` (every `cfg.mem.csv_every` = 10 trials, after each block and at the end). Every row has `subj_id` and `session_date`. Columns include `choice`, `correct`, `choice_rt` (from choice-screen onset) and the measured image onsets.
- **Progress print:** after every trial the command window shows e.g. `Memory | condition 1 (high) | trial 47/150 | correct` (condition = 1st or 2nd condition of this participant).
- **Test mode:** `cfg.max_images_per_block` also caps the memory blocks.

## EEG triggers (Day 1 and Day 2)

ViewPixx pixel mode: the colour of the top-left pixel goes to the BioSemi as a trigger on **every** frame.
- **Every flip goes through `flip_trig(win, cfg, code, when)`** (never `Screen('Flip')` directly in Day 1 code). It draws the trigger pixel (`draw_trigger`; code 0 = black) and, for code > 0, flips the same picture again one frame later with 0, so the lines always go 0 → code → 0 and a code lasts one frame. It returns the onset of the code frame.
- Encoding: `trigger_rgb.m` (ViewPixx pixel mode, BioSemi cable shift: pins 2–9 → bits 1–8; taken from the earlier experiment's `ViewPixxTrigger.m`, which is no longer in the repo); `draw_trigger` divides by 255.
- **Codes only in `get_cfg.m` (`cfg.triggers`)**. `get_cfg` calls `write_trigger_codes`, which checks them (1–255, unique) and rewrites `trigger_codes.txt` (the reference for the analysis). `cfg.triggers.enabled = false` keeps the pixel black.
- Bit scheme: 128 image onset, 64 block start, 16 fixation onset, 1 = high / 2 = low (block start, fixation); 8–12 = experiment start / end / block end / resume, Day 2 choice screen. Image codes are the same on both days: target = 128 + category number (129–137), foil = 160 + category number (161–169), flower = 160. Category numbers = order of `cfg.triggers.category_names` (`image_trigger.m`). Image codes carry no condition or Day 2 position (those follow from block start and trial order).
- Where: `set_screen` zeroes the pixel on the first flip; `run_encoding` calls `ask_eeg_started` before opening the screen, sends `experiment_start` (or `experiment_resume`) with the start/resume screen and `experiment_end` with the end screen; `present_block` sends `block_start` (block-start fixation, `cfg.block_start_fix`), `image_trigger` code / `catch_image` (onset), `fixation` (offset) and `block_end`. Space presses and break screens send nothing (press times are in `key_time`).
- Day 2: `run_memory` asks `ask_eeg_started`, sends `experiment_start` with the instructions (`experiment_resume` with the resume screen) and `experiment_end`; `run_memory_block` sends `block_start` (first ITI), `fixation` (ITI and between the images), image onsets (`image_trigger`, target or foil + category), `mem_choice_screen` and `block_end`. Key presses send nothing.
- **Expected codes in the sequence:** `add_triggers_encoding` (Day 1: `trig_image`, `trig_fix`) and `add_triggers_memory` (Day 2: `trig_iti`, `trig_image1`, `trig_isi`, `trig_image2`, `trig_choice`) add the codes per trial right after the sequence is made (and again on resume). They are in the sequence and results CSVs, and the presentation code sends exactly these columns. Block start (Day 1) and block end are per block and not in the table; on Day 2 the first trial after a resume sends `block_start` instead of its `trig_iti`.
- Record in fullscreen (`windowed = false`); `run_encoding` and `run_memory` warn in windowed mode.
- **Trigger log (backup):** `flip_trig` adds every code > 0 to `trigger_log.m` with the onset time of the frame that carried it (PTB flip time), plus block and trial (`seq.trial` / `mseq.trial`; NaN for block/session events). Written to `sub-XXX_<encoding|memory>_triggers_<date>.csv` (`subj_id, session_date, part, code, name, flip_time, block, trial, missed`; `missed` = 1 if PTB reports the frame came later than requested, i.e. a dropped frame; names from `trigger_list.m`, the same as in `trigger_codes.txt`) during the ISI after every image/trial, at block end, at the end and when a session stops; appended on resume. Kept in memory between those points, so logging never delays a flip. It is the complete list of codes that should be in the EEG (incl. block and experiment events). To use it, map it onto the BioSemi Status channel with offset **and** clock drift (`EEG = a + b·log`, fitted on the correct triggers; Day 1 pilot: drift −26.5 ppm ≈ 144 ms over 90 min, residual SD 0.4 ms at 1024 Hz), never with a constant offset.

Concept sets are created once, before data collection:

```matlab
create_concept_sets()   % -> Stimulus_lists/concept_sets.csv (+ concept_sets_balance.csv)
```

- `create_concept_sets` refuses to overwrite an existing `concept_sets.csv`, because the sets must stay fixed once testing starts. `create_stimuli_list_balanced(subj_id)` fails if the file is missing. It writes `Stimulus_lists/stimuli_sub-XXX.csv`.
- The list-making code is **not** in `Functions/` (that folder is for the session code only):
  - `Stimulus_lists/create_concept_sets.m` – builds the 11 sets (run once).
  - `Stimulus_lists/functions/create_stimuli_list_balanced.m` – one participant's list.
  - `Stimulus_lists/functions/create_22_stim_lists.m` – script that makes the lists for participants 1–22.
  Paths inside these files are derived from their own location (`Stimulus_lists/` → experiment root), so keep them where they are or update the path lines.
- Each list has a `pair` column: the target and foil with the same `pair` within a concept are tested against each other in the Day 2 2AFC (HI: rotation position i with i+10, pairs 1–10; LI: pair 1 = rotation position k with k+10, where k = 1–10 is the participant's slot among the 10 LI participants of the round). Pairs are the same in both rounds of the cycle, with target and foil swapped.

The notebooks in `Stimuli/Selection20_resized/` must be run with that folder as the working directory. They use relative paths to `stimuli_list.csv`.
- `luminance_contrast_check.ipynb` writes `image_luminance_contrast.csv`: grayscale mean luminance and RMS contrast per image.
- `alexnet_similarity_check.ipynb` uses torchvision AlexNet. Images are resized to 224 without cropping. It writes the CSV tables to `alexnet_tables/` (tracked): `concept_similarity.csv` (conv2/fc7 within-concept z), `concept_distance_fc7.csv` (165×165), the design simulation and others. The RDM cache (`alexnet_rdms.npz`, ~120 MB) and figures go to `alexnet_outputs/`, which is git-ignored.
- The MATLAB set-building reads those CSVs. If the pool changes, rerun both notebooks before rebuilding the sets.

## Stimulus data conventions

- `stimuli_list.csv` is the master pool: `image_id, category, subcategory, exemplar, filename, path, source`. `path` is relative to `Stimuli/Selection20_resized/`.
- Category folder names match the `category` column exactly (e.g. `Furniture_Home_decor/`): no `:` and no count suffixes. Keep it that way, since `path` depends on it.
- `Exclude/` holds removed concepts and is not in `stimuli_list.csv`.
- `Stimuli/Catch/` holds the 4 attention-check flower images (THINGS `flower` 01, 14, 16, 19, resized to 400×400; log with luminance/contrast in `catch_sources.csv`). They are not in `stimuli_list.csv`, are Day 1 only and never part of the analyses. Used for the Day 1 attention check (see Running).
- `image_sources.csv` logs the resize/crop of each image to 400×400 and the image source (e.g. THINGS).
