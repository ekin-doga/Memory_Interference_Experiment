function ask_eeg_started()
% ASK_EEG_STARTED - Experimenter confirms in the command window that the EEG
% recording is running, before the screen opens. Asked at every start,
% also when resuming (the recording may have been stopped).
%   y - recording is running, continue
%   n - reminder to start it, then asks again
%   q - quit (error 'encoding:quit'; nothing is shown, data so far is kept)
while true
    r = input('Has the EEG recording been started? [y/n/q] ', 's');
    if strcmpi(r, 'y')
        return;
    elseif strcmpi(r, 'n')
        disp('Please start the EEG recording first.');
    elseif strcmpi(r, 'q')
        error('encoding:quit', 'Stopped before the start: EEG recording not confirmed.');
    else
        disp('Invalid input. Please enter y, n or q.');
    end
end
end
