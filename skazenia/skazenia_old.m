%% Wczytanie danych z plików CSV
files = dir('skazenia/data/*.csv');
data = table();

for i = 1:length(files)
    filepath = fullfile(files(i).folder, files(i).name);
    try
        T = readtable(filepath, ...
            ReadVariableNames=true, VariableNamingRule='preserve', ...
            Encoding='UTF-8', Delimiter=';', DecimalSeparator=',', ...
            TreatAsMissing={'< 2', '-'});
    catch
        T = readtable(filepath, ...
            ReadVariableNames=true, VariableNamingRule='preserve', ...
            Encoding='windows-1250', Delimiter=';', DecimalSeparator=',', ...
            TreatAsMissing={'< 2', '-'});
    end
    data = [data; T];
end

close all;

%% Ustandaryzowanie nazw kolumn
expectedVarNames = {
    'Punkt', 'Miejscowosc', 'DataPoboru', 'ObjetoscWodyL', 'OsadyDenneGsm', ...
    'MasaCs137G', 'GestoscGcm3', 'Cs137OsadyBqKg', 'NiepewnoscCs137OsadyBqKg', ...
    'Pu239240mBqKg', 'NiepewnoscPu239240mBqKg', 'Pu238mBqKg', ...
    'NiepewnoscPu238mBqKg', 'Pu238doPu239240', 'Cs137WodamBqL', ...
    'NiepewnoscCs137WodamBqL', 'Sr90WodamBqL', 'NiepewnoscSr90WodamBqL', ...
    'Sr90doCs137'};

if width(data) == numel(expectedVarNames)
    data.Properties.VariableNames = expectedVarNames;
else
    error('Liczba kolumn (%d) jest inna niz oczekiwane %d.', width(data), numel(expectedVarNames));
end

%% Konwersja typow
if iscell(data.Miejscowosc)
    data.Miejscowosc = string(data.Miejscowosc);
elseif ischar(data.Miejscowosc)
    data.Miejscowosc = string(cellstr(data.Miejscowosc));
end

data.Miejscowosc = strip(data.Miejscowosc);

if ~isdatetime(data.DataPoboru)
    data.DataPoboru = datetime(string(data.DataPoboru), 'InputFormat', 'dd.MM.yyyy', 'Format', 'yyyy-MM-dd');
end

data.Rok = year(data.DataPoboru);

%% Mapa punktow z podpisami miejscowosci (na starcie)
geo = jsondecode(fileread('skazenia/data/miejscowosci.geojson'));
features = geo.features;

nPoints = numel(features);
lons = NaN(nPoints, 1);
lats = NaN(nPoints, 1);
labels = strings(nPoints, 1);

for k = 1:nPoints
    coords = features(k).geometry.coordinates;
    lons(k) = coords(1);
    lats(k) = coords(2);
    labels(k) = string(features(k).properties.place_name);
end

geoTable = table(labels, lats, lons, 'VariableNames', {'Miejscowosc', 'Latitude', 'Longitude'});

figure(1);
gx = geoaxes;
geoscatter(gx, lats, lons, 60, 'filled', 'MarkerFaceColor', [0.10 0.45 0.85]);
title(gx, 'Punkty pomiarowe - lokalizacje');

try
    geobasemap(gx, 'streets-light');
catch
    geobasemap(gx, 'topographic');
end

hold(gx, 'on');
for k = 1:nPoints
    text(gx, lats(k) + 0.06, lons(k) + 0.06, labels(k), ...
        'FontSize', 9, 'Color', [0.15 0.15 0.15], ...
        'BackgroundColor', 'white', 'Margin', 1);
end
hold(gx, 'off');

latMargin = 0.8;
lonMargin = 1.0;
geolimits(gx, [min(lats) - latMargin, max(lats) + latMargin], ...
    [min(lons) - lonMargin, max(lons) + lonMargin]);

%% Podstawowe statystyki roczne
analysisVars = {'Cs137OsadyBqKg', 'Pu239240mBqKg', 'Pu238mBqKg', 'Cs137WodamBqL', 'Sr90WodamBqL'};
roczne = groupsummary(data, 'Rok', {'mean', 'median', 'std'}, analysisVars);

