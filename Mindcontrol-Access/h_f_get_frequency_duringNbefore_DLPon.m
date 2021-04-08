
close all;



%% define the variables
angle_data_selected=cell(cyclenum,1);
answer = inputdlg({'limit for minimal period','and the maxmium interval','the anterior portion to be calculated'}, '', 1,...
    {'0.4','','30'});
minimalperiod=str2double(answer{1});
anterior_portion=str2double(answer{3});
maxperiod=str2double(answer{2});
t_w=cell(cyclenum,4);
t_w_angle_smt=cell(cyclenum,2);
t_w_angledatazerooffset1=cell(cyclenum,1);
t_w_peaks=cell(cyclenum,1);
if ~exist('t_w_illu_time','var')
    t_w_illu_time = this_worm_illumination_time;
end
if ~exist('t_w_curvdatafiltered','var') && exist('this_worm_curvdatafiltered','var')
    t_w_curvdatafiltered = this_worm_curvdatafiltered;
end  
%% select frame of start and end point to be analysed
for sequence_extracting_index=1:cyclenum
    
    shortafterflag=0;
    if t_w_illu_time(sequence_extracting_index,1)-frames_beforeDLPon>0
        t1=t_w_illu_time(sequence_extracting_index,1)-frames_beforeDLPon;
    else
        t1=t_w_illu_time(sequence_extracting_index,1)-50;
    end
    if t_w_illu_time(sequence_extracting_index,2)+300<=numframes_total
        t2=t_w_illu_time(sequence_extracting_index,2)+300;
    else
        t2=t_w_illu_time(sequence_extracting_index,2);
        shortafterflag=1;
    end
    t1b=t1-t1+1;
    t2b=t_w_illu_time(sequence_extracting_index,1)-1-t1+1;
    t1d=t_w_illu_time(sequence_extracting_index,1)-t1+1;
    t2d=t_w_illu_time(sequence_extracting_index,2)-t1+1;
    t1a=t_w_illu_time(sequence_extracting_index,2)+1-t1+1;
    t2a=t2-t1+1;
    
    t_start_auto=t1d;
    t_end_auto=t2d;

    fps=(t_end_auto-t_start_auto)/(time_auto{sequence_extracting_index,1}(t_end_auto,1)-time_auto{sequence_extracting_index,1}(t_start_auto,1));

    c2 = t_w_curvdatafiltered{sequence_extracting_index,1}(t_start_auto:t_end_auto,:) > 0;
   
    maskhead = 0.1;
    masktail = 0.1;
    minimum_fraction_for_fit = 0.8;

    c3 = edge(single(c2),'sobel', 0);

    c3(:,round((1-masktail)*numcurvpts):end) = 0;
    c3(:,1:round(maskhead*numcurvpts)) = 0;

    [c4,numlab] = bwlabel(c3);

    numcycles2 = 0;

    clear slopedata timedata slopedatatmp timedatatmp okdatatmp curvsigndatatmp curvsigndata;

    okdatatmp = zeros(numlab, 1);

    normrthresh = 220;
    
    for n=1:numlab
        c5 = (c4 == n);
        [y, x] = find(c5);

        yshift = 3;
        yshifted = ceil(1+0.5*(1+sign(y-yshift)) .* (y-yshift-1))+t_start_auto;
        curvshift = zeros(size(x));

        for jj=1:length(x)
            curvshift(jj) = t_w_curdata{sequence_extracting_index,1}(yshifted(jj), x(jj));
        end

        tmp = x;
        x=x(logical((tmp>=maskhead * numcurvpts) .* (tmp<=(1-masktail) * numcurvpts)));
        y=y(logical((tmp>=maskhead * numcurvpts) .* (tmp<=(1-masktail) * numcurvpts)));

        if max(x) - min(x) >=  (1-maskhead-masktail)*minimum_fraction_for_fit*numcurvpts

            [p,S] = polyfit(x,y,1);


            if S.normr < normrthresh
                %if mean(curvshift) > 0
                %    plotcol = '-g';
                %else
                %    plotcol = '--g';
                %end
                %plot(polyval(p,[1:numcurvpts]), plotcol); hold on;        
                numcycles2 = numcycles2 + 1;
                slopedatatmp(n) = p(1);
                timedatatmp(n) = p(2);
                okdatatmp(n) = 1;
                negshift = (mean(curvshift) > 0);
                curvsigndatatmp(n) = negshift;
                xpos = 5;
                ypos = p(2)-1;
                if p(2)<1
                    xpos = numcurvpts/4;
                    ypos = 5;
                end
                    %text(xpos,ypos,num2str([numcycles2 p(1)]), 'Color', 'white'); hold on;
            end
        end

    end

    numcycles2 = 0;
    c4b = c4;
    for n=1:numlab
        if okdatatmp(n)
            numcycles2 = numcycles2+1;
            slopedata(numcycles2) = slopedatatmp(n);
            timedata(numcycles2) = timedatatmp(n);
            curvsigndata(numcycles2)=curvsigndatatmp(n);
            c4b(c4b==n) = numcycles2;
        else
            c4b(c4b==n) = 0;
        end
    end

    %% calculate the cycles of wave propagated

    %here wavevelocity represents the the time needs for a complete phase for a
    %whole body length
    
     angle_data_selected{1,1} = unwrap(unwrap(t_w_angledata{sequence_extracting_index,1}(t1b:t2b,:)),[],2); 
     angle_data_selected{2,1} = unwrap(unwrap(t_w_angledata{sequence_extracting_index,1}(t1d:t2d,:)),[],2);
     angle_data_selected{3,1} = unwrap(unwrap(t_w_angledata{sequence_extracting_index,1}(t1d:t2d,:)),[],2);
     angle_data_zerooffset=cell(3,1);
     angle_data_zerooffset1=cell(3,1);
     period_s=zeros(3,1);
     frequency=zeros(3,1);
     wavevelocity=zeros(3,1);
     wavelength=zeros(3,1);
     %angle_smth=cell(3);
     %angle_smthp20=cell(3,1);
     %if ~shortafterflag
         illustatus=3;
     %else
     %    illustatus=2;
     %end
     for i=1:illustatus % i == 1, before DLPon; i == 2, during DLPon; i == 3, 
         angle_data_avg1 = mean(angle_data_selected{i,1}(:,:),2);
         angle_data_zerooffset{i,1} = angle_data_selected{i,1} - repmat(angle_data_avg1, [1 size(angle_data_selected{i,1},2)]);
         angle_data_zerooffset{i,1} = unwrap(unwrap(angle_data_zerooffset{i,1},[],2));
         angle_data_zerooffset1{i,1} = angle_data_zerooffset{i,1}-mean(angle_data_zerooffset{i,1}(:));
       
         % calculat period three different illlumination state by segment 20 of body
        if i==3
           angle_smthp20{i}=smooth(smooth(angle_data_zerooffset1{i,1}(:,80),10,'sgolay'),5);
        else
           angle_smthp20{i}=smooth(smooth(angle_data_zerooffset1{i,1}(:,anterior_portion),10,'sgolay'),5);
           %angle_smthp20{i}=smooth(smooth(smooth(smooth(angle_data_zerooffset1{i,1}(:,anterior_portion),15,'sgolay'),15),15),15);
           %results before 170328 ran using four times smoothing
        end

        
         %angle_smth data has 3-by-3 dimention, column means illu stats: before, during, after; row means bodysegment
         %15,50,85.
        
         for j=1:3
            angle_smth{i,j}=smooth(smooth(angle_data_zerooffset1{i,1}(:,15+35*(j-1)),10,'sgolay'),5);
         end
         
         
         [worm_pks,worm_pklcs]=findpeaks(angle_smthp20{i});
         [worm_pksI,worm_pklcsI]=findpeaks(-angle_smthp20{i});
         pklcs=[worm_pks,worm_pklcs];
         pklcsI=[worm_pksI,worm_pklcsI];
         numpks=length(worm_pklcs);
         numpksI=length(worm_pklcsI);
         pks_k=0;
         for pks_j=2:numpks
             
             if pklcs(pks_j-pks_k,2)-pklcs(pks_j-pks_k-1,2)<minimalperiod*fps % get rid of fulse peaks
                 pklcs(pks_j-pks_k,:)=[];
                 pks_k=pks_k+1;
             end
         end
         pksI_k=0;
         for pksI_j=2:numpksI
             if pklcsI(pksI_j-pksI_k,2)-pklcsI(pksI_j-pksI_k-1,2)<minimalperiod*fps % get rid of fulse peaks
                 pklcsI(pksI_j-pksI_k,:)=0;
                 pksI_k=pksI_k+1;
             end
         end
         % stop counitng at reversal dirction
         %{
         offflag=0;
         if size(pklcs,1)>1
            for j=2:length(pklcs)
                for k=1:size(pklcsI,1)
                    if -pklcsI((pklcs(j-1,1)<pklcsI(k,1)<pklcs(j,1)),1)>0
                        offflag=1;
                        break
                    end
                end
                if offflag==1
                    break
                end
            end
         else
             j=1;
         end
         %}
         % number of rounds suubstrates the wrong points
         if pks_j>1
             rounds_by_frame=(pklcs(pks_j-pks_k,2)-pklcs(1,2))/(pks_j-pks_k-1);
         else
             rounds_by_frame=0;
         end
         period_s(i) = rounds_by_frame/fps;
         frequency(i)=1/period_s(i);
         %wavevelocity(i)= mean(1./slopedata)/numcurvpts*fps;
         wavelength(i) = wavevelocity(i) * period_s(i);
         t_w_peak{i,1}=pklcs;
         t_w_peak{i,2}=pklcsI;
         t_w_peak{i,3}=rounds_by_frame;
         t_w_peak{i,4}=pks_j-pks_k;
         %if i == 1
         %angle_data_output = if_bias_Before_DLPon(angle_data_zerooffset1)
         %end
     end
     t_w{sequence_extracting_index,1}=period_s;
     t_w{sequence_extracting_index,2}=wavevelocity;
     t_w{sequence_extracting_index,3}=wavelength;
     t_w{sequence_extracting_index,4}=frequency;
     t_w_angle_smt{sequence_extracting_index,1}=angle_smthp20;
     t_w_angle_smt{sequence_extracting_index,2}=angle_smth;
     t_w_angledatazerooffset1{sequence_extracting_index,1}=angle_data_zerooffset1;
     t_w_peaks{sequence_extracting_index,1}=t_w_peak;
     
     clear angle_data_zerooffset curvshift t_w_peak;
     

   
    %if sequence_extracting>100
     %   t_w_meanperiod_DLPoff{sequence_extracting_index,1}=period_s;
      %  t_w_meanperiod_DLPoff{sequence_extracting_index,2}=wavevelocity;
       % t_w_meanperiod_DLPoff{sequence_extracting_index,3}=wavelength;
        %t_w_meanperiod_DLPoff{sequence_extracting_index,4}=sqrt(sin2_theta);

   % end
end
t_w_mat=zeros(size(t_w,1),6);
% meanings of t_w_mat are: period of head Before, head During, tail During;
% frequency of head Before, head During, tail During
for i=1:size(t_w,1)
    for j=1:3
        t_w_mat(i,j)=t_w{i,1}(j,1);
        t_w_mat(i,j+3)=t_w{i,4}(j,1);
    end
end



close all