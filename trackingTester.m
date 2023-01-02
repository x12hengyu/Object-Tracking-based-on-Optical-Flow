function trackingTester(data_params, tracking_params)
    % Useful function to get ROI from the img 
    function roi = get_ROI(img, rect)
        % just a convenience function
        xmin = rect(1);
        ymin = rect(2);
        width = rect(3);
        height = rect(4);
        roi = img(ymin:ymin+height-1, xmin:xmin+width-1,:);
    end
    
    % Verify that output directory exists
    if ~exist(data_params.out_dir, 'dir')
        fprintf(1, "Creating directory %s.\n", data_params.out_dir);
        mkdir(data_params.out_dir);
    end
    trackingbox_color = [255, 255, 0];
    % Load the first frame, draw a box on top of that frame, and save it.
    first_frame = imread(fullfile(data_params.data_dir, data_params.genFname(1)));
    annotated_first_frame = drawBox(first_frame, tracking_params.rect, trackingbox_color, 3);
    imwrite(annotated_first_frame, fullfile(data_params.out_dir, data_params.genFname(1)));
    
    % take the ROI from the first frame and keep its histogram to match
    % later
    obj_roi = get_ROI(first_frame, tracking_params.rect);
    
    
    %------------- FILL IN CODE -----------------
    % Create the intensity histogram using the obj_roi that was extracted
    % above.
    obj_hist = histcounts(obj_roi, tracking_params.bin_n);
    %------------- END FILL IN CODE -----------------

	% OPTIONAL: You can do the matching in color too.
	% Use the rgb2ind function to transform the image such that it only has a
    % fixed number of colors (much less than 256^3). If you visualize the mapped_obj 
    % image it should look similar to the obj_roi image, but with much less
    % variations in the color (the palette's size is tracking_params.bin_n).
    % The output colormap will tell you which colors were chosen to be used in 
    % the mapped_obj output image.
    % NOTE: If you want to do this, you have to do it consistently for all
    % frames!
    % [mapped_obj, colormap] = rgb2ind(obj_roi, tracking_params.bin_n);
    % Create a color histogram from the mapped_obj image that has the colors
    % quantized.
    % Hint: If the mapped_obj image has Q different colors, then your
    % histogram will have Q bins, one for each color.
    % obj_hist = ??
    
    % Normalize histogram such that its sum = 1
    obj_hist = double(obj_hist) / sum(obj_hist(:));

    % Tracking loop
    % -------------    
    % initial location of tracking box
    obj_col = tracking_params.rect(1);
    obj_row = tracking_params.rect(2);
    obj_width = tracking_params.rect(3);
    obj_height = tracking_params.rect(4);
    frame_ids = data_params.frame_ids;
    for frame_id = frame_ids(2:end)
        % Read current frame
        fprintf('On frame %d\n', frame_id);
        frame = imread(fullfile(data_params.data_dir, data_params.genFname(frame_id)));
        [H, W, ~] = size(frame);
        %------------- FILL IN CODE -----------------
        % extract the area over which we will search for the object
        % Hint:  This step is very similar to what you did in computeFlow
        % to extract the search_area.
        search_radius = tracking_params.search_radius;

        row_min = max(obj_row - search_radius, 1);	
        row_max = min(obj_row + obj_height + search_radius, W);	
        col_min = max(obj_col - search_radius, 1);	
        col_max = min(obj_col + obj_width + search_radius, H);

        search_window = frame(row_min:row_max, col_min:col_max, :);
        %------------- END FILL IN CODE -----------------
        % Change to grayscale
        gray_search_window = rgb2gray(search_window);
        % extract each object-sized sub-region from the searched area and
        % make it a column
        candidate_windows = im2col(gray_search_window, [obj_height obj_width], 'sliding');
        num_windows = size(candidate_windows, 2);
        % compute histograms for each candidate sub-region extracted from
        % the search window
        candidate_hists = double(zeros(tracking_params.bin_n, num_windows));
        for i = 1:num_windows
            %------------- FILL IN CODE -----------------
            % Hint: You already have done this at the beginning of this
            % function.
            candidate_hists(:,i) = histcounts(candidate_windows(:,i), tracking_params.bin_n);
            %------------- END FILL IN CODE -----------------

            % Normalize histogram such that its sum = 1
            candidate_hists(:,i) = candidate_hists(:,i) / sum(candidate_hists(:,i));
        end
        
        %------------- FILL IN CODE -----------------
        
        % find the best-matching region
        % Hint: You have all the candidate histograms, and you want to find
        % the one that is the most similar to the histogram you computed
        % from the first frame
        
        idx = 1;
        R = immse(obj_hist.', candidate_hists(:,idx));
        for i = 2:num_windows
            temp = immse(obj_hist.', candidate_hists(:,i));
            if temp < R
                R = temp;
                idx = i;  
            end
        end

        % UPDATE the obj_row and obj_col, which tell us the location of the
        % top-left pixel of the bounding box around the object we are
        % tracking.
        offset = search_radius * 2 + 1;
        obj_row = mod(idx, offset) + row_min + 1;
        obj_col = floor(idx / offset) + col_min;
        
        %------------- END FILL IN CODE -----------------

        % generate box annotation for the current frame
        annotated_frame = drawBox(frame, [obj_col obj_row obj_width obj_height], trackingbox_color, 3);
        % save annotated frame in the output directory
        imwrite(annotated_frame, fullfile(data_params.out_dir, data_params.genFname(frame_id)));
    end
end
