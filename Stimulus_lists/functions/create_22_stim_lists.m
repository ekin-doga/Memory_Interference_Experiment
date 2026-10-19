%% Create the first 22 stimuli lists

% category mix
% within-concept similarity (conv2, fc7)
% luminance and contrast
% across-concept similarity (fc7) -> avoid e.g., ambulance/firetruck

addpath(fileparts(mfilename('fullpath')));   % so create_stimuli_list_balanced is found from anywhere

for s = 1:22
    create_stimuli_list_balanced(s);
end