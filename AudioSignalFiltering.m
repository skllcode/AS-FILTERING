%% Course Project 1 - Audio Signal Filtering
% Aim: To filter noisy Audio Signal using FIR and IIR Filters
% Student: Shrujal Rajendra Kakade
% Signal: SYB05 (Fs = 44100 Hz, Duration = 3.52 s)

clc; clear; close all;

%% 1. Load the noisy signal
[noisy_signal, Fs] = audioread('SYB05/SYB05/noisySYB05new.wav');
load('SYB05/SYB05/noisySYB05new.mat');  % loads variable x3

N = length(noisy_signal);
t = (0:N-1) / Fs;  % time vector

% Create output directories
if ~exist('plots', 'dir'), mkdir('plots'); end
if ~exist('audio_output', 'dir'), mkdir('audio_output'); end

%% 2. Plot the Time Domain Noisy Signal
figure('Position', [100 100 900 400]);
plot(t, noisy_signal, 'b');
xlabel('Time (seconds)');
ylabel('Amplitude');
title('Noisy Audio Signal - Time Domain');
grid on;
saveas(gcf, 'plots/01_noisy_signal_time_domain.png');

%% 3. Compute and Plot the Magnitude of FFT of Noisy Audio Signal
Y_noisy = fft(noisy_signal);
f = (0:N-1) * (Fs / N);  % frequency vector
mag_noisy = abs(Y_noisy);

figure('Position', [100 100 900 400]);
plot(f(1:floor(N/2)), mag_noisy(1:floor(N/2)), 'r');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT of Noisy Audio Signal');
grid on;
saveas(gcf, 'plots/02_fft_noisy_signal.png');

%% 4. FFT of Original Signal (from .mat file) and Comparison
Y_original = fft(x3);
mag_original = abs(Y_original);

figure('Position', [100 100 900 400]);
plot(f(1:floor(N/2)), mag_original(1:floor(N/2)), 'g');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT of Original Signal (from .mat data)');
grid on;
saveas(gcf, 'plots/03_fft_original_signal.png');

% Comparison plot
figure('Position', [100 100 900 500]);
subplot(2,1,1);
plot(f(1:floor(N/2)), mag_noisy(1:floor(N/2)), 'r');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT of Noisy Signal');
grid on;

subplot(2,1,2);
plot(f(1:floor(N/2)), mag_original(1:floor(N/2)), 'g');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT of Original Signal (from .mat)');
grid on;
saveas(gcf, 'plots/04_fft_comparison.png');

%% Time Domain Plot of Original Signal
t_orig = (0:length(x3)-1) / Fs;
figure('Position', [100 100 900 400]);
plot(t_orig, x3, 'g');
xlabel('Time (seconds)');
ylabel('Amplitude');
title('Original Audio Signal - Time Domain');
grid on;
saveas(gcf, 'plots/05_original_signal_time_domain.png');

%% 5. Design Appropriate Filters
% Analysis: Noise is concentrated in 6 kHz - 22 kHz range
% Useful audio content is below 4-5 kHz
% Solution: Low-pass filter with cutoff at 5000 Hz

fc = 5000;                    % Cutoff frequency in Hz
Wn = fc / (Fs/2);             % Normalized cutoff frequency

% ==================== FIR Filter Design ====================
% Using Kaiser window method
filter_order_fir = 100;       % FIR filter order
b_fir = fir1(filter_order_fir, Wn, 'low', kaiser(filter_order_fir+1, 5));
a_fir = 1;

% ==================== IIR Filter Design ====================
% Using Butterworth filter
filter_order_iir = 6;         % IIR filter order
[b_iir, a_iir] = butter(filter_order_iir, Wn, 'low');