%% Ranking miejscowosci po srednim Cs-137 i Sr-90 w wodzie
miasta = groupsummary(data, 'Miejscowosc', 'mean', {'Cs137WodamBqL', 'Sr90WodamBqL'});
miasta = sortrows(miasta, 'mean_Cs137WodamBqL', 'descend');

miastaPelne = groupsummary(data, 'Miejscowosc', 'mean', analysisVars);
mapMiasta = innerjoin(geoTable, miastaPelne, 'Keys', 'Miejscowosc');

%% Wizualizacja trendow rocznych
figure(2);
tiledlayout(2,2, 'TileSpacing', 'compact');

nexttile;
plot(roczne.Rok, roczne.mean_Cs137WodamBqL, '-o', 'LineWidth', 1.6);
grid on;
xlabel('Rok', FontWeight='bold'); ylabel('Cs-137 w wodzie [mBq/L]', rotation=0, FontWeight='bold');
title('Srednia roczna Cs-137 w wodzie', FontSize=16);

nexttile;
plot(roczne.Rok, roczne.mean_Sr90WodamBqL, '-o', 'LineWidth', 1.6);
grid on;
xlabel('Rok'); ylabel('Sr-90 w wodzie [mBq/L]');
title('Srednia roczna Sr-90 w wodzie');

nexttile;
plot(roczne.Rok, roczne.mean_Cs137OsadyBqKg, '-o', 'LineWidth', 1.6);
grid on;
xlabel('Rok'); ylabel('Cs-137 w osadach [Bq/kg]');
title('Srednia roczna Cs-137 w osadach');

nexttile;
plot(roczne.Rok, roczne.mean_Pu239240mBqKg, '-o', 'LineWidth', 1.6);
grid on;
xlabel('Rok'); ylabel('Pu-239+240 [mBq/kg]');
title('Srednia roczna Pu-239+240 w osadach');

keyboard;

%% Korelacje miedzy glownymi wskaznikami
X = data{:, analysisVars};
[R, P] = corr(X, 'Rows', 'pairwise');

%% Top 10 miejscowosci - wykres slupkowy
topN = min(10, height(miasta));
topMiasta = miasta(1:topN, :);

figure(3);
tiledlayout(1,2, 'TileSpacing', 'compact');

nexttile;
barh(categorical(topMiasta.Miejscowosc), topMiasta.mean_Cs137WodamBqL);
grid on;
xlabel('Srednie Cs-137 [mBq/L]'); ylabel('Miejscowosc');
title('Top miejscowosci: Cs-137 w wodzie');
set(gca, 'YDir', 'reverse');

nexttile;
barh(categorical(topMiasta.Miejscowosc), topMiasta.mean_Sr90WodamBqL);
grid on;
xlabel('Srednie Sr-90 [mBq/L]'); ylabel('Miejscowosc');
title('Top miejscowosci: Sr-90 w wodzie');
set(gca, 'YDir', 'reverse');

%% Rozklady danych - histogramy
figure(4);
tiledlayout(2,2, 'TileSpacing', 'compact');

nexttile;
histogram(data.Cs137WodamBqL, 'NumBins', 20);
grid on;
xlabel('Cs-137 w wodzie [mBq/L]'); ylabel('Liczba pomiarow');
title('Rozklad Cs-137 w wodzie');

nexttile;
histogram(data.Sr90WodamBqL, 'NumBins', 20);
grid on;
xlabel('Sr-90 w wodzie [mBq/L]'); ylabel('Liczba pomiarow');
title('Rozklad Sr-90 w wodzie');

nexttile;
histogram(data.Cs137OsadyBqKg, 'NumBins', 20);
grid on;
xlabel('Cs-137 w osadach [Bq/kg]'); ylabel('Liczba pomiarow');
title('Rozklad Cs-137 w osadach');

nexttile;
histogram(data.Pu239240mBqKg, 'NumBins', 20);
grid on;
xlabel('Pu-239+240 [mBq/kg]'); ylabel('Liczba pomiarow');
title('Rozklad Pu-239+240');

