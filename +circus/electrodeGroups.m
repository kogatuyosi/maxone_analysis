function [ electrode_groups, channel_groups ] = electrodeGroups( mapping, radius )
% ELECTRODEGROUPS       groups the active electrodes a recording into local area clusters
% 
%     Groups = mxw.util.electrodegroups( mapping , radius )
% 
%     Groups  : cell array with the electrodes from the same clustering group
%     mapping : structure, as read from an h5 file
%     radius  : radius
% 
%     The clustering algorithm starts with the top left electrode, and adds
%     all electrodes within 'radius' micro meter to the same group/cluster of
%     electrodes.
% 

all_used_channels = [];
electrode_groups = {};
channel_groups = {};

valid_idx = mapping.x>=0;

while sum(valid_idx)>0
    % find upper left corner
    x = mapping.x(valid_idx);
    y = mapping.y(valid_idx);
    ch = mapping.channel(valid_idx);
    electrode = mapping.electrode(valid_idx);
    channel = mapping.channel(valid_idx);

    [~,b] = sort( sqrt( x.^2 + y.^2 ) );

    topPoint_x = x(b(1));
    topPoint_y = y(b(1));

    [d,b] = sort( sqrt( (topPoint_x-x).^2 + (topPoint_y-y).^2 ) );

    rng = d<radius;
    idx = b(rng);

    %groups{end+1} = double(ch(idx));
    electrode_groups{end+1} = double(electrode(idx));
    channel_groups{end+1} = double(channel(idx));

    all_used_channels = [all_used_channels ; ch(idx)];

    for m_idx = 1:length(mapping.channel)
        if any( all_used_channels==mapping.channel(m_idx) )
            valid_idx(m_idx) = 0;
        end
    end
end
