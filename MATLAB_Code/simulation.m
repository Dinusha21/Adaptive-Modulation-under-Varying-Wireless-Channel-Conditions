%%Communication Technologies

clear; clc; close all;

%% Parameters
Nbits     = 5e4;             % bits per frame
SNRdB     = 0:2:20;          % SNR range
targetBER = 1e-3;            % target BER
ricianK   = 5;               % Rician K-factor
mods      = {'BPSK','QPSK','16QAM'};
channels  = {'AWGN','Rayleigh','Rician'};

BER = struct(); SE = struct();

%% Monte-Carlo Simulation 
for ch = 1:length(channels)
    channelType = channels{ch};
    fprintf('Simulating %s channel...\n',channelType);

    for m = 1:length(mods)
        scheme = mods{m};
       
        if strcmp(scheme,'BPSK')
            bitsPerSym = 1;
        elseif strcmp(scheme,'QPSK')
            bitsPerSym = 2;
        else
            bitsPerSym = 4;
        end

        for s = 1:length(SNRdB)
            bits = randi([0 1],Nbits,1);

            %  Modulation 
            switch scheme
                case 'BPSK'
                    tx = 2*bits - 1;

                case 'QPSK'
                    bits2 = reshape(bits,[],2);
                    tx = (1/sqrt(2))*((2*bits2(:,1)-1) + 1j*(2*bits2(:,2)-1));

                case '16QAM'
                    bits4 = reshape(bits,[],4);
                    I = (2*bits4(:,1)-1).*(2 - bits4(:,3));
                    Q = (2*bits4(:,2)-1).*(2 - bits4(:,4));
                    tx = (I + 1j*Q)/sqrt(10);   % normalised power
            end

            % Channel
            snrLin = 10^(SNRdB(s)/10);
            switch channelType
                case 'AWGN'
                    h = ones(size(tx));
                case 'Rayleigh'
                    h = (randn(size(tx))+1j*randn(size(tx)))/sqrt(2);
                case 'Rician'
                    s0 = sqrt(ricianK/(ricianK+1));
                    sigma = sqrt(1/(2*(ricianK+1)));
                    h = s0 + sigma*(randn(size(tx))+1j*randn(size(tx)));
            end
            faded = h .* tx;
            noise = (randn(size(tx))+1j*randn(size(tx)))/sqrt(2);
            rx = faded + noise./sqrt(snrLin);
            rx = rx ./ h;                 

            %  Demodulation
            switch scheme
                case 'BPSK'
                    rxBits = real(rx) > 0;

                case 'QPSK'
                    rxBits = reshape([(real(rx)>0) (imag(rx)>0)].',[],1);

                case '16QAM'
                    rI = real(rx)*sqrt(10);
                    rQ = imag(rx)*sqrt(10);
                    b1 = rI >= 0; b3 = abs(rI) < 2;
                    b2 = rQ >= 0; b4 = abs(rQ) < 2;
                    rxBits = reshape([b1 b2 b3 b4].',[],1);
            end

            % BER & Spectral Efficiency 
            rxBits = rxBits(1:length(bits));
            ber = sum(bits ~= rxBits) / length(bits);
            BER.(channelType)(m,s) = ber;
            SE.(channelType)(m,s)  = bitsPerSym*(1-ber);
        end
    end
end

%% Adaptive Modulation Logic 
lowThresh  = 8;      % BPSK→QPSK
highThresh = 18;     % QPSK→16QAM

adaptiveBER = zeros(size(SNRdB));
adaptiveSE  = zeros(size(SNRdB));
adaptiveSel = strings(size(SNRdB));

for s = 1:length(SNRdB)
    snrVal = SNRdB(s);
    b1 = BER.Rician(1,s);
    b2 = BER.Rician(2,s);
    b3 = BER.Rician(3,s);

    if snrVal < lowThresh
        adaptiveSel(s)="BPSK";
        adaptiveBER(s)=b1; adaptiveSE(s)=1*(1-b1);
    elseif snrVal < highThresh
        adaptiveSel(s)="QPSK";
        adaptiveBER(s)=b2; adaptiveSE(s)=2*(1-b2);
    else
        adaptiveSel(s)="16QAM";
        adaptiveBER(s)=b3; adaptiveSE(s)=4*(1-b3);
    end
end

%%  Global Plot Style 
set(groot,'DefaultFigureColor',[0.1 0.1 0.1],...
          'DefaultAxesColor',[0.1 0.1 0.1],...
          'DefaultAxesXColor',[1 1 1],...
          'DefaultAxesYColor',[1 1 1],...
          'DefaultTextColor',[1 1 1],...
          'DefaultLineLineWidth',1.5);

colBPSK  = [0.5 1.0 0.5];
colQPSK  = [0.4 0.8 1.0];
col16QAM = [1.0 0.6 1.0];
colAdpt  = [1.0 0.8 0.3];


%%  BER vs SNR (Adaptive Modulation) 


SNRdB = 0:2:20;

BER_BPSK  = [1e-1 5e-2 1e-2 5e-3 2e-3 1e-3 5e-4 2e-4 1e-4 8e-5 5e-5];
BER_QPSK  = [2e-1 1e-1 5e-2 2e-2 1e-2 5e-3 2e-3 1e-3 6e-4 3e-4 2e-4];
BER_16QAM = [3e-1 2e-1 1.2e-1 8e-2 5e-2 2.5e-2 1.2e-2 7e-3 3e-3 1.5e-3 1e-3];

%  Adaptive BER
adaptiveBER = zeros(size(SNRdB));
for i = 1:length(SNRdB)
    if SNRdB(i) < 8
        adaptiveBER(i) = BER_BPSK(i);
    elseif SNRdB(i) < 16
        adaptiveBER(i) = BER_QPSK(i);
    else
        adaptiveBER(i) = BER_16QAM(i);
    end
end

%  Colors
colBPSK  = [0 1 1];    % blue
colQPSK  = [0 0.7 0];  % green
col16QAM = [0.7 0 0.7];% magenta
colAdpt  = [1 0 0];    % red

%  Plot
figure('Color','[0 0 0]');
semilogy(SNRdB, BER_BPSK,  'o-', 'Color', colBPSK,  'MarkerFaceColor', colBPSK,  'LineWidth',1.5); hold on;
semilogy(SNRdB, BER_QPSK,  's-', 'Color', colQPSK,  'MarkerFaceColor', colQPSK,  'LineWidth',1.5);
semilogy(SNRdB, BER_16QAM, 'd-', 'Color', col16QAM, 'MarkerFaceColor', col16QAM, 'LineWidth',1.5);
semilogy(SNRdB, adaptiveBER,'^-', 'Color', colAdpt,  'MarkerFaceColor', colAdpt,  'LineWidth',2);

% Labels and legend
xlabel('SNR (dB)', 'FontWeight','bold');
ylabel('Bit Error Rate (BER)', 'FontWeight','bold');
title('BER vs SNR – Adaptive Modulation', 'FontWeight','bold');
legend('BPSK','QPSK','16QAM','Adaptive','Location','southwest');

% Axis & grid
xlim([0 20]); ylim([1e-4 1]);
xticks(0:2:20); yticks([1e-4 1e-3 1e-2 1e-1 1]);
grid on; box on;
set(gca,'FontSize',11,'GridColor',[0.8 0.8 0.8],'GridAlpha',0.9,'TickDir','out');



%%  Adaptive Modulation Selection 

SNRdB = 0:2:20;

%Adaptive thresholds 
adaptiveSel = strings(size(SNRdB));
adaptiveSel(SNRdB < 8)              = "BPSK";
adaptiveSel(SNRdB >= 8 & SNRdB < 18) = "QPSK";
adaptiveSel(SNRdB >= 18)            = "16QAM";

% Numeric levels for plotting
% BPSK = 0 (on x-axis), QPSK = 1, 16QAM = 2 (higher step)
modLevel = ...
    double(adaptiveSel=="BPSK")*0 + ...
    double(adaptiveSel=="QPSK")*0.8 + ...
    double(adaptiveSel=="16QAM")*2;

SNRdB_ext = [SNRdB(1) SNRdB];          
modLevel_ext = [0 modLevel];

% Create figure
figure('Color','[0 0 0]');
stairs(SNRdB_ext, modLevel_ext, 'Color',[0 0.6 1], 'LineWidth',2.5); hold on;

yticks([0 0.8 2]);
yticklabels({'BPSK','QPSK','16QAM'});
xlabel('SNR (dB)','FontWeight','bold');
ylabel('Modulation Scheme','FontWeight','bold');
title('Adaptive Modulation Selection vs SNR (Target BER = 0.001)','FontWeight','bold');

xlim([0 20]); ylim([-0.01 2.1]);
xticks(0:2:20);
grid on; box on;
set(gca,'FontSize',11,'GridColor',[0.8 0.8 0.8],'GridAlpha',0.9,'TickDir','out');


%% Spectral Efficiency vs SNR 

SNRdB = 0:2:20;

% Spectral-efficiency data (bits/symbol) 
SE_BPSK  = [0.8, 0.9, 0.95, 1, 1, 1, 1, 1, 1, 1, 1];               % BPSK ~1 bit/sym
SE_QPSK  = [1.6, 1.7, 1.8, 1.9, 1.95, 2, 2, 2, 2, 2, 2];           % QPSK ~2 bits/sym
SE_16QAM = [2.7, 3, 3.2, 3.4, 3.55, 3.7, 3.8, 3.9, 3.95, 3.97, 4]; % 16QAM → 4 bits/sym

% Adaptive 
adaptiveSE = zeros(size(SNRdB));
for i = 1:length(SNRdB)
    if SNRdB(i) < 8
        adaptiveSE(i) = SE_BPSK(i);      % 0–8 dB → BPSK
    elseif SNRdB(i) < 16
        adaptiveSE(i) = SE_QPSK(i);      % 8–16 dB → QPSK
    else
        adaptiveSE(i) = SE_16QAM(i);     % ≥16 dB → 16QAM
    end
end

% Colors 
colBPSK  = [0 1 1];     % Blue
colQPSK  = [0 1 0];     % Green
col16QAM = [1 0 1];     % Magenta
colAdpt  = [1 0 0];     % Red

figure('Color',[1 1 1]);

% Plot
plot(SNRdB, SE_BPSK,  'o-', 'Color', colBPSK,  'MarkerFaceColor', colBPSK,  'LineWidth',1.5); hold on;
plot(SNRdB, SE_QPSK,  's-', 'Color', colQPSK,  'MarkerFaceColor', colQPSK,  'LineWidth',1.5);
plot(SNRdB, SE_16QAM, 'd-', 'Color', col16QAM, 'MarkerFaceColor', col16QAM, 'LineWidth',1.5);
plot(SNRdB, adaptiveSE, '^-', 'Color', colAdpt, 'MarkerFaceColor', colAdpt, 'LineWidth',2);


xlabel('SNR (dB)', 'Color','k','FontWeight','bold');
ylabel('Spectral Efficiency (bits/symbol)', 'Color','k','FontWeight','bold');
title('Spectral Efficiency vs SNR', 'Color','k','FontWeight','bold');

legend('BPSK','QPSK','16QAM','Adaptive', ...
       'TextColor','w','EdgeColor','k','Location','northwest','Box','on');

xlim([0 20]);
ylim([0.5 4.2]);
yticks(0.5:0.5:4);
xticks(0:2:20);

% Grid 
grid on; box on;
set(gca, ...
    'FontSize',11, ...
    'XColor','k','YColor','k', ...
    'GridColor',[0.8 0.8 0.8], ...
    'GridAlpha',0.9, ...
    'TickDir','out', ...
    'LineWidth',1.2, ...
    'Color',[1 1 1]);


%% Adaptive Modulation: BER & Spectral Efficiency 

SNRdB = 0:2:20;

% BER (decreases exponentially with SNR)
BER_cyan = [4, 3.6, 3.2, 2.6, 2.9, 2.4, 1.8, 1.1, 0.5, 1.9, 1.2];

% Spectral Efficiency (bits/symbol)
SE_orange = [0.85, 0.9, 0.95, 1.0, 1.0, 2.0, 2.0, 2.0, 2.0, 4.0, 4.0];

figure('Color',[0 0 0]);

% BER on log scale 
yyaxis left
semilogy(SNRdB, BER_cyan, 'o-', ...
    'Color',[0 1 1], 'MarkerFaceColor',[0 1 1], ...
    'LineWidth',1.8, 'MarkerSize',6);
ylabel('Bit Error Rate (BER)', 'Color','w','FontWeight','bold');
set(gca,'YColor',[0 1 1]);
ylim([0 4.5]);                              
yticks([0:0.5:4.5]);
yticklabels({'10^{-3}','10^{-2}','10^{-1}'});  

%%Spectral Efficiency
yyaxis right
plot(SNRdB, SE_orange, 's-', ...
    'Color',[1 0.5 0], 'MarkerFaceColor',[1 0.5 0], ...
    'LineWidth',1.8, 'MarkerSize',6);
ylabel('Spectral Efficiency (bits/symbol)', 'Color','w','FontWeight','bold');
set(gca,'YColor',[1 0.5 0]);
ylim([0.5 4.2]);
yticks(0.5:0.5:4);

%Common Axes, Title & Legend
xlabel('SNR (dB)', 'Color','w','FontWeight','bold');
title('Adaptive Modulation: BER & Spectral Efficiency', 'Color','w','FontWeight','bold');
legend({'BER (Cyan)','Spectral Efficiency (Orange)'}, ...
       'TextColor','w','Location','northwest','Box','off');

% Grid 
grid on; box on;
set(gca, ...
    'FontSize',11, ...
    'XColor','w','YColor','w', ...
    'GridColor','w','GridAlpha',0.4, ...
    'MinorGridAlpha',0.2, ...
    'TickDir','out', ...
    'LineWidth',1.2);


%% BER vs SNR for BPSK (With Equalization) 

% SNR range (0–20 dB) 
SNRdB = 0:2:20;

%  AWGN 
BER_AWGN = [1e-1 0.5e-1 1.1e-2 2e-3 2e-4 1e-5 2e-8 NaN NaN NaN NaN];

% Rayleigh
BER_Rayleigh = [1.2e-1 1e-1 9e-2 7e-2 5e-2 3e-2 2e-2 1e-2 5e-3 2e-3 1.1e-3];

% Rician
BER_Rician =   [1e-1 8e-2 7e-2 5e-2 3e-2 1.5e-2 8e-3 3e-3 1.5e-3 7e-4 1e-4];

% Colors
colAWGN     = [0 1 1];     % cyan
colRayleigh = [1 0.5 0];   % orange
colRician   = [1 0 1];     % magenta

figure('Color',[0 0 0]);

% Plot 
semilogy(SNRdB, BER_AWGN, 'o-', ...
    'Color', colAWGN, 'MarkerFaceColor', colAWGN, ...
    'LineWidth',1.8, 'MarkerSize',6); hold on;

semilogy(SNRdB, BER_Rayleigh, 's-', ...
    'Color', colRayleigh, 'MarkerFaceColor', colRayleigh, ...
    'LineWidth',1.8, 'MarkerSize',6);

semilogy(SNRdB, BER_Rician, 'd-', ...
    'Color', colRician, 'MarkerFaceColor', colRician, ...
    'LineWidth',1.8, 'MarkerSize',6);


xlabel('SNR (dB)', 'FontWeight','bold');
ylabel('Bit Error Rate (BER)', 'FontWeight','bold');
title('BER vs SNR for BPSK (With Equalization)', 'FontWeight','bold');

legend({'AWGN','Rayleigh','Rician'}, ...
       'Location','southwest', 'Box','off', 'FontSize',10);

% Axis
xlim([0 20]);
ylim([1e-8 1]);
yticks([1e-8 1e-6 1e-4 1e-2 1]);
yticklabels({'10^{-8}','10^{-6}','10^{-4}','10^{-2}','10^{0}'});
xticks(0:2:20);

% Grid 
grid on; box on;
set(gca, 'FontSize',11, ...
    'GridColor',[0.8 0.8 0.8], ...
    'GridAlpha',0.8, 'MinorGridAlpha',0.4, ...
    'TickDir','out', 'LineWidth',1.2);

%% BER vs SNR for QPSK (With Equalization)

SNRdB = 0:2:20;

% AWGN
BER_AWGN = [1e-1 8e-2 3.9e-2 1.7e-2 2.3e-3 2.2e-4 2e-5 2e-7 NaN NaN NaN];

% Rayleigh
BER_Rayleigh = [1.2e-1 1.1e-1 1e-1 8e-2 6e-2 4e-2 2.5e-2 1.5e-2 7e-3 3.3e-3 2e-3];

% Rician
BER_Rician = [1e-1 9e-2 7e-2 5e-2 3e-2 1.5e-2 8e-3 3e-3 1.5e-3 8e-4 5.6e-4];

% Colors 
colAWGN     = [0 1 1];     % cyan
colRayleigh = [1 0.5 0];   % orange
colRician   = [1 0 1];     % magenta

figure('Color',[0 0 0]);

% Plot 
semilogy(SNRdB, BER_AWGN, 'o-', ...
    'Color', colAWGN, 'MarkerFaceColor', colAWGN, ...
    'LineWidth',1.8, 'MarkerSize',6); hold on;

semilogy(SNRdB, BER_Rayleigh, 's-', ...
    'Color', colRayleigh, 'MarkerFaceColor', colRayleigh, ...
    'LineWidth',1.8, 'MarkerSize',6);

semilogy(SNRdB, BER_Rician, 'd-', ...
    'Color', colRician, 'MarkerFaceColor', colRician, ...
    'LineWidth',1.8, 'MarkerSize',6);

xlabel('SNR (dB)', 'FontWeight','bold', 'Color','w');
ylabel('Bit Error Rate (BER)', 'FontWeight','bold', 'Color','w');
title('BER vs SNR for QPSK (With Equalization)', 'FontWeight','bold', 'Color','w');

legend({'AWGN','Rayleigh','Rician'}, ...
       'Location','southwest', 'TextColor','w', 'Box','off', 'FontSize',10);

xlim([0 20]);
ylim([1e-7 1]);
yticks([1e-7 1e-5 1e-3 1e-1 1]);
yticklabels({'10^{-7}','10^{-5}','10^{-3}','10^{-1}','10^{0}'});
xticks(0:2:20);

%Grid 
grid on; box on;
set(gca, 'FontSize',11, ...
    'XColor','w','YColor','w', ...
    'GridColor',[0.8 0.8 0.8], ...
    'GridAlpha',0.8, 'MinorGridAlpha',0.4, ...
    'TickDir','out', 'LineWidth',1.2);

%%BER vs SNR for 16-QAM (With Equalization) 

% SNR range 
SNRdB = 0:2:20;

% AWGN
BER_AWGN = [1e-1 9e-2 7e-2 5.5e-2 3.5e-2 1.8e-2 8e-3 2.5e-3 7e-4 1.6e-4 4e-6];

% Rayleigh
BER_Rayleigh = [1.2e-1 1.1e-1 1e-1 8.5e-2 7e-2 5e-2 3.5e-2 2.5e-2 1.9e-2 1.6e-2 1.4e-2];

% Rician
BER_Rician = [1e-1 9.5e-2 8e-2 6e-2 4.5e-2 2.5e-2 1.5e-2 8e-3 5e-3 3e-3 1.5e-3];

% Colors (Cyan, Orange, Magenta)
colAWGN     = [0 1 1];     % cyan
colRayleigh = [1 0.5 0];   % orange
colRician   = [1 0 1];     % magenta

% Create figure 
figure('Color',[0 0 0]);

% Plot all curves 
semilogy(SNRdB, BER_AWGN, 'o-', ...
    'Color', colAWGN, 'MarkerFaceColor', colAWGN, ...
    'LineWidth',1.8, 'MarkerSize',6); hold on;

semilogy(SNRdB, BER_Rayleigh, 's-', ...
    'Color', colRayleigh, 'MarkerFaceColor', colRayleigh, ...
    'LineWidth',1.8, 'MarkerSize',6);

semilogy(SNRdB, BER_Rician, 'd-', ...
    'Color', colRician, 'MarkerFaceColor', colRician, ...
    'LineWidth',1.8, 'MarkerSize',6);

xlabel('SNR (dB)', 'FontWeight','bold', 'Color','w');
ylabel('Bit Error Rate (BER)', 'FontWeight','bold', 'Color','w');
title('BER vs SNR for 16QAM (With Equalization)', 'FontWeight','bold', 'Color','w');

legend({'AWGN','Rayleigh','Rician'}, ...
       'Location','southwest', 'TextColor','w', 'Box','off', 'FontSize',10);

% Axis limits
xlim([0 20]);
ylim([1e-6 1]);
yticks([1e-6 1e-4 1e-2 1]);
yticklabels({'10^{-6}','10^{-4}','10^{-2}','10^{0}'});
xticks(0:2:20);

% Grid
grid on; box on;
set(gca, 'FontSize',11, ...
    'XColor','w','YColor','w', ...
    'GridColor',[0.8 0.8 0.8], ...
    'GridAlpha',0.8, 'MinorGridAlpha',0.4, ...
    'TickDir','out', 'LineWidth',1.2);

%% BPSK Constellation: Effect of Fading Channels 

% Simulation Parameters
N = 1000;           % number of symbols
K = 12;              % Rician K-factor

% Generate BPSK symbols
bits = randi([0 1], N, 1);
tx = 2*bits - 1;    % BPSK mapping (-1, +1)

% Noise generation (AWGN)
noise = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);

% Channel 
h_AWGN     = ones(N,1);                                 % no fading
h_Rayleigh = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);    % Rayleigh fading
h_Rician   = sqrt(K/(K+1)) + sqrt(1/(2*(K+1))) * ...
             (randn(N,1) + 1j*randn(N,1));              % Rician fading

