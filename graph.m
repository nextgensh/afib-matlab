%8718

function graph()
    data = csvread('eva_filter.csv');
    
    data = data(8718:length(data), :);
    
    x = data(:, 1);
    x = x - data(1,1);
    x = x / 1000;
    x = x / 60;
    x = x / 60;

    % Adjust the axis to reflect the time in hrs. The trace collection was
    % started at 4:10 pm (16hr in 24 format).
    x = x + 12.5;

    y = data(:, 2);
    accx = data(:, 4);
    accy = data(:, 5);
    accz = data(:, 6);

    mag = zeros(length(accx), 1);
    for a=1:length(accx)
        mag(a) = sqrt(accx(a)*accx(a) + accy(a)*accy(a) + accz(a)*accz(a));
    end

    % Extract only those value for which the watch has indicated the HR is
    % accurate.
    ay = zeros(length(data), 1);
    for a = 1:length(data)
        if data(a, 3) >= 1
            ay(a) = data(a, 2);
        end
    end

    figure(1);

    a1 = subplot('Position',[0.1 0.1 0.8 0.8]);
    a1.YTick = 0:10:180;
    a1.XTick = 10:1:45;
    a1.XLim = [10 45];
    %p = plot(x, ay);
    %hold on;
    [hax, l1, l2] = plotyy(x, y, x, mag);
    xlabel('Time (Hrs)');
    ylabel(hax(1), 'Beats per minute (bpm)');
    ylabel(hax(2), 'Acceleration Magnitude (m/s^2)');
    grid on;
    
    [retmag, retdata] = getRestTimes(data(:, 2), mag);
    figure(2);
    a2 = subplot('Position',[0.1 0.1 0.8 0.8]);
    [hax, l1, l2] = plotyy(x, retdata, x, retmag);
    xlabel('Time (Hrs)');
    ylabel(hax(1), 'Beats per minute (bpm)');
    ylabel(hax(2), 'Acceleration Magnitude (m/s^2)');
    grid on;
    
    [retmag, retdata, count, indexstore] = isolateIdle(data, retmag, 2);
    display(count);
    figure(3);
    a2 = subplot('Position',[0.1 0.1 0.8 0.8]);
    plot(x, retdata);
    xlabel('Time (Hrs)');
    ylabel('Beats per minute (bpm)');
    grid on;
    
    figure(4);
    rmssd = parseRMSSD(retdata, indexstore);
    plot(rmssd);
    xlabel('Instances');
    ylabel('RMSSD (msec)');
    grid on;
    
    figure(5);
    a2 = subplot('Position',[0.1 0.1 0.8 0.8]);
    boxplot(rmssd);
    a2.YTick = 0:10:70;
    a2.YLim = [0 70];
    grid on;
end

% Method which isolates periods of 2 mins or more of stationary time.
% The current threshold value used for this is a mag of 2 m/s^2 (Refer to
% my paper)
function [retmag, retdata] = getRestTimes(data, accmag)
    
    retmag = zeros(length(accmag), 1);
    retdata = zeros(length(accmag), 1);
    
    % Just populate the vector with values that are all stationary.
    for a=1:length(data)
        if(accmag(a) <= 2)
            retmag(a) = accmag(a);
            retdata(a) = data(a);
        end
    end
    
end

% Method which further isolates only regions which are contigous 
% stationary for the idle period.
% The index array holds pairs of index, the start and stop index of each
% stationary segment.
function [retmag, retdata, count, indexstore] = isolateIdle(data, accmag, threshold)
     retmag = zeros(length(data), 1);
     retdata = zeros(length(data), 1);
     
     starttime = data(1, 1);
     elapsedtime = 0;
     endindex = 0;
     
     count = 0;
     
     indexstore = [];
     
     for a=1:length(data)
        % Find the end of continum until first zero value.
        for b=a:length(data)
            if(accmag(b) > 0)
                elapsedtime = data(b, 1) - starttime;
                endindex = b;
            else
                starttime = data(b, 1);
                break;
            end
        end
        
        elapsedtime = (elapsedtime / 1000) / 60;
        if(elapsedtime >= threshold) 
            count = count + 1;
            indexstore(length(indexstore)+1) = a;    % Add the start and stop index.
            indexstore(length(indexstore)+1) = b;
            % We can keep this data as we have more than 2 mins of
            % stationary period
            for b=a:endindex
                retdata(b) = data(b, 2);
            end
        end
     end
end

% Method which calculates the RMSSD of the resulting values.
% This method accepts a section of the HR values.
function [rmssd] = getRMSSD(data)
    sum = 0;
    for a=1:length(data)-1
        
        v1 = data(a);
        v2 = data(a+1);
        if(v1 <= 0 || v2 <= 0)
            continue;
        end
        v1_temp = (1 / v1)*60*1000;
        v2_temp = (1 / v2)*60*1000;
        
        sum = sum + ((v1_temp - v2_temp)^2);
    end
 
    sum = sum / (length(data)-1);
    rmssd = sqrt(sum);
end


% Method which parses the array of hr values and then throws segment of it
% to the getRMSSD function.
function [rmssdv] = parseRMSSD(data, indexstore)
    rmssdv = [];
    
    for a=1:2:length(indexstore)-1
        rmssd = getRMSSD(data(indexstore(a):indexstore(a+1)-1));
        rmssdv(length(rmssdv)+1) = rmssd;
    end
end