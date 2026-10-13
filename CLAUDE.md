# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Stimulus preparation and Psychtoolbox presentation code for an EEG memory-interference experiment (Day 1 encoding; foils are reserved for a Day 2 test). There is no build, lint or test tooling. Code is MATLAB plus Python Jupyter notebooks for stimulus checks. Text shown to participants is in German.

## Design

- Pool: 165 concepts (`subcategory`) × 20 exemplars = 3,300 images, in 9 categories.
- Per participant:
  - **High interference (HI):** 15 concepts × 10 targets + 10 foils.
  - **Low interference (LI):** the other 150 concepts × 1 target + 1 foil.
  - Foils always come from the same concept as their targets.
- Balanced scheme (`create_stimuli_list_balanced.m`): the 165 concepts are split once into 11 fixed sets of 15. A participant's HI set is `mod(subj_id - 1, 11) + 1`. The sets are balanced on category mix (exact), AlexNet conv2/fc7 within-concept similarity, and luminance/contrast. The 1% most similar fc7 concept pairs never share a set. Sets are built by simulated annealing with a fixed seed.
- `subj_id` is the RNG seed for exemplar selection, so any participant's list can be regenerated exactly.

## Running

The encoding session is started by `run_encoding.m` in the repo root. Set `subj_id` and `windowed` at the top, then run it. It adds `Functions/` to the path and runs these steps:

`get_cfg` → `create_participant` (creates `Participants/sub-XXX/`, which is git-ignored) → `create_stimuli_list_balanced` → `create_sequence` → `set_screen` (preloads textures) → `run_encoding_high` / `run_encoding_low` (each calls `present_block` per block).

- **Condition order:** the two conditions run separately, one after the other. Odd `subj_id` runs high first, even runs low first. Each condition has `cfg.repeat` blocks, and each block shows that condition's 150 targets once in a new random order.
- **Output:** `results.mat` is saved after every block, and the measured image onset/offset is stored in `seq`. Pressing ESC raises the error `encoding:quit`. `run_encoding` catches it and keeps the completed blocks.
- **Test mode:** if `cfg.max_images_per_block` in `get_cfg.m` is not `[]`, every block is cut to that many images. Set it back to `[]` for real sessions.
- **Unused config:** `cfg.path_to_table` / `cfg.stimuli_subfolder` in `get_cfg.m` are leftovers from the old experiment and nothing reads them. Triggers are not set up yet.

Concept sets are created once, before data collection:

```matlab
create_concept_sets()   % -> Stimulus_lists/concept_sets.csv (+ concept_sets_balance.csv)
```

- `create_concept_sets` refuses to overwrite an existing `concept_sets.csv`, because the sets must stay fixed once testing starts. `create_stimuli_list_balanced(subj_id)` fails if the file is missing. It writes `Stimulus_lists/stimuli_sub-XXX.csv`.

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
