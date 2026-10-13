function dir_name = create_participant(name, crash_restart, exp_version)

sub_folder = strcat('sub_',num2str(name));

dir_name = strcat("Participants/",sub_folder);

if ~exist((dir_name), 'dir')

    disp(strcat('Creating new participant directory:', dir_name'))
    mkdir(dir_name)

else
    disp(strcat('Participant directory:', dir_name))

    % Skip overwrite prompt if crash restart or practice mode
    if crash_restart == 0 && strcmp(exp_version, 'experiment')

        answer = 0;

        while answer == 0
            r = input('Participant exists. Overwrite [y/n]? ', 's');

            if strcmpi(r, 'y')
                disp('Logfiles will be overwritten.')
                answer = 1;

            elseif strcmpi(r, 'n')
                error(['Participant exists and you chose not to overwrite. ' ...
                   'Change the name for the new participant and start again. ' ...
                   'If the experiment crashed or terminated change crash_restart to 1.']);
            else
                disp('Invalid input. Please enter y or n.')
            end
        end

    end
end
end