# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Stimulus preparation and Psychtoolbox presentation code for an EEG memory-interference experiment (Day 1 encoding; foils are reserved for a Day 2 test). There is no build, lint or test tooling. Code is MATLAB plus Python Jupyter notebooks for stimulus checks. Text shown to participants is in English for now (all participant-facing text for Day 2 is in `cfg.mem.*_text` in `get_cfg.m`).

## Design

- Pool: 165 concepts (`subcategory`) × 20 exemplars = 3,300 images, in 9 categories.
- Per participant:
  - **High interference (HI):** 15 concepts × 10 targets + 10 foils.
  - **Low interference (LI):** the other 150 concepts × 1 target + 1 foil.
  - Foils always come from the same concept as their targets.
- Balanced scheme (`create_stimuli_list_balanced.m`): the 165 concepts are split once into 11 fixed sets of 15. A participant's HI set is `mod(subj_id - 1, 11) + 1`. The sets are balanced on category mix (exact), AlexNet conv2/fc7 within-concept similarity, and luminance/contrast. The 1% most similar fc7 concept pairs never share a set. Sets are built by simulated annealing with a fixed seed.
- Targets/foils follow a fixed rotation over 22 participants (one cycle): every image is a target once and a foil once per condition. Lists for participants 1–22 are pre-generated in `Stimulus_lists/` and frozen; `create_stimuli_list_balanced` errors for `subj_id` > 22 (second cycle not set up yet).

## Running

The encoding session is started by `run_encoding.m` in the repo root. Set `subj_id` and `windowed` at the top, then run it. It adds `Functions/` to the path and runs these steps:

`get_cfg` → `create_participant` (creates `Participants/sub-XXX/`, which is git-ignored) → load the pre-made `Stimulus_lists/stimuli_sub-XXX.csv` (errors if missing; lists are never regenerated during a session) → `create_sequence` → `set_screen` (preloads textures) → `run_encoding_high` / `run_encoding_low` (each calls `present_block` per block).

- **Condition order:** the two conditions run separately, one after the other. Odd `subj_id` runs high first, even runs low first. Each condition has `cfg.repeat` blocks, and each block shows that condition's 150 targets once in a new random order.
- **High-block order:** `cfg.high_order` in `get_cfg.m`. `'random'` (default) fully shuffles each high-interference block; `'grouped'` shows each concept's 10 exemplars back to back, with concept order and exemplar order reshuffled every repetition (a block never starts with the concept that ended the previous one). Low blocks are always fully shuffled.
- **Output:** `results.mat` is saved after every block, and the measured image onset/offset is stored in `seq`. Pressing ESC raises the error `encoding:quit`. `run_encoding` catches it and keeps the completed blocks.
- **Test mode:** if `cfg.max_images_per_block` in `get_cfg.m` is not `[]`, every block is cut to that many images. Set it back to `[]` for real sessions.
- **Unused config:** `cfg.path_to_table` / `cfg.stimuli_subfolder` in `get_cfg.m` are leftovers from the old experiment and nothing reads them. Triggers are not set up yet.

## Day 2 memory test (`run_memory.m`)

Set `subj_id` and `windowed` at the top, then run it. Steps: `get_cfg` → participant folder (from Day 1; asks before overwriting `memory_results.mat`) → load `Stimulus_lists/stimuli_sub-XXX.csv` → `create_memory_sequence` → `set_screen` → `run_memory_block` per condition, with a break between conditions.

- **Task:** exemplar-level 2AFC. One trial per target–foil pair (same concept, same `pair` number). Fixation `cfg.mem.iti` → image 1 (`cfg.mem.img_dur`, 500 ms) → fixation (`cfg.mem.isi`, 1000 ms) → image 2 (500 ms) → choice screen "first or second?" (keys `cfg.mem.choice_keys`, no time limit) → confidence 1–4 (`cfg.mem.conf_keys`, no time limit).
- **Order:** conditions in separate blocks, in the same order as Day 1 (`condition_order.m`, shared with `create_sequence`). Random trial order within a block; the target is first in exactly half of each block's trials. Seed `subj_id + 2`.
- **Breaks:** only one, between the two conditions (self-paced). No breaks within a block.
- **Output** (in `Participants/sub-XXX/`): `memory_sequence.csv` (planned trials), `memory_results.mat` (saved after every trial), `memory_results.csv` (at the end). Columns include `choice`, `correct`, `choice_rt` (from choice-screen onset), `confidence`, `conf_rt` and the measured image onsets.
- **Test mode:** `cfg.max_images_per_block` also caps the memory blocks.

## Triggers (not active yet)

- `draw_trigger(win, cfg, code)` is called before every `Screen('Flip')` in the memory test, so each code is time-locked to the frame it belongs to. With `cfg.triggers.enabled = false` it draws a black top-left pixel. The ViewPixx RGB encoding still has to be ported from `Functions_Old_Experiment/ViewPixxTrigger.m`; colours are 0–1 here, so divide its 0–255 values by 255.
- Memory codes are in `cfg.triggers.mem`: image 1 onset 111/112 (high target/foil), 121/122 (low); image 2 onset 113/114, 123/124; choice screen 130; choice first/second 131/132 (with the confidence-screen flip); confidence 141–144 (with the next fixation flip).
- The encoding code (`present_block`) does not call `draw_trigger` yet. Add it before each flip there too; otherwise the trigger pixel shows the gray background, which the ViewPixx would read as a code.

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
- Each list has a `pair` column: the target and foil with the same `pair` within a concept are tested against each other in the Day 2 2AFC (HI: rotation position i with i+10, pairs 1–10; LI: pair 1). Pairs are the same in both rounds of the cycle, with target and foil swapped.

The notebooks in `Stimuli/Selection20_resized/` must be run with that folder as the working directory. They use relative paths to `stimuli_list.csv`.
- `luminance_contrast_check.ipynb` writes `image_luminance_contrast.csv`: grayscale mean luminance and RMS contrast per image.
- `alexnet_similarity_check.ipynb` uses torchvision AlexNet. Images are resized to 224 without cropping. It writes the CSV tables to `alexnet_tables/` (tracked): `concept_similarity.csv` (conv2/fc7 within-concept z), `concept_distance_fc7.csv` (165×165), the design simulation and others. The RDM cache (`alexnet_rdms.npz`, ~120 MB) and figures go to `alexnet_outputs/`, which is git-ignored.
- The MATLAB set-building reads those CSVs. If the pool changes, rerun both notebooks before rebuilding the sets.

## Stimulus data conventions

- `stimuli_list.csv` is the master pool: `image_id, category, subcategory, exemplar, filename, path, source`. `path` is relative to `Stimuli/Selection20_resized/`.
- Category folder names match the `category` column exactly (e.g. `Furniture_Home_decor/`): no `:` and no count suffixes. Keep it that way, since `path` depends on it.
- `Exclude/` holds removed concepts and is not in `stimuli_list.csv`.
- `image_sources.csv` logs the resize/crop of each image to 400×400 and the image source (e.g. THINGS).

## `Functions_Old_Experiment/`

This is the presentation code from a previous experiment, a scene-typicality task with an attention check and ViewPixx EEG triggers. It's kept for reference, e.g. `ViewPixxTrigger.m` for when triggers are added.
- `get_cfg` → `create_participant` → `set_screen` → `init_experiment_new` (`select_stimuli_new` + `create_sequence_new`) → trial loop (`one_image`, `get_response_timed`, `show_break`).
- Its config paths (`stim_list.csv`, `stimuli_all`, `Participants/`) and trigger codes are for the old design and don't match the current stimuli.
