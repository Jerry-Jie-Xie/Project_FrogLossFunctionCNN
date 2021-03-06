% Extract raw noisy data and split it into training and testing data
close all; clear; clc;
%======================%
aug_method = 'no';
feature_type = 'all';
%======================%
fs = 44100;
%======================%
snrValue_array = [-20:5:-5];
nSnr = length(snrValue_array);
for iSnr = 1:nSnr
    select_snr = snrValue_array(iSnr);
    
    noise_type = {'white_noise', 'pink_noise', 'rain_noise', 'wind_noise'};
    
    nNoise = length(noise_type);
    for iNoise = 1:nNoise
        select_noise_type = noise_type{iNoise};
     
        win_size_array = [0.2] * fs;
        % win_over_array = [0.2, 0.5, 0.8];
        win_over_array = [0.8];
        nSize = length(win_size_array);
        nOver = length(win_over_array);
        for iSize = 1:nSize
            win_size = win_size_array(iSize);
            
            for iOver = 1:nOver
                win_over = win_over_array(iOver);
                
                % win_size = 1024;
                % win_over = 0.5;
                %======================%
                audio_folder = ['.\Australia-Frog\data_split_noise\'];
                
                % percent_array = 0.5:0.1:0.9;
                percent_array = 0.8;
                nPerc = length(percent_array);
                for iPerc = 1:nPerc
                    
                    temp_percent = percent_array(iPerc);
                    training_data_folder = [audio_folder, 'training_', num2str(temp_percent), '\', num2str(select_snr), '\noise_data_',  select_noise_type];
                    training_audio_list = dir(training_data_folder);
                    training_audio_list = training_audio_list(arrayfun(@(x) ~strcmp(x.name(1), '.'), training_audio_list));
                    
                    testing_data_folder = [audio_folder, 'testing_', num2str(temp_percent), '\', num2str(select_snr), '\noise_data_',  select_noise_type];
                    testing_audio_list = dir(testing_data_folder);
                    testing_audio_list = testing_audio_list(arrayfun(@(x) ~strcmp(x.name(1), '.'), testing_audio_list));
                    
                    %=======================%
                    label_folder = '.\Australia-Frog\label\';
                    label_list = dir(label_folder);
                    label_list = label_list(arrayfun(@(x) ~strcmp(x.name(1), '.'), label_list));
                    
                    nTrainingList = length(training_audio_list);
                    
                    training_audio_cell = cell(1, nTrainingList);
                    testing_audio_cell = cell(1, nTrainingList);
                    for iTrainingList = 1:nTrainingList
                        
                        disp([num2str(select_snr), '_', select_noise_type, '_', num2str(iTrainingList)])
                        
                        tra_species_path = [training_data_folder, '\',  training_audio_list(iTrainingList).name];
                        [training_audio_signal, sr] = audioread(tra_species_path);
                        
                        % labeling
                        temp_label = csvread(['.\Australia-Frog\training_len_folder\training_len_', num2str(temp_percent), '_noise.csv']);
                        start_label = temp_label(iTrainingList);
                        
                        % read label
                        label_path = ['.\Australia-Frog\label\',  label_list(iTrainingList).name];
                        label_data = xlsread(label_path);
                        % remove NAN
                        nan_index = ~isnan(label_data);
                        label_data = label_data(nan_index(:,1),:);
                        label_data = sortrows(label_data,2);
                        
                        % find the closest value
                        label_array = sort(label_data(:));
                        [minValue,closestIndex] = min(abs(start_label-label_array));
                        if label_array(closestIndex) > start_label
                            
                            start_index = closestIndex - 1;
                            stop_index = closestIndex;
                            
                            start_value = label_array(start_index);
                            stop_value = label_array(stop_index);
                            
                            start_loc = label_data == start_value;
                            start_sum_loc = sum(start_loc);
                            stop_loc = label_data == stop_value;
                            stop_sum_loc = sum(stop_loc);
                            
                            if start_sum_loc(2) == 1 && stop_sum_loc(1) ==1
                                
                                training_label_data = label_data(1: ceil(start_index/2), :);
                                testing_label_data = label_data((ceil(start_index/2)+1):end, :) - start_label + 1;
                                
                            else
                                % create new
                                new_label_array = [label_array(1:closestIndex-1); start_label; start_label;label_array(closestIndex:end)];
                                new_label_data = reshape(new_label_array,  2, length(new_label_array)/2)';
                                
                                training_label_data = new_label_data(1: ceil(start_index/2), :);
                                testing_label_data = new_label_data((ceil(start_index/2)+1):end, :) - start_label + 1;
                                
                            end
                            
                        else
                            start_index = closestIndex;
                            stop_index = closestIndex+1;
                            
                            start_value = label_array(start_index);
                            stop_value = label_array(stop_index);
                            
                            start_loc = label_data == start_value;
                            start_sum_loc = sum(start_loc);
                            stop_loc = label_data == stop_value;
                            stop_sum_loc = sum(stop_loc);
                            
                            if start_sum_loc(2) == 1 && stop_sum_loc(1) ==1
                                
                                training_label_data = label_data(1: ceil(start_index/2), :);
                                testing_label_data = label_data((ceil(start_index/2)+1):end, :) - start_label +1;
                                
                            else
                                % create new
                                if closestIndex+3 > length(label_array)
                                    new_label_array = [label_array(1:closestIndex); start_label; start_label; label_array(end)];
                                else
                                    new_label_array = [label_array(1:closestIndex); start_label; start_label; label_array(closestIndex+3:end)];
                                end
                                new_label_data = reshape(new_label_array,  2, length(new_label_array)/2)';
                                
                                training_label_data = new_label_data(1: ceil(start_index/2), :);
                                testing_label_data = new_label_data((ceil(start_index/2)+1):end, :) - start_label + 1;
                                
                            end                            
                        end
                        
                        %=================================================================%
                        % labeling
                        training_label_info = ones(length(training_audio_signal), 1);
                        [nRow, ~] = size(training_label_data);                       
                        for iRow = 1:nRow
                            start = training_label_data(iRow, 1);
                            stop = min(training_label_data(iRow, 2), length(training_label_info));
                            
                            training_label_info(start: stop) = 2;
                            
                        end
                        
                        training_label_info = training_label_info - 1;
   
                        % generate label for each sliding window
                        training_label_mat = window_move(training_label_info,  win_size, win_over);
                        [~, nCol] = size(training_label_mat);
                        training_final_label_weak = zeros(1, nCol);
                        training_final_label_mid = zeros(1, nCol);
                        training_final_label_strong = zeros(1, nCol);
                        
                        for iCol = 1:nCol
                            
                            temp_label = training_label_mat(:, iCol);
                            if sum(temp_label) / win_size == 1
                                training_final_label_strong(iCol) = iTrainingList;
                            end
                            if sum(temp_label) / win_size >= 0.75
                                training_final_label_mid(iCol) = iTrainingList;
                            end
                            if sum(temp_label) / win_size >= 0.5
                                training_final_label_weak(iCol) = iTrainingList;
                            end
                            
                        end
                        
                        % windowing
                        training_audio_feature = window_move(training_audio_signal, win_size, win_over);

                        % combine feature and label
                        %training_temp_data = [training_audio_feature', training_final_label_weak', training_final_label_mid', training_final_label_strong'];
                        training_temp_data = [training_audio_feature', training_final_label_weak'];

                        %=================================================================%
                        % testing data
                        tes_species_path = [testing_data_folder, '\',  testing_audio_list(iTrainingList).name];
                        [testing_audio_signal, ~] = audioread(tes_species_path);
                        
                        % labeling
                        testing_label_info = ones(length(testing_audio_signal), 1);
                        [nRow, ~] = size(testing_label_data);
                        
                        for iRow = 1:nRow
                            start = max(testing_label_data(iRow, 1), 1);
                            stop = testing_label_data(iRow, 2);
                            
                            testing_label_info(start: stop) = 2;
                            
                        end
                        
                        testing_label_info = testing_label_info - 1;
                        
                        % generate label for each sliding window
                        testing_label_mat = window_move(testing_label_info,  win_size, win_over);

                        [~, nCol] = size(testing_label_mat);
                        testing_final_label_weak = zeros(1, nCol);
                        testing_final_label_mid = zeros(1, nCol);
                        testing_final_label_strong = zeros(1, nCol);
                        
                        for iCol = 1:nCol
                            temp_label = testing_label_mat(:, iCol);
                            
                            % percentage
                            if sum(temp_label) / win_size == 1
                                testing_final_label_strong(iCol) = iTrainingList;
                            end
                            
                            if sum(temp_label) / win_size >= 0.75
                                testing_final_label_mid(iCol) = iTrainingList;
                            end
                            
                            if sum(temp_label) / win_size >= 0.5
                                testing_final_label_weak(iCol) = iTrainingList;
                            end
                        end
                        
                        % windowing
                        [testing_audio_feature, loc] = window_move(testing_audio_signal, win_size, win_over);
                       
                        % combine feature and label
                        %testing_temp_data = [testing_audio_feature', testing_final_label_weak', testing_final_label_mid', testing_final_label_strong'];
                        testing_temp_data = [testing_audio_feature', testing_final_label_weak'];
                        
                        %=================================================================%
                        % save training feature
                        training_audio_cell{iTrainingList} = training_temp_data;
                        
                        % save testing feature
                        testing_audio_cell{iTrainingList} = testing_temp_data;
                        
                    end
                    
                    % save data
                    audio_mat = cell2mat(training_audio_cell');
                    save_final_folder = ['.\Australia-Frog\raw_data_sliding_noise\', num2str(select_snr), '\noise_data_',  select_noise_type, '\result_all_percent_', num2str(temp_percent), '_winsize_', num2str(win_size), '_winover_',  num2str(win_over)];
                    create_folder(save_final_folder);
                    save_final_path = [save_final_folder, '\training_raw_data_sliding_window.csv'];
                    csvwrite(save_final_path, audio_mat);
                    
                    audio_mat = cell2mat(testing_audio_cell');
                    save_final_path = [save_final_folder, '\testing_raw_data_sliding_window.csv'];
                    csvwrite(save_final_path, audio_mat);
                    
                end
            end
        end
    end
end
%[EOF]

