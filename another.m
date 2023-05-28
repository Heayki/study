function another
%SPEECH_PROCESSING_GUI - MATLAB designed GUI for speech processing function.

% Create the GUI figure and set its properties
    fig = uifigure('Name','Speech Processing','Position',[100 100 520 400]);
    fig.NumberTitle = 'off';
    fig.Color = [0.8 0.8 0.8];

% Create heading label
    headingLabel = uilabel(fig,'Text','Speech Processing','Position',[190 360 140 25]);
    headingLabel.FontSize = 14;
    headingLabel.FontWeight = 'bold';

    % Create instructions label
    infoLabel = uilabel(fig,'Text','Please choose an audio file and select a processing method: ','Position',[30 310 400 25]);

    % Create an audio file selector
    audioBtn = uibutton(fig,'push','Text','Choose Audio File','Position',[30 270 120 30],'ButtonPushedFcn',@(audioBtn,event)fileSelector());

    % Create processing method labels
    uicontrol('Style','text','String','Select processing method:','Position',[30 220 180 25],'BackgroundColor',[0.8 0.8 0.8]);
    % Create a dropdown list for processing methods
    dropdown = uidropdown(fig,'Items',{'Change Speed without Change Pitch','Change Pitch without Change Speed','Remove Noise from Audio File'}, 'Position',[30 180 250 25],'Value','Change Speed without Change Pitch','ValueChangedFcn', @(dropdown)processSelect(dropdown));

    % Create a button group for radio buttons
    btnGroup = uibuttongroup('Parent', fig, 'Position', [0, 0, 1, 1], 'Visible','off');
    
    speedChangerBtn = uiradiobutton(btnGroup, 'Text', 'Change Speed without Change Pitch', 'Position', [30 200 250 25]);
    pitchShifterBtn = uiradiobutton(btnGroup, 'Text', 'Change Pitch without Change Speed', 'Position', [30 180 250 25]);
    noiseRemoverBtn = uiradiobutton(btnGroup, 'Text', 'Remove Noise from Audio File', 'Position', [30 160 250 25]);
    
    % Set button group to visible
    btnGroup.Visible = 'on';
    
    pitchShifterBtn = uibutton(fig, 'push','Text','Pitch Shift', 'Position',[150 110 100 30],'Enable','off', 'ButtonPushedFcn', @(pitchShifterBtn,event)pitchShift(fig.UserData.filepath,fig.UserData.currentMethod));
    % Create a processing button
    processBtn = uibutton(fig,'push','Text','Process Audio','Position',[30 110 100 30],'Enable','off','ButtonPushedFcn', @(processBtn,event)processAudio());

    % Create an instructions label
    resultLabel = uilabel(fig,'Text','','Position',[280 50 200 25],'HorizontalAlignment','left','VerticalAlignment','top');

    % File Selector function
    function fileSelector()
        [filename, pathname] = uigetfile('*.wav','Choose an audio file');
        if isequal(filename,0)
            disp('No file selected.')
        else
            filepath = [pathname,filename];
            disp(filepath); % display the filepath for debugging
            set(audioBtn,'Text',filename)
            set(processBtn,'Enable','on')
            % save filepath into the UserData property
            fig.UserData.filepath = filepath;
        end
    end
function processSelect(dropdown)
    % get the handle to the figure
    fig = gcf;
    % get the dropdown value
    currentMethod = dropdown.Value;
    % update figure user data
    fig.UserData.currentMethod = currentMethod;
    % update pitch shift button's callback function
    pitchShifterBtn = findobj(fig,'Tag','pitchShifterBtn');
    pitchShifterBtn.ButtonPushedFcn = @(~, ~)pitchShift(fig.UserData.filepath,fig.UserData.currentMethod);