%% 6. Plot the Frequency Response of the Filters
% FIR Filter Frequency Response
figure('Position', [100 100 900 500]);
[H_fir, W_fir] = freqz(b_fir, a_fir, 4096, Fs);
subplot(2,1,1);
plot(W_fir, 20*log10(abs(H_fir)), 'b', 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title(sprintf('FIR Low-Pass Filter (Kaiser Window) - Order %d, fc = %d Hz', filter_order_fir, fc));
grid on;
xlim([0 Fs/2]);
ylim([-80 5]);
xline(fc, '--r', 'Cutoff', 'LineWidth', 1.2);

% IIR Filter Frequency Response
[H_iir, W_iir] = freqz(b_iir, a_iir, 4096, Fs);
subplot(2,1,2);
plot(W_iir, 20*log10(abs(H_iir)), 'm', 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title(sprintf('IIR Low-Pass Filter (Butterworth) - Order %d, fc = %d Hz', filter_order_iir, fc));
grid on;
xlim([0 Fs/2]);
ylim([-80 5]);
xline(fc, '--r', 'Cutoff', 'LineWidth', 1.2);
saveas(gcf, 'plots/06_filter_frequency_responses.png');

%% 7. Apply the Designed Filters to the Noisy Signal
% Apply FIR filter
filtered_fir = filter(b_fir, a_fir, noisy_signal);

% Apply IIR filter
filtered_iir = filter(b_iir, a_iir, noisy_signal);

% Use IIR Butterworth as the primary filtered output
filtered_signal = filtered_iir;

%% 8. Plot Time Domain and FFT of Filtered Signal

% --- FIR Filtered Signal ---
figure('Position', [100 100 900 500]);
subplot(2,1,1);
plot(t, filtered_fir, 'b');
xlabel('Time (seconds)');
ylabel('Amplitude');
title('FIR Filtered Signal - Time Domain');
grid on;

Y_fir = fft(filtered_fir);
mag_fir = abs(Y_fir);
subplot(2,1,2);
plot(f(1:floor(N/2)), mag_fir(1:floor(N/2)), 'b');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT of FIR Filtered Signal');
grid on;
saveas(gcf, 'plots/07_fir_filtered_signal.png');

% --- IIR Filtered Signal ---
figure('Position', [100 100 900 500]);
subplot(2,1,1);
plot(t, filtered_iir, 'm');
xlabel('Time (seconds)');
ylabel('Amplitude');
title('IIR Filtered Signal (Butterworth) - Time Domain');
grid on;

Y_iir = fft(filtered_iir);
mag_iir = abs(Y_iir);
subplot(2,1,2);
plot(f(1:floor(N/2)), mag_iir(1:floor(N/2)), 'm');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT of IIR Filtered Signal (Butterworth)');
grid on;
saveas(gcf, 'plots/08_iir_filtered_signal.png');

% --- Combined Comparison ---
figure('Position', [100 100 1000 700]);
subplot(3,1,1);
plot(f(1:floor(N/2)), mag_noisy(1:floor(N/2)), 'r');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('FFT Comparison: Noisy vs Filtered');
legend('Noisy Signal'); grid on;

subplot(3,1,2);
plot(f(1:floor(N/2)), mag_fir(1:floor(N/2)), 'b');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('FIR Filtered Signal');
legend('FIR (Kaiser)'); grid on;

subplot(3,1,3);
plot(f(1:floor(N/2)), mag_iir(1:floor(N/2)), 'm');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('IIR Filtered Signal');
legend('IIR (Butterworth)'); grid on;
saveas(gcf, 'plots/09_fft_comparison_all.png');

% Filtered signal time domain plot
figure('Position', [100 100 900 400]);
plot(t, filtered_signal, 'Color', [0 0.6 0]);
xlabel('Time (seconds)');
ylabel('Amplitude');
title('Filtered Audio Signal - Time Domain (IIR Butterworth)');
grid on;
saveas(gcf, 'plots/10_filtered_signal_time_domain.png');

% FFT of filtered signal standalone
figure('Position', [100 100 900 400]);
plot(f(1:floor(N/2)), mag_iir(1:floor(N/2)), 'Color', [0 0.6 0]);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT of Filtered Signal (IIR Butterworth)');
grid on;
saveas(gcf, 'plots/11_fft_filtered_signal.png');

%% 9. Save and Play Audio Files
% Normalize before saving
filtered_fir_norm = filtered_fir / max(abs(filtered_fir));
filtered_iir_norm = filtered_iir / max(abs(filtered_iir));

audiowrite('audio_output/noisy_signal.wav', noisy_signal, Fs);
audiowrite('audio_output/filtered_FIR.wav', filtered_fir_norm, Fs);
audiowrite('audio_output/filtered_IIR_Butterworth.wav', filtered_iir_norm, Fs);

% Save original signal from .mat as wav
x3_norm = x3 / max(abs(x3));
audiowrite('audio_output/original_signal_from_mat.wav', x3_norm, Fs);

fprintf('\n========================================\n');
fprintf('  Audio Signal Filtering - Complete\n');
fprintf('========================================\n');
fprintf('Sampling Frequency: %d Hz\n', Fs);
fprintf('Signal Duration: %.2f seconds\n', N/Fs);
fprintf('Number of Samples: %d\n', N);
fprintf('Filter Cutoff Frequency: %d Hz\n', fc);
fprintf('FIR Filter Order: %d (Kaiser Window)\n', filter_order_fir);
fprintf('IIR Filter Order: %d (Butterworth)\n', filter_order_iir);
fprintf('\nPlots saved to: plots/\n');
fprintf('Audio files saved to: audio_output/\n');
fprintf('========================================\n');

%% Play filtered signal
fprintf('\nPlaying filtered signal (IIR Butterworth)...\n');
sound(filtered_iir_norm, Fs);
