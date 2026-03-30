%% Analiza Hałasu Drogowego 2018-2024
clear; clc; close all;

% --- KROK 1: IMPORT DANYCH ---
selPath = uigetdir(pwd, 'Wybierz folder z plikami CSV');
if selPath == 0, error('Nie wybrano folderu.'); end
cd(selPath);

if ~exist('wykresy', 'dir'), mkdir('wykresy'); end

fileNames = {'Wyniki_pomiarow_halasu_drogowego_w_2018_roku.csv', ...
             'Wyniki_pomiarow_halasu_drogowego_w_2019_roku.csv', ...
             'Wyniki_pomiarow_halasu_drogowego_w_2020_roku.csv', ...
             'Wyniki_pomiarow_halasu_drogowego_w_2021_roku.csv', ...
             'Wyniki_pomiarow_halasu_drogowego_w_2022_roku.csv', ...
             'Wyniki_pomiarow_halasu_drogowego_w_2023_roku.csv', ...
             'Wyniki_pomiarow_halasu_drogowego_w_2024_roku.csv'};

dataList = {};

for i = 1:length(fileNames)
    fname = fileNames{i};
    if ~isfile(fname), continue; end
    y = str2double(regexp(fname, '\d{4}', 'match', 'once'));
    
    opts = detectImportOptions(fname, 'VariableNamingRule', 'preserve');
    if y == 2020, opts.Delimiter = ';'; end
    
    T_raw = readtable(fname, opts);
    vars = T_raw.Properties.VariableNames;
    
    idxProv = find(contains(vars, 'Wojew', 'IgnoreCase', true), 1);
    idxNoise = find(contains(vars, 'Laeq', 'IgnoreCase', true), 1);
    idxTime = find(contains(vars, 'Czas', 'IgnoreCase', true), 1);
    idxLon = find(contains(vars, 'dł. geogr', 'IgnoreCase', true), 1);
    idxLat = find(contains(vars, 'szer. geogr', 'IgnoreCase', true), 1);

    try
        f_prov = mapProvince(T_raw{:, idxProv});
        
        noiseRaw = T_raw{:, idxNoise};
        if iscell(noiseRaw) || isstring(noiseRaw), f_noise = str2double(strrep(string(noiseRaw), ',', '.'));
        else, f_noise = double(noiseRaw); end
        
        f_time = repmat("Nieokreślony", height(T_raw), 1);
        if ~isempty(idxTime), f_time = string(T_raw{:, idxTime}); end
        
        f_lon = nan(height(T_raw), 1); f_lat = nan(height(T_raw), 1);
        if ~isempty(idxLon) && ~isempty(idxLat)
            f_lon = str2double(strrep(string(T_raw{:, idxLon}), ',', '.'));
            f_lat = str2double(strrep(string(T_raw{:, idxLat}), ',', '.'));
        end
        
        n = min([length(f_prov), length(f_noise), length(f_time), length(f_lon)]);
        T_clean = table(repmat(y, n, 1), reshape(f_prov(1:n), [], 1), ...
            reshape(f_noise(1:n), [], 1), reshape(f_time(1:n), [], 1), ...
            reshape(f_lon(1:n), [], 1), reshape(f_lat(1:n), [], 1), ...
            'VariableNames', {'Year','Province','NoiseLevel','TimePeriod','Lon','Lat'});
        dataList{end+1} = T_clean;
        fprintf('Wczytano pomyślnie rok %d\n', y);
    catch ME
        fprintf('Pominięto problematyczny plik: %d\n', y);
    end
end

allData = vertcat(dataList{:});
allData(isnan(allData.NoiseLevel), :) = [];
allData(allData.Province == "Nieznane", :) = []; 
allData.Province = categorical(allData.Province);

%% --- KROK 2: GENEROWANIE WYKRESÓW ---

% 1. Średni hałas rocznie
figure('Color', 'w');
yAvg = groupsummary(allData, 'Year', 'mean', 'NoiseLevel');
bar(yAvg.Year, yAvg.mean_NoiseLevel, 0.6, 'FaceColor', [0.15 0.3 0.6]);
ylim([min(yAvg.mean_NoiseLevel)-5, max(yAvg.mean_NoiseLevel)+5]);
formatChart('Średni poziom hałasu rocznie', 'Rok', 'dB', '01_sredni_halas');

% 2. Histogram
figure('Color', 'w');
histogram(allData.NoiseLevel, 'BinWidth', 2, 'FaceColor', [0.2 0.5 0.2], 'EdgeColor', 'k');
formatChart('Rozkład wszystkich pomiarów', 'Poziom [dB]', 'Ilość', '02_histogram');

% 3. Boxplot roczny
figure('Color', 'w');
boxplot(allData.NoiseLevel, allData.Year, 'Colors', 'k');
formatChart('Statystyka hałasu w latach', 'Rok', 'dB', '03_boxplot_roczny');

% 4. PORÓWNANIE 2018 vs 2024
figure('Color', 'w', 'Position', [100 100 800 600]); 
pAvg2018 = groupsummary(allData(allData.Year == 2018, :), 'Province', 'mean', 'NoiseLevel');
pAvg2024 = groupsummary(allData(allData.Year == 2024, :), 'Province', 'mean', 'NoiseLevel');

provList = unique(allData.Province);
val18 = nan(length(provList), 1);
val24 = nan(length(provList), 1);

for j = 1:length(provList)
    idx18 = pAvg2018.Province == provList(j);
    idx24 = pAvg2024.Province == provList(j);
    if any(idx18), val18(j) = pAvg2018.mean_NoiseLevel(idx18); end
    if any(idx24), val24(j) = pAvg2024.mean_NoiseLevel(idx24); end
end

[~, sortIdx] = sort(val24, 'ascend', 'MissingPlacement', 'first');
sortedProvs = provList(sortIdx);
sortedVal18 = val18(sortIdx);
sortedVal24 = val24(sortIdx);

b = barh([sortedVal18, sortedVal24], 'grouped', 'EdgeColor', 'k');
b(1).FaceColor = [0.5 0.7 0.9]; % 2018
b(2).FaceColor = [0.1 0.3 0.7]; % 2024
set(gca, 'ytick', 1:length(sortedProvs), 'yticklabel', string(sortedProvs));
lgd = legend(b, {'Rok 2018', 'Rok 2024'}, 'Location', 'southeast');
set(lgd, 'Color', 'k', 'EdgeColor', 'k');
formatChart('Porównanie średniego hałasu: 2018 vs 2024', 'dB', 'Województwo', '04_porownanie_2018_2024');

% 5. Dzień vs Noc
figure('Color', 'w');
dnData = allData(contains(string(allData.TimePeriod), {'Dzień','Noc'}, 'IgnoreCase', true), :);
dnAvg = groupsummary(dnData, 'TimePeriod', 'mean', 'NoiseLevel');
bar(categorical(dnAvg.TimePeriod), dnAvg.mean_NoiseLevel, 0.5, 'FaceColor', [0.4 0.4 0.4]);
formatChart('Średni hałas: Dzień vs Noc', 'Pora doby', 'dB', '05_dzien_noc');

% 6. Przekroczenia normy (>65dB)
figure('Color', 'w');
allData.IsOver = allData.NoiseLevel > 65;
overTable = groupsummary(allData, 'Year', 'sum', 'IsOver');
bar(overTable.Year, overTable.sum_IsOver, 'FaceColor', [0.8 0.2 0.2]);
formatChart('Liczba pomiarów > 65dB', 'Rok', 'Liczba', '06_przekroczenia');

% 7. MAPA GEOGRAFICZNA PUNKTÓW 
figure('Color', 'w', 'Position', [100 100 800 600]);
try
    
    geoscatter(allData.Lat, allData.Lon, 12, allData.NoiseLevel, 'filled');
    geobasemap('grayland'); 
    cb = colorbar; cb.Label.String = 'dB'; cb.Color = 'k'; colormap parula;
    formatChart('Mapa punktów pomiarowych na tle Polski', '', '', '07_mapa_geograficzna');
catch
    
    scatter(allData.Lon, allData.Lat, 10, allData.NoiseLevel, 'filled');
    cb = colorbar; cb.Label.String = 'dB'; cb.Color = 'k'; colormap parula;
    formatChart('Mapa punktów pomiarowych (bez tła geograficznego)', 'Długość geogr.', 'Szerokość geogr.', '07_mapa_zwykla');
end

% 8. Liczba pomiarów ogółem rocznie
figure('Color', 'w');
counts = groupsummary(allData, 'Year');
bar(counts.Year, counts.GroupCount, 'FaceColor', [0.2 0.5 0.4]);
formatChart('Liczba wykonanych pomiarów w latach', 'Rok', 'Sztuk', '08_liczba_pomiarow');

% 9. Max vs Średnia
figure('Color', 'w', 'Position', [100 100 800 600]);
yMax = groupsummary(allData, 'Year', 'max', 'NoiseLevel');
hold on;
b9 = bar(yAvg.Year, yAvg.mean_NoiseLevel, 'FaceColor', [0.85 0.85 0.85], 'EdgeColor', 'k');
p9 = plot(yAvg.Year, yMax.max_NoiseLevel, 'r-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
lgd = legend([b9, p9], {'Średnia', 'Maksimum'}, 'Location', 'northwest');
set(lgd, 'Color', 'k', 'EdgeColor', 'k');
formatChart('Wartości średnie i maksymalne', 'Rok', 'dB', '09_max_vs_avg');

% 10. Procent przekroczeń (Kołowy)
figure('Color', 'w');
p = pie([sum(allData.NoiseLevel > 65), sum(allData.NoiseLevel <= 65)]);
for k = 2:2:length(p), p(k).Color = 'k'; p(k).FontSize = 10; end
title('Udział pomiarów powyżej 65dB', 'FontSize', 14, 'Color', 'k');
lgd = legend({'Nienormatywne', 'W normie'}, 'Location', 'southoutside');
set(lgd, 'Color', 'w', 'EdgeColor', 'none');
set(gcf, 'InvertHardcopy', 'off', 'PaperPositionMode', 'auto');
saveas(gcf, 'wykresy/10_udzial_pie.png');

% 11. Trend Mazowieckie
figure('Color', 'w');
maz = allData(string(allData.Province) == "mazowieckie", :);
if ~isempty(maz)
    mAvg = groupsummary(maz, 'Year', 'mean', 'NoiseLevel');
    plot(mAvg.Year, mAvg.mean_NoiseLevel, '-ok', 'LineWidth', 2, 'MarkerFaceColor', 'b');
    formatChart('Trend hałasu: Mazowieckie', 'Rok', 'dB', '11_trend_mazowsze');
end

% 12. Liczba pomiarów wg województw
figure('Color', 'w');
pCount = groupsummary(allData, 'Province');
pCount = sortrows(pCount, 'GroupCount', 'ascend');
b2 = barh(pCount.GroupCount, 'FaceColor', 'flat');
b2.CData = cool(height(pCount)); 
set(gca, 'yticklabel', string(pCount.Province));
formatChart('Intensywność badań: Liczba pomiarów wg województw', 'Liczba', 'Województwo', '12_pomiarow_wg_wojewodztw');

% 13. Rozstęp roczny (Max-Min)
figure('Color', 'w');
yR = groupsummary(allData, 'Year', @(x) max(x)-min(x), 'NoiseLevel');
bar(yR.Year, yR.fun1_NoiseLevel, 'FaceColor', [0.5 0.2 0.5]);
formatChart('Różnica między Max a Min dB', 'Rok', 'Różnica', '13_rozstep');

% 14. MAPA GEOGRAFICZNA GĘSTOŚCI 
figure('Color', 'w', 'Position', [100 100 800 600]);
try
    
    geodensityplot(allData.Lat, allData.Lon, 'FaceColor', 'interp');
    geobasemap('grayland'); 
    formatChart('Zagęszczenie pomiarów na mapie Polski (Heatmapa)', 'Długość', 'Szerokość', '14_gestosc_mapa_geo');
catch
    
    binscatter(allData.Lon, allData.Lat, [35 35]);
    formatChart('Zagęszczenie pomiarów (brak mapy geograficznej)', 'Lon', 'Lat', '14_gestosc_mapa_zwykla');
end

% 15. Odchylenie Standardowe
figure('Color', 'w');
yS = groupsummary(allData, 'Year', 'std', 'NoiseLevel');
plot(yS.Year, yS.std_NoiseLevel, '-^k', 'LineWidth', 2, 'MarkerFaceColor', 'y');
formatChart('Zmienność wyników (Odch. Std)', 'Rok', 'dB', '15_zmiennosc');

fprintf('Gotowe! Wykresy 07 i 14 wygenerowano na interaktywnej mapie Polski.\n');

%% --- FUNKCJE POMOCNICZE ---

function cleanName = mapProvince(rawName)
    s = lower(string(rawName));
    cleanName = repmat("Nieznane", size(rawName));
    
    cleanName(contains(s, 'dolno')) = "dolnośląskie";
    cleanName(contains(s, 'kujaw')) = "kujawsko-pomorskie";
    cleanName(contains(s, 'lubels')) = "lubelskie";
    cleanName(contains(s, 'lubus')) = "lubuskie";
    cleanName(contains(s, 'dzki')) = "łódzkie";
    cleanName(contains(s, 'opolsk') & contains(s, 'm')) = "małopolskie";
    cleanName(contains(s, 'mazow')) = "mazowieckie";
    cleanName(contains(s, 'opolsk') & ~contains(s, 'm') & ~contains(s, 'wielk')) = "opolskie";
    cleanName(contains(s, 'podkarp')) = "podkarpackie";
    cleanName(contains(s, 'podlas')) = "podlaskie";
    cleanName(contains(s, 'pomorsk') & ~contains(s, 'kujaw') & ~contains(s, 'zach')) = "pomorskie";
    cleanName(contains(s, 'tokrzys')) = "świętokrzyskie";
    cleanName(contains(s, 'warmi') | contains(s, 'mazurs')) = "warmińsko-mazurskie";
    cleanName(contains(s, 'wielkop')) = "wielkopolskie";
    cleanName(contains(s, 'zachod')) = "zachodniopomorskie";
    
    cleanName(contains(s, 'skie') & cleanName == "Nieznane") = "śląskie";
end

function formatChart(tit, xl, yl, fileName)
    ax = gca;
    
   
    if isa(ax, 'matlab.graphics.axis.GeographicAxes')
        title(tit, 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
    else
        title(tit, 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
        if ~isempty(xl), xlabel(xl, 'FontSize', 11, 'Color', 'k'); end
        if ~isempty(yl), ylabel(yl, 'FontSize', 11, 'Rotation', 0, 'HorizontalAlignment', 'right', 'Color', 'k'); end
        set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.4 0.4 0.4], 'Box', 'on', 'LineWidth', 1.1);
        grid on;
    end
    
    
    set(gcf, 'InvertHardcopy', 'off', 'Color', 'w', 'PaperPositionMode', 'auto'); 
    saveas(gcf, ['wykresy/', fileName, '.png']);
end