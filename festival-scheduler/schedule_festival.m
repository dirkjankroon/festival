function schedule_festival(filename_in,filename_html_out )
% This function reads a schedule of shows from a text file, assigns each show to a 
% track so that no two shows on the same track overlap in time, and 
% outputs the schedule both to the console and to an HTML file.
%
% The HTML file supports both Mobile and FullSize view
% 
% Inputs:
%   filename_in - The input text file containing show names and times (default input.txt).
%   filename_html_out - The output HTML file to save the scheduled results 
%			(default schedule.html).
%
% Outputs:
%   The function does not return variables but prints to the console and
%   creates an HTML file with the schedule.
%
% Example input file format:
%   show_1 29 33
%   show_2 2 9
%   show_3 44 47
%   show_4 26 3010:48 2-9-2024
%   show_5 15 20
%
% Written By D.Kroon 02-09-2024 at Demcon

% Set default values for input and output filenames if not provided
if(nargin<1)
    filename_in = 'input.txt';
end
if(nargin<2)
    filename_html_out = 'schedule.html';
end

% Read show data from the input file
data_shows = read_input_data(filename_in);

% Schedule the shows into tracks
[data_shows_scheduled,track_num] = schedule_data_show(data_shows);

% Print the scheduled shows to the console
print_to_console(data_shows_scheduled,track_num);

% Create an HTML schedule from the scheduled show
create_html_schedule(data_shows_scheduled,track_num, filename_html_out);

% Open the generated HTML file
system(filename_html_out)
end

function data_shows = read_input_data(filename)
    % Open the file and read data
    file_id = fopen(filename, 'r');
    data_raw = textscan(file_id, '%s %d %d');
    fclose(file_id);
    
    % Extract each column into a variable
    show_title = data_raw{1}; % cell array of strings
    start_time = data_raw{2};    % first column of integers
    end_time = data_raw{3};    % second column of integers
    
    % Restructure data to have the data of one show in one item
    data_shows = repmat(struct('title','','start_time',int32(0),'end_time',int32(0)),size(show_title,1),1);
    for i_show=1:size(show_title,1)
        data_shows(i_show).title = show_title{i_show};
        data_shows(i_show).start_time = start_time(i_show);
        data_shows(i_show).end_time = end_time(i_show);
    end
end

function [data_shows_scheduled,track_num] = schedule_data_show(data_shows)
    % Sort shows by start time, first item earliest start time
    [~,index_tracks_possible] = sort([data_shows.start_time]);
    data_shows = data_shows(index_tracks_possible);
    
    % Now add shows to a track if the current end-time of the track is before the
    % start time of the show.
    % If starting before the end time of all current tracks, start a new track.
    data_shows_scheduled = repmat(struct('title','','start_time',int32(0),'end_time',int32(0),'track',int32(0)),size(data_shows,1),1);
    track_num = 0;
    track_end_time =zeros(size(data_shows,1),1,'int32');
    for i_show=1:size(data_shows,1)
        item_show = data_shows(i_show);
        index_tracks_possible = find(track_end_time(1:track_num) < item_show.start_time);
        % If no available track, add a new track
        if(isempty(index_tracks_possible))
            track_num = track_num +1;
            track_selected = track_num;
        else
            [~,ind]=sort(track_end_time(index_tracks_possible));
            % Select track with latest end time relative to the start time of this new show
            % This does not influence the number of tracks needed, but
            % it is nice if the shows continues with minimum inbetween waiting
            % time between two shows for the public
            track_selected = index_tracks_possible(ind(end));
        end
        % Update the track end time and assign the show to the track
        track_end_time(track_selected) =item_show.end_time;
        data_shows_scheduled(i_show).title = item_show.title;
        data_shows_scheduled(i_show).start_time = item_show.start_time;
        data_shows_scheduled(i_show).end_time = item_show.end_time;
        data_shows_scheduled(i_show).track = track_selected;
    end
end

function print_to_console(data_shows_scheduled,track_num)
     % Print the schedule for each track
    for i_track=1:track_num
        fprintf('\ntrack %d\n', i_track)
        track_shows = data_shows_scheduled([data_shows_scheduled.track]==i_track);
        for j=1:size(track_shows,1)
            fprintf('- title %s, time from %d t/m %d\n', track_shows(j).title,track_shows(j).start_time,track_shows(j).end_time);
        end
    end
end

