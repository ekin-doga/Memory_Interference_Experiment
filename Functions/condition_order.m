function order = condition_order(subj_id)
% CONDITION_ORDER - Order of the two conditions for one participant
%
% Used by both create_sequence (Day 1 encoding) and create_memory_sequence
% (Day 2 test), so the two days always follow the same order:
%   odd  subj_id: {'high', 'low'}
%   even subj_id: {'low', 'high'}

if mod(subj_id, 2) == 1
    order = {'high', 'low'};
else
    order = {'low', 'high'};
end
end