%% Macierz korelacji - wykres ciepla
figure(5);
hm = heatmap(analysisVars, analysisVars, R, 'Colormap', parula);
hm.Title = 'Korelacje Pearsona miedzy wskaznikami';
hm.CellLabelFormat = '%.2f';

% maska istotnosci: p >= 0.05 oznacza brak istotnosci statystycznej
figure(6);
imagesc(P >= 0.05);
colormap(gray);
colorbar;
axis equal tight;
xticks(1:numel(analysisVars)); yticks(1:numel(analysisVars));
xticklabels(analysisVars); yticklabels(analysisVars);
xtickangle(30);
title('Brak istotnosci korelacji (1 = p >= 0.05)');

%% Mapa tematyczna: kolor = Cs-137 w wodzie, rozmiar = Sr-90 w wodzie
figure(7);
gx2 = geoaxes;

markerSizes = 80 * ones(height(mapMiasta), 1);
srVals = mapMiasta.mean_Sr90WodamBqL;
if any(isfinite(srVals))
    srMin = min(srVals, [], 'omitnan');
    srMax = max(srVals, [], 'omitnan');
    if srMax > srMin
        markerSizes = 50 + 250 * (srVals - srMin) / (srMax - srMin);
    end
end

geoscatter(gx2, mapMiasta.Latitude, mapMiasta.Longitude, markerSizes, ...
    mapMiasta.mean_Cs137WodamBqL, 'filled');
title(gx2, 'Mapa tematyczna: Cs-137 i Sr-90 w wodzie');
try
    geobasemap(gx2, 'streets-light');
catch
    geobasemap(gx2, 'topographic');
end
colormap(gx2, turbo);
cb = colorbar;
cb.Label.String = 'Srednie Cs-137 w wodzie [mBq/L]';
hold(gx2, 'on');
for k = 1:height(mapMiasta)
    text(gx2, mapMiasta.Latitude(k) + 0.05, mapMiasta.Longitude(k) + 0.05, mapMiasta.Miejscowosc(k), ...
        'FontSize', 8, 'BackgroundColor', 'white', 'Margin', 1);
end
hold(gx2, 'off');
geolimits(gx2, [min(mapMiasta.Latitude) - latMargin, max(mapMiasta.Latitude) + latMargin], ...
    [min(mapMiasta.Longitude) - lonMargin, max(mapMiasta.Longitude) + lonMargin]);

%% Wykresy pudełkowe po latach
figure(8);
tiledlayout(2,2, 'TileSpacing', 'compact');

rokCat = categorical(data.Rok);

nexttile;
boxchart(rokCat, data.Cs137WodamBqL);
grid on;
xlabel('Rok'); ylabel('Cs-137 w wodzie [mBq/L]');
title('Rozklad Cs-137 w wodzie wg lat');

nexttile;
boxchart(rokCat, data.Sr90WodamBqL);
grid on;
xlabel('Rok'); ylabel('Sr-90 w wodzie [mBq/L]');
title('Rozklad Sr-90 w wodzie wg lat');

nexttile;
boxchart(rokCat, data.Cs137OsadyBqKg);
grid on;
xlabel('Rok'); ylabel('Cs-137 w osadach [Bq/kg]');
title('Rozklad Cs-137 w osadach wg lat');

nexttile;
boxchart(rokCat, data.Pu239240mBqKg);
grid on;
xlabel('Rok'); ylabel('Pu-239+240 [mBq/kg]');
title('Rozklad Pu-239+240 wg lat');

%% Scatter zaleznosci miedzy radionuklidami w wodzie
figure(9);
scatter(data.Cs137WodamBqL, data.Sr90WodamBqL, 40, data.Rok, 'filled');
grid on;
xlabel('Cs-137 w wodzie [mBq/L]');
ylabel('Sr-90 w wodzie [mBq/L]');
title('Zaleznosc Cs-137 vs Sr-90 w wodzie');
cb = colorbar;
cb.Label.String = 'Rok';