end
% Process Audio function
function processAudio()
    if speedChangerBtn.Value == 1
        % change speed, keep pitch
        changeSpeed(fig.UserData.filepath);
        resultLabel.Text = 'Audio File Successfully Processed for Changing Speed!';
    elseif pitchShifterBtn.Value == 1
        % change pitch, keep speed
        changePitch(fig.UserData.filepath)
        resultLabel.Text = 'Audio File Successfully Processed for Changing Pitch!';
    elseif noiseRemoverBtn.Value == 1
        % reduce noise
        noiseRemover(fig.UserData.filepath)
        resultLabel.Text = 'Audio File Successfully Processed for Noise Reduction!';
    end
end

% Speed Changer function
function changeSpeed(filepath)
    fs = 44100;
    % read the audio file
    [y,Fs] = audioread(filepath);
    % get change speed ratio
    ratio = inputdlg('Enter ratio of speed change (e.g 2 for speed up, 0.5 for slow down):','Speed Ratio',1,{'1'});
    ratio = str2double(ratio{1});
    % check if ratio is greater than 1 (speed up) or less than 1 (slow down)
    if ratio > 1
        % change sample rate and play the new audio file for speed up
        y2 = resample(y, 1, ceil(ratio));
        sound(y2,Fs*(1/ceil(ratio)));
        % save the new audio file
        [filepathnew, filename, ext] = fileparts(filepath);
        newFilename = fullfile(filepathnew, ['speedChange_', num2str(ratio), 'x', '_', filename, ext]);
        audiowrite(newFilename,y2,Fs*(1/ceil(ratio)));
    elseif ratio < 1
        % change sample rate and play the new audio file for slow down
        y2 = resample(y, 1, floor(1/ratio));
        sound(y2,Fs/ratio);
        % save the new audio file
        [filepathnew, filename, ext] = fileparts(filepath);
        newFilename = fullfile(filepathnew, ['speedChange_', num2str(ratio), 'x', '_', filename, ext]);
        audiowrite(newFilename,y2,Fs/ratio);
    else
        % if ratio is 1, play the original audio file
        sound(y,Fs);
    end
    % plot the waveform of the original and modified audio
    t = linspace(0,(length(y)-1)/fs,length(y));
    t2 = linspace(0,(length(y2)-1)/(fs*ratio),length(y2));
    subplot(2,1,1)
    plot(t,y)
    title('Original Audio')
    xlabel('Time (s)')
    ylabel('Amplitude')
    subplot(2,1,2)
    plot(t2,y2)
    title('Modified Audio')
    xlabel('Time (s)')
    ylabel('Amplitude')
end

% Pitch Shifter function
function changePitch(filepath)
    % read the audio file
    [y,Fs] = audioread(filepath);
    % get steps of pitch change
    steps = inputdlg('Enter number of steps for pitch shift (e.g 3):','Pitch Steps',1,{'0'});
    steps = str2num(steps{1});
    % change pitch and play the new audio file
    y2 = pitchshift(y,Fs,steps,2048);
    sound(y2,Fs);
    % save the new audio file
    newFilename = ['pitchChange_', num2str(steps), '_', filepath];
    audiowrite(newFilename,y2,Fs);
end
    % Noise Remover function
function noiseRemover(filepath)
    % read the audio file
    [y,Fs] = audioread(filepath);
    % apply spectral subtraction and play the new audio file
    y2 = ssr_demo(filepath);
    sound(y2,Fs);
    % save the new audio file
    newFilename = ['noiseReduction_', filepath];
    audiowrite(newFilename,y2,Fs);
end

% Spectral Subtraction function
function [clean_signal] = ssr_demo(filepath)
    % read the audio file
    [y,Fs] = audioread(filepath);
    % calculate the STFT of the signal
    window = hamming(256,'periodic');
    hop = 128;
    Y = spectrogram(y,window,hop,256);
    % calculate the power spectrum and noise threshold
    power_spect = abs(Y).^2;
    noise_threshold = median(power_spect,2);
    % calculate the noise reduction factor
    noise_reduction_factor = 4;
    % apply spectral subtraction
    power_spect = power_spect - noise_reduction_factor * noise_threshold;
    power_spect(power_spect<0) = 0;
    % reconstruct clean signal from modified power spectrum
    clean_signal = istft(power_spect,window,hop,256,Fs);
end

end