function create_html_schedule(data_shows_scheduled,track_num, filename_out)
    % Load HTML template
    lines = readlines("html/template.html");
    % Generate color mapping for tracks
    colorm = uint8(winter(track_num)*128);
    lines_track =repmat("",track_num*4,1);
    lines_track_index = 0;

    % Create CSS for each track
    for i_track=1:track_num
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) = sprintf(".track-%d {",i_track);
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index)  = sprintf("  background-color: rgb(%d, %d, %d);",colorm(i_track,1),colorm(i_track,2),colorm(i_track,3));
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) = "  color: #fff;";
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index)  = "}";
    end
    % Insert CSS styles into the HTML template
    ts = find(lines=='%trackstyle%');
    lines = [lines(1:ts-1,:);lines_track;lines(ts+1:end,:)];
    lines_track =repmat("",track_num,1);
    lines_track_index = 0;
    for i_track=1:track_num
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) = sprintf("  <span class=""track-slot"" aria-hidden=""true"" style=""grid-column: track-%d; grid-row: tracks;"">Track %d</span>",i_track,i_track);
    end

    % Create track header slots
    ts = find(lines=='%track_slot_header%');
    lines = [lines(1:ts-1,:);lines_track;lines(ts+1:end,:)];

    % Define the grid rows based on time slots
    tstart = min([data_shows_scheduled.start_time]);
    tend = max([data_shows_scheduled.end_time]);
    lines_track =repmat("",tend-tstart+2,1);
    lines_track_index = 0;
    for i_time=tstart:tend
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) =sprintf("      [time-%d] 1fr",i_time);
    end
    lines_track_index = lines_track_index +1;
    lines_track(lines_track_index) =sprintf("      [time-%d] 1fr;",tend+1);
    ts = find(lines=='%template_rows%');
    lines = [lines(1:ts-1,:);lines_track;lines(ts+1:end,:)];

    % Define the grid columns based on track layout
    lines_track =repmat("",track_num+2,1);
    lines_track_index = 0;
    lines_track_index = lines_track_index +1;
    lines_track(lines_track_index) =sprintf("      [times] %dem",track_num);
    lines_track_index = lines_track_index +1;
    lines_track(lines_track_index) ="      [track-1-start] 1fr";
    for i_track=1:track_num-1
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) =sprintf("      [track-%d-end track-%d-start] 1fr",i_track,i_track+1);
    end
    lines_track_index = lines_track_index +1;
    lines_track(lines_track_index) =sprintf("      [track-%d-end];",track_num);
    ts = find(lines=='%template_columns%');
    lines = [lines(1:ts-1,:);lines_track;lines(ts+1:end,:)];

    % Insert the schedule sessions into the HTML
    tlast = tstart-1;
    lines_track =repmat("",size(data_shows_scheduled,1)*5+ tend-tstart+2,1);
    lines_track_index = 0;
    for i=1:size(data_shows_scheduled,1)
        item_show = data_shows_scheduled(i);
        if(item_show.start_time > tlast)
            for i_time = tlast+1:item_show.start_time
                lines_track_index = lines_track_index +1;
                lines_track(lines_track_index) = sprintf("<h2 class=""time-slot"" style=""grid-row: time-%d;"">%d:00</h2>",i_time,i_time);
            end
            tlast = item_show.start_time;
        end
        % Add the scheduled show details to the HTML
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) =sprintf("  <div class=""session session-%d track-%d"" style=""grid-column: track-%d; grid-row: time-%d / time-%d;"">", i, item_show.track,item_show.track,item_show.start_time,item_show.end_time+1);
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) =sprintf("    <h3 class=""session-title""><a href=""#"">%s</a></h3>",item_show.title);
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) =sprintf("    <span class=""session-time"">%d:00 - %d:59</span>",item_show.start_time,item_show.end_time);
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) =sprintf("    <span class=""session-track"">Track: %d</span>",item_show.track);
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) =sprintf("  </div>");
    end

    % Add remaining time slots after the last scheduled show
    for i_time = tlast+1:tend+1
        lines_track_index = lines_track_index +1;
        lines_track(lines_track_index) = sprintf("<h2 class=""time-slot"" style=""grid-row: time-%d;"">%d:00</h2>",i_time,i_time);
    end
    % Insert the session details into the HTML template
    ts = find(lines=='%sessions%');
    lines = [lines(1:ts-1,:);lines_track;lines(ts+1:end,:)];

    % Write the final HTML content to the output file
    writelines(lines,filename_out);
end