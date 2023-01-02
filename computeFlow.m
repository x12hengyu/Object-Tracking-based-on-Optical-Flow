function result = computeFlow(img1, img2, search_radius, template_radius, grid_MN)
    % Check images have the same dimensions, and resize if necessary
    if find(size(img2) ~= size(img1))
        img2 = imresize(img2, size(img1));
    end
    % Get number of rows and cols for output grid
    M = grid_MN(1);
    N = grid_MN(2);

    [H, W] = size(img1);
    % locations where we estimate the flow
    grid_y = round(linspace(template_radius+1, H-template_radius, M));
    grid_x = round(linspace(template_radius+1, W-template_radius, N));
    
    % allocate matrices where we will store the computed optical flow
    U = zeros(M, N);    % horizontal motion
    V = zeros(M, N);    % vertical motion
    
    % compute flow for each grid patch
    for i = 1:M
        for j = 1:N
            %------------- PLEASE FILL IN THE NECESSARY CODE WITHIN THE FOR LOOP -----------------
            % Note: Wherever there are questions mark you should write
            % code and fill in the correct values there. You may need
            % to write more lines of code to obtain the correct values to 
            % input in the questions marks.
            
            % extract the current patch/window (template)
            col = grid_x(j);
            row = grid_y(i);

            row_min = max(1, row - template_radius);
            col_min = max(1, col - template_radius);
            row_max = min(H, row + template_radius);
            col_max = min(W, col + template_radius);
            
            template = img1(row_min:row_max,col_min:col_max);
            % where we'll look for the template

            row_min = max(1, row - search_radius);
            col_min = max(1, col - search_radius);
            row_max = min(H, row + search_radius);
            col_max = min(W, col + search_radius);
            search_area = img2(row_min:row_max,col_min:col_max);

            % compute correlation
            corr_map = normxcorr2(template, search_area);
            
            % Look at the correlation map and find the best match
            % The best match will have the Maximum Correlation value
            [~, max_ind] = max(corr_map(:));
            % Convert the index into row and col
            [max_ind_row, max_ind_col] = ind2sub(size(corr_map), max_ind);
            
            % express peak location as offset from template location
            U(i, j) = max_ind_col - (template_radius + search_radius);
            V(i, j) = max_ind_row - (template_radius + search_radius);
        end
    end
    
    % Any post-processing or denoising needed on the flow
    
    % plot the flow vectors
    fig = figure();
    imshow(img1);
    hold on; quiver(grid_x, grid_y, U, V, 2, 'y', 'LineWidth', 1.3);
    % From https://www.mathworks.com/matlabcentral/answers/96446-how-do-i-convert-a-figure-directly-into-an-image-matrix-in-matlab-7-6-r2008a
    frame = getframe(gcf);
    result = frame2im(frame);
    hold off;
    close(fig);
end