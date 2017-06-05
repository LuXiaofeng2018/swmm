% The MATLAB script was created to auto-calibrate SWMM.

% The first step is to install Python2.7 and swmmtoolbox to windows-based 
% computer (Python can be downloaded from the website:
% https://pypi.python.org/pypi?%3Aaction=search&term=swmm&submit=search.)

% To excecute this procedure, there are five necessary components: 
% (1) study site topography information, (2) in-situ observations, (3) initial
% parameter ranges derived from peer-reviewed literature, (4) Python code 
% to extract simulation data from SWMM "*.out" file (can be download from
% website https://pypi.python.org/pypi?%3Aaction=search&term=swmm&submit=search), 
% and (5) SWMM command line tools for use in parallel computing applications. 

% In this script, MATLAB was used as a tool to bring all these information 
% together. Users need to write MATLAB code to generate SWMM "*.inp" files
% with different parameter values, then forces SWMM to execute with "*.inp"
% files and generate "*.out" and "*.rpt" files.  Then user-specified MATLAB
% code forces Python to extract simulation results (e.g., inflow discharges
% in this script) from "*.out" files and compares with in-situ observations.

% The script was only used for academic research. 

% Author: Jing Wang
% Email: jwang1@umd.edu


clear; clc; 
date_tick_type = 'dd-mmm-yyyy HH:MM';

%% Directories and filenames
fprintf('\n%s\n','**LOAD TEMPLATE INPUT FILES**');
[FileName, PathName, FILTERINDEX] = uigetfile('/../paper_code/*.inp', 'LOAD TEMPLATE INPUT FILES');

fprintf('\n%s\n',['    filename = ' FileName]);
FileName = [PathName FileName];

%% User-defined variables
num_replicates = 2; % the number of ensemble

%% Step#1: Generate parameter values
% user define the parameters need to be calibrated
% use string in the template input file
name_of_old_expression = {'BOBO','COCO'};
num_of_old_expression = length(name_of_old_expression);
new_name_of_parameters = {'Curve_Number','Depth_of_depression_storage_on_impervous_area[mm]'};

% define the range of each parameter
para_boundary = NaN * ones(num_of_old_expression,2);

for n = 1:1:num_of_old_expression
    
    if strcmpi(name_of_old_expression(1,n),'BOBO')== 1;
        para_boundary(n,1) = 30;
        para_boundary(n,2) = 70;
        
    elseif strcmpi(name_of_old_expression(1,n),'COCO')== 1;
        para_boundary(n,1) = 0.01;
        para_boundary(n,2) = 20;
        
    end
end

% Generate sets of uncorrelated, uniform perturbations
rand_perturbations = rand(num_replicates,num_of_old_expression); % uniform distribution on [0 1]

% Scale parameters' values to fit within desired range
para_var_samples = NaN * ones(num_replicates,num_of_old_expression);

for n = 1:1:num_of_old_expression
    
    para_var_samples(:,n) = para_boundary(n,1) + (para_boundary(n,2)...
        - para_boundary(n,1)) * rand_perturbations(:,n);
    
end


%% create files to store input report output and text files
% create the swmm process folders
name_of_folder = cell(num_replicates,1); % the name of the folders
for n = 1:1:num_replicates
    
    name_of_folder{n} = ['run_',num2str(n,'%04.0f')];

    % Create input output and report folders
    mkdir([PathName,'input\',name_of_folder{n}]);
    mkdir([PathName,'output\',name_of_folder{n}]);
    mkdir([PathName,'report\',name_of_folder{n}]);
    mkdir([PathName,'text_inflow\',name_of_folder{n}]);

end


        
%% Loop through the template input and create new input files
% Open input template filename
root_input_file = [PathName,'input\'];
forcing_location_in_template = 'location_of_forcing_files';
path_forcing = [PathName,'template_ppt'];

for n = 1:1:num_replicates
    
    % Open input template filename
        cd(PathName);
        fid_TEMPLATE = fopen('template.inp');
        
        % Create output filenames of interest
        input_filename = [root_input_file,'run_',num2str(n,'%04.0f'),'\template.inp'];
        
        fid_out = fopen(input_filename,'w');
        
        % Search through "template" *.inp file
        line_counter = 0; % reset INPUT line counter 
        
        while feof(fid_TEMPLATE) == 0
            line_counter = line_counter + 1;
            tline = fgetl(fid_TEMPLATE);
            
            for ii = 1:1:num_of_old_expression
                eval_string = ['old_expression_',num2str(ii),...
                    ' = name_of_old_expression{ii};'];
                eval(eval_string)
                eval_string = ['new_expression_',num2str(ii),...
                    '= num2str(para_var_samples(n,ii));'];
                eval(eval_string)
            end 
            
            if strfind(tline,old_expression_1)
                
                % Locate exact position within the string
                startIndex_1 = regexp(tline,old_expression_1);
                stopIndex_1 = startIndex_1 + length(old_expression_1);
                tline_1step1of2 = [tline(1:startIndex_1-1),new_expression_1,...
                    ' ',tline(stopIndex_1:end)];
                
                % Copy newly-modified line into new *.inp file of interest
                fprintf(fid_out,'%s\n',tline_1step1of2);
                
                
            elseif strfind(tline,old_expression_2)
                
                % Locate exact position within the string
                startIndex_2 = regexp(tline,old_expression_2);
                stopIndex_2 = startIndex_2 + length(old_expression_2);
                tline_1step1of2 = [tline(1:startIndex_2-1),new_expression_2,...
                    ' ',tline(stopIndex_2:end)];
                
                % Copy newly-modified line into new *.inp file of interest
                fprintf(fid_out,'%s\n',tline_1step1of2);
            
            elseif strfind(tline,forcing_location_in_template) % location of forcing
                
                % Locate exact position within the string
                startIndex_forcing = regexp(tline,forcing_location_in_template);
                stopIndex_forcing = startIndex_forcing + length(forcing_location_in_template);
                tline_1step1of1 = [tline(1:startIndex_forcing-1),path_forcing,...
                    ' ',tline(stopIndex_forcing:end)];
                
                % Copy newly-modified line into new *.inp file of interest
                fprintf(fid_out,'%s\n',tline_1step1of1);
                
            else
                fprintf(fid_out,'%s\n',tline); % use existing line
            end
            
        end

        % Close file(s) of interest
        status = fclose(fid_TEMPLATE); %#ok<*NASGU> % close template file
        status = fclose(fid_out); % close newly created *.inp file

end
        
        
%% Step 2: Process Input Files in SWMM via SWMM
% Process the input files(Note: EPA SWMM 5.1 exe. has to be in the same
% folder with all code) and Process the output binary files and save 
% into txt files (here take inflow to inlet as an example).
parfor n = 1:num_replicates %the number of input files
    input_path = ['input\run_',num2str(n,'%04.0f')];
    output_path = ['output\run_',num2str(n,'%04.0f')]; 
    report_path = ['report\run_',num2str(n,'%04.0f')];

    testString = ['swmm5 ',input_path,'\template.inp ',report_path,....
        '\template.rpt ',output_path,'\template.out'];
    [status,cmdout] = system(testString);
end



%% Step 3: Process the output binary files and save into mat files 
parfor n = 1:num_replicates %the number of input files

    root_dir_txt = [PathName,'text_inflow\',name_of_folder{n},'\'];
    root_dir_out = [PathName,'output\',name_of_folder{n},'\'];
    cd(root_dir_out)
   
    % extract data from *.out file with swmmtoolbox
    testString= ['swmmtoolbox extract template.out subcatchment,subcatchment,3'];
    [status,cmdout_inflow] =system(testString);
        
  %% save swmm outfiles string(cmdout) into txt file
  txt_name = ['template.txt'];
  fpath = [root_dir_txt txt_name];
  fid = fopen(fpath,'w');
  fprintf(fid, '%s\r\n',cmdout_inflow);
  fclose(fid);

end


%% Step4: Extract data from *.txt file and store into *.mat files
% take subcatchment runoff rate as an example
for n = 1:1:num_replicates %the number of input files

    root_dir_txt = [PathName,'text_inflow\',name_of_folder{n},'\'];
    cd(root_dir_txt);
    
    % extract data from txt file
    [date_string inflow] = textread('template.txt','%s %f','headerlines',1,'delimiter',',');
    
    % Save data vector into *mat file which is easier to compare with the oberved later
    eval_string = ['swmm_inflow.inflow(:,n) = inflow(1:end-1);'];
    eval(eval_string)
    
    date_num_swmm = datenum(cell2mat(date_string(1:end-1,:)));
    eval_string = ['swmm_inflow.time = date_num_swmm;'];
    eval(eval_string);

end

% save the *.mat files
cd(PathName);
save('swmm_inflow','swmm_inflow');