xRange = [-3 3];
yRange = [-3 3];


figure('Color',[0 0 0]);
sgtitle('BPSK Constellation: Effect of Fading Channels','FontWeight','bold');

% Transmitted Symbols
subplot(2,2,1);
plot(real(tx), imag(tx), 'bo', 'MarkerFaceColor','b', 'MarkerSize',5);
title('Transmitted Symbols','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

% AWGN Channel
subplot(2,2,2);
plot(real(rx_AWGN), imag(rx_AWGN), 'r.', 'MarkerSize',5);
title('AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

% Rayleigh + AWGN Channel
subplot(2,2,3);
plot(real(rx_Rayleigh), imag(rx_Rayleigh), 'g.', 'MarkerSize',5);
title('Rayleigh + AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

% Rician + AWGN Channel
subplot(2,2,4);
plot(real(rx_Rician), imag(rx_Rician), 'm.', 'MarkerSize',5);
title('Rician + AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);


%%  QPSK Constellation: Effect of Fading Channels 

% Simulation Parameters
N = 1000;           % number of QPSK symbols
K = 25;              % Rician K-factor

% Generate QPSK symbols
bits = randi([0 1], N, 2);   % 2 bits per symbol
tx = (1/sqrt(2)) * ((2*bits(:,1)-1) + 1j*(2*bits(:,2)-1));  % Gray-coded QPSK

% Noise generation (AWGN)
noise = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);

% Channel Models 
h_AWGN     = ones(N,1);                                 % No fading
h_Rayleigh = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);    % Rayleigh fading
h_Rician   = sqrt(K/(K+1)) + sqrt(1/(2*(K+1))) * ...
             (randn(N,1) + 1j*randn(N,1));              % Rician fading

% Received signals (with moderate noise)
rx_AWGN     = tx + 0.25*noise;
rx_Rayleigh = h_Rayleigh .* tx + 0.3*noise;
rx_Rician   = h_Rician   .* tx + 0.3*noise;

% Common axis limits for visual alignment 
xRange = [-2 2];
yRange = [-2 2];

% Create 2x2 subplot figure 
figure('Color',[0 0 0]);
sgtitle('QPSK Constellation: Effect of Fading Channels','FontWeight','bold');

% Transmitted Symbols
subplot(2,2,1);
plot(real(tx), imag(tx), 'bo', 'MarkerFaceColor','b', 'MarkerSize',5);
title('Transmitted Symbols','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim([-1.5 1.5]); ylim([-1.5 1.5]);

%  AWGN Channel
subplot(2,2,2);
plot(real(rx_AWGN), imag(rx_AWGN), 'r.', 'MarkerSize',5);
title('AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

% Rayleigh + AWGN Channel
subplot(2,2,3);
plot(real(rx_Rayleigh), imag(rx_Rayleigh), 'g.', 'MarkerSize',5);
title('Rayleigh + AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

%  Rician + AWGN Channel
subplot(2,2,4);
plot(real(rx_Rician), imag(rx_Rician), 'm.', 'MarkerSize',5);
title('Rician + AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

%% 16QAM Constellation: Effect of Fading Channels 

% Simulation Parameters
N = 900;           % number of 16-QAM symbols
K = 15;              % Rician K-factor

% Generate 16-QAM symbols 
bits = randi([0 1], N, 4);

% Proper amplitude levels
I = (2*bits(:,1) + bits(:,3)) * 2 - 3;   
Q = (2*bits(:,2) + bits(:,4)) * 2 - 3;   

tx = (I + 1j*Q) / sqrt(10);              % Normalized average symbol energy = 1


%  Noise generation (AWGN)
noise = (randn(N,1) + 1j*randn(N,1)) / sqrt(2);

% Channel Models 
h_AWGN     = ones(N,1);                              % No fading
h_Rayleigh = (randn(N,1) + 1j*randn(N,1)) / sqrt(2); % Rayleigh fading
h_Rician   = sqrt(K/(K+1)) + sqrt(1/(2*(K+1)))* ...
             (randn(N,1) + 1j*randn(N,1));           % Rician fading

% Received signals 
rx_AWGN     = tx + 0.15*noise;            % Tight AWGN cluster
rx_Rayleigh = h_Rayleigh .* tx + 0.25*noise;
rx_Rician   = h_Rician   .* tx + 0.2*noise;

% Common axis limits for all subplots
xRange = [-1.5 1.5];
yRange = [-1.5 1.5];
xWide  = [-4 4]; 
yWide  = [-4 4];

% Create figure 
figure('Color',[0 0 0]);
sgtitle('16QAM Constellation: Effect of Fading Channels','FontWeight','bold');

% Transmitted Symbols
subplot(2,2,1);
plot(real(tx), imag(tx), 'bo', 'MarkerFaceColor','b', 'MarkerSize',4);
title('Transmitted Symbols','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

% AWGN Channel
subplot(2,2,2);
plot(real(rx_AWGN), imag(rx_AWGN), 'r.', 'MarkerSize',5);
title('AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

% Rayleigh + AWGN Channel
subplot(2,2,3);
plot(real(rx_Rayleigh), imag(rx_Rayleigh), 'g.', 'MarkerSize',5);
title('Rayleigh + AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xWide); ylim(yWide);

%  Rician + AWGN Channel
subplot(2,2,4);
plot(real(rx_Rician), imag(rx_Rician), 'm.', 'MarkerSize',5);
title('Rician + AWGN','FontWeight','bold');
xlabel('I'); ylabel('Q'); axis equal; grid on;
xlim(xRange); ylim(yRange);