%% Area chart dla srednich rocznych w wodzie
figure(10);
yyaxis left;
area(roczne.Rok, roczne.mean_Cs137WodamBqL, 'FaceAlpha', 0.45);
ylabel('Cs-137 w wodzie [mBq/L]');

yyaxis right;
plot(roczne.Rok, roczne.mean_Sr90WodamBqL, '-o', 'LineWidth', 1.8);
ylabel('Sr-90 w wodzie [mBq/L]');

grid on;
xlabel('Rok');
title('Srednie roczne radionuklidy w wodzie');

%% Heatmapa rok x miejscowosc dla Cs-137 w wodzie
heatPlaces = unique(data.Miejscowosc, 'stable');
heatYears = unique(data.Rok);
heatValues = NaN(numel(heatPlaces), numel(heatYears));

for rowIdx = 1:numel(heatPlaces)
    for colIdx = 1:numel(heatYears)
        mask = data.Miejscowosc == heatPlaces(rowIdx) & data.Rok == heatYears(colIdx);
        if any(mask)
            heatValues(rowIdx, colIdx) = mean(data.Cs137WodamBqL(mask), 'omitnan');
        end
    end
end

figure(11);
hm2 = heatmap(string(heatYears), heatPlaces, heatValues, 'Colormap', hot);
hm2.Title = 'Cs-137 w wodzie: srednie rok x miejscowosc';
hm2.XLabel = 'Rok';
hm2.YLabel = 'Miejscowosc';
hm2.CellLabelColor = 'none';

%% Wykres slupkowy pionowy dla najwyzszych srednich Cs-137 w wodzie
figure(12);
bar(categorical(topMiasta.Miejscowosc), topMiasta.mean_Cs137WodamBqL, 'FaceColor', [0.20 0.55 0.85]);
grid on;
xlabel('Miejscowosc');
ylabel('Srednie Cs-137 w wodzie [mBq/L]');
title('Top miejscowosci: Cs-137 w wodzie');
xtickangle(35);

%% Wykres stem dla sredniego Pu-239+240 w osadach
puMiasta = sortrows(miastaPelne(:, {'Miejscowosc', 'mean_Pu239240mBqKg'}), 'mean_Pu239240mBqKg', 'descend');
topPu = puMiasta(1:min(12, height(puMiasta)), :);

figure(13);
stem(topPu.mean_Pu239240mBqKg, 'filled', 'LineWidth', 1.4);
grid on;
xlabel('Pozycja w rankingu');
ylabel('Srednie Pu-239+240 [mBq/kg]');
title('Ranking miejscowosci: Pu-239+240 w osadach');
xticks(1:height(topPu));
xticklabels(cellstr(topPu.Miejscowosc));
xtickangle(35);

%% Boxplot dla top miejscowosci po Cs-137 w wodzie
topPlaceNames = topMiasta.Miejscowosc;
topMask = ismember(data.Miejscowosc, topPlaceNames);

figure(14);
boxchart(categorical(data.Miejscowosc(topMask), topPlaceNames), data.Cs137WodamBqL(topMask));
grid on;
xlabel('Miejscowosc');
ylabel('Cs-137 w wodzie [mBq/L]');
title('Rozklad Cs-137 w wodzie dla top miejscowosci');
xtickangle(35);

%% Druga mapa tematyczna: kolor = Cs-137 w osadach
figure(15);
gx3 = geoaxes;
geoscatter(gx3, mapMiasta.Latitude, mapMiasta.Longitude, 90, mapMiasta.mean_Cs137OsadyBqKg, 'filled');
title(gx3, 'Mapa tematyczna: Cs-137 w osadach');
try
    geobasemap(gx3, 'satellite');
catch
    geobasemap(gx3, 'topographic');
end
colormap(gx3, parula);
cb = colorbar;
cb.Label.String = 'Srednie Cs-137 w osadach [Bq/kg]';
geolimits(gx3, [min(mapMiasta.Latitude) - latMargin, max(mapMiasta.Latitude) + latMargin], ...
    [min(mapMiasta.Longitude) - lonMargin, max(mapMiasta.Longitude) + lonMargin]);