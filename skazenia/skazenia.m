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

%% Sanitizacja kolumn pomiarowych (konwersja string -> double gdy readtable nie parsuje poprawnie)
measureVars = {'ObjetoscWodyL', 'OsadyDenneGsm', 'MasaCs137G', 'GestoscGcm3', ...
    'Cs137OsadyBqKg', 'NiepewnoscCs137OsadyBqKg', ...
    'Pu239240mBqKg', 'NiepewnoscPu239240mBqKg', 'Pu238mBqKg', ...
    'NiepewnoscPu238mBqKg', 'Pu238doPu239240', 'Cs137WodamBqL', ...
    'NiepewnoscCs137WodamBqL', 'Sr90WodamBqL', 'NiepewnoscSr90WodamBqL', 'Sr90doCs137'};

for vIdx = 1:numel(measureVars)
    col = data.(measureVars{vIdx});
    if ~isnumeric(col)
        col = strrep(string(col), ',', '.');
        data.(measureVars{vIdx}) = str2double(col);
    end
end

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

f = figure(1);
f.Position = [0 500 1200 600];
f.Visible = "off";
f.Theme = 'light';

gx = geoaxes;
geoscatter(gx, lats, lons, 60, 'filled', ...
    'MarkerFaceColor', [0.90 0.35 0.10], 'MarkerEdgeColor', [1 1 1], 'LineWidth', 0.8);
title(gx, 'Punkty pomiarowe - lokalizacje', FontSize=16);

geobasemap('topographic')
gx.LatitudeAxis.Visible = 'off';
gx.LongitudeAxis.Visible = 'off';

hold(gx, 'on');
for k = 1:nPoints
    latOffset = 0.2;
    lonOffset = 0;
    placeName = lower(labels(k));

    if contains(placeName, "pułtusk") || contains(placeName, "pultusk")
        latOffset = 0.28;
        lonOffset = -0.18;
    elseif contains(placeName, "wyszków") || contains(placeName, "wyszkow")
        latOffset = 0.12;
        lonOffset = 0.16;
    end

    text(gx, lats(k) + latOffset, lons(k) + lonOffset, labels(k), ...
        'FontSize', 9, 'Color', [0.15 0.15 0.15], ...
        'BackgroundColor', [0.8,0.8,0.8], 'Margin', 1);
end
hold(gx, 'off');

latMargin = 0.8;
lonMargin = 1.0;
geolimits(gx, [min(lats) - latMargin, max(lats) + latMargin], ...
    [min(lons) - lonMargin, max(lons) + lonMargin]);



exportgraphics(f, '1.png', BackgroundColor='#f0efe9')
close(f)

%% Podstawowe statystyki roczne
analysisVars = {'Cs137OsadyBqKg', 'Pu239240mBqKg', 'Pu238mBqKg', 'Cs137WodamBqL', 'Sr90WodamBqL'};
roczne = groupsummary(data, 'Rok', {'mean', 'median', 'std'}, analysisVars);

%% Ranking miejscowosci po srednim Cs-137 i Sr-90 w wodzie
miasta = groupsummary(data, 'Miejscowosc', 'mean', {'Cs137WodamBqL', 'Sr90WodamBqL'});
miasta = sortrows(miasta, 'mean_Cs137WodamBqL', 'descend');

miastaPelne = groupsummary(data, 'Miejscowosc', 'mean', analysisVars);
mapMiasta = innerjoin(geoTable, miastaPelne, 'Keys', 'Miejscowosc');

%% Wizualizacja trendow rocznych - w wodzie
f = figure(2);
f.Position = [0 500 1200 600];
f.Visible = "off";
f.Theme = 'light';

ax = axes(f);
hold(ax, 'on');
plot(ax, roczne.Rok, roczne.mean_Cs137WodamBqL, '-o', 'LineWidth', 1.6, DisplayName='^{137}Cs [mBq/L]');
plot(ax, roczne.Rok, roczne.mean_Sr90WodamBqL, '-o', 'LineWidth', 1.6, DisplayName='^{90}Sr [mBq/L]');

grid(ax, 'on');
xlabel(ax, 'Rok', FontWeight='bold');
ylabel(ax, 'Stężenie izotopów', rotation=0, FontWeight='bold');
title(ax, 'Srednie roczne stężenie promieniotwórcze izotopów w wodzie', FontSize=16);
legend(ax, Location='northwest');
ax.Units = 'normalized';
ax.Position = [0.10 0.18 0.85 0.74];

exportgraphics(f, '2.png', BackgroundColor='#f0efe9')
close(f);

%% Wizualizacja trendow rocznych - osady
f = figure(3);
f.Position = [0 500 1200 600];
f.Visible = "off";
f.Theme = 'light';

ax = axes(f);
hold(ax, 'on');
plot(ax, roczne.Rok, roczne.mean_Cs137OsadyBqKg, '-o', 'LineWidth', 1.6, DisplayName='^{137}Cs [Bq/kg]');
plot(ax, roczne.Rok, roczne.mean_Pu239240mBqKg, '-o', 'LineWidth', 1.6, DisplayName='^{239}Pu+^{240}Pu [mBq/kg]');
plot(ax, roczne.Rok, roczne.mean_Pu238mBqKg, '-o', 'LineWidth', 1.6, DisplayName='^{238}Pu [mBq/kg]');

grid(ax, 'on');
xlabel(ax, 'Rok', FontWeight='bold');
ylabel(ax, 'Stężenie izotopów', rotation=0, FontWeight='bold');
title(ax, 'Srednie roczne stężenie promieniotwórcze izotopów w osadach dennych', FontSize=16);
legend(ax, Location='northwest');
ax.Units = 'normalized';
ax.Position = [0.10 0.18 0.85 0.74];

exportgraphics(f, '3.png', BackgroundColor='#f0efe9')
close(f);

%% Korelacje miedzy glownymi wskaznikami
X = data{:, analysisVars};
[R, P] = corr(X, 'Rows', 'pairwise');

%% Top 10 miejscowosci - wykres slupkowy
topN = min(10, height(miasta));
topMiasta = miasta(1:topN, :);

%% Violin plots - rozklad stezen w wodzie wg wszystkich miejscowosci
f = figure(4);
f.Position = [0 500 1400 580];
f.Visible = "off";
f.Theme = 'light';
tl4 = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl4, 'Rozkład stężeń izotopów w wodzie wg miejscowości', 'FontSize', 14, 'FontWeight', 'bold');

miejscowoscCat = categorical(data.Miejscowosc, unique(data.Miejscowosc, 'stable'));


nexttile;
violinplot(miejscowoscCat, data.Cs137WodamBqL, Orientation="horizontal");
grid on;
ylabel(tl4, 'Miejscowość', rotation=0, FontWeight='bold');
xlabel('^{137}Cs [mBq/L]', FontWeight='bold');
title('Stężenie ^{137}Cs w wodzie', FontSize=16);
xtickangle(40);

nexttile;
violinplot(miejscowoscCat,data.Sr90WodamBqL, Orientation="horizontal");
grid on;
xlabel('^{90}Sr [mBq/L]', FontWeight='bold');
title('Stężenie ^{90}Sr w wodzie', FontSize=16);
xtickangle(40);

exportgraphics(f, '4.png', BackgroundColor='#f0efe9')
close(f);

%% Violin plots - rozklad stezen w osadach wg wszystkich miejscowosci
f = figure(5);
f.Position = [0 500 1400 580];
f.Visible = "off";
f.Theme = 'light';
tl5 = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl5, 'Rozkład stężeń izotopów w osadach wg miejscowości', 'FontSize', 14, 'FontWeight', 'bold');

nexttile;
violinplot(miejscowoscCat, data.Cs137OsadyBqKg, Orientation="horizontal");
grid on;
ylabel(tl5, 'Miejscowość', rotation=0, FontWeight='bold');
xlabel('^{137}Cs [Bq/kg]', 'FontWeight', 'bold');
title('^{137}Cs w osadach');
xtickangle(40);

nexttile;
violinplot(miejscowoscCat, data.Pu239240mBqKg, Orientation="horizontal");
grid on;

xlabel('^{239+240}Pu [mBq/kg]', FontWeight='bold');
title('^{239+240}Pu w osadach', FontSize=16);
xtickangle(40);

exportgraphics(f, '5.png', BackgroundColor='#f0efe9')
close(f);

%% Ostatni violin plot
f = figure(6);
f.Position = [0 500 1200 600];
f.Visible = "off";
f.Theme = 'light';

violinplot(miejscowoscCat, data.Pu238mBqKg, Orientation="horizontal");
grid on;
ylabel('Miejscowość', rotation=0, FontWeight='bold');
xlabel('^{238}Pu [mBq/kg]', FontWeight='bold');
title('^{238}Pu w osadach', FontSize=16);
xtickangle(40);

exportgraphics(f, '6.png', BackgroundColor='#f0efe9')
close(f);

%% Rozklady danych - histogramy (woda)
f = figure(7);
f.Position = [0 500 1200 600];
f.Visible = "off";
f.Theme = 'light';
tiledlayout(2,1, 'TileSpacing', 'compact');

nexttile;
histogram(data.Cs137WodamBqL, 'NumBins', 20);
grid on;
xlabel('Cs-137 w wodzie [mBq/L]', rotation=0, FontWeight='bold'); 
ylabel('Liczba pomiarow', FontWeight='bold');
title('Rozklad Cs-137 w wodzie');

nexttile;
histogram(data.Sr90WodamBqL, 'NumBins', 20);
grid on;
xlabel('Sr-90 w wodzie [mBq/L]', rotation=0, FontWeight='bold');
ylabel('Liczba pomiarow', FontWeight='bold');
title('Rozklad Sr-90 w wodzie');

%% Rozklady danych - histogramy (osady)
f = figure(7);
f.Position = [0 500 1200 600];
f.Visible = "off";
f.Theme = 'light';
tiledlayout(2,1, 'TileSpacing', 'compact');

nexttile;
histogram(data.Cs137OsadyBqKg, 'NumBins', 20);
grid on;
xlabel('Cs-137 w osadach [Bq/kg]', rotation=0, FontWeight='bold');
ylabel('Liczba pomiarow', FontWeight='bold');
title('Rozklad Cs-137 w osadach');

nexttile;
histogram(data.Pu239240mBqKg, 'NumBins', 20);
grid on;
xlabel('Pu-239+240 [mBq/kg]', rotation=0, FontWeight='bold');
ylabel('Liczba pomiarow', FontWeight='bold');
title('Rozklad Pu-239+240');

exportgraphics(f, '7.png', BackgroundColor='#f0efe9')
close(f);

%% Macierz korelacji - wykres ciepla
figure(8);
hm = heatmap(analysisVars, analysisVars, R, 'Colormap', parula);
hm.Title = 'Korelacje Pearsona miedzy wskaznikami';
hm.CellLabelFormat = '%.2f';

% maska istotnosci: p >= 0.05 oznacza brak istotnosci statystycznej
figure(9);
imagesc(P >= 0.05);
colormap(gray);
colorbar;
axis equal tight;
xticks(1:numel(analysisVars)); yticks(1:numel(analysisVars));
xticklabels(analysisVars); yticklabels(analysisVars);
xtickangle(30);
title('Brak istotnosci korelacji (1 = p >= 0.05)');

%% Wykresy pudełkowe po latach
figure(10);
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
xlabel('Rok'); ylabel('Pu-239+240 osadach [mBq/kg]');
title('Rozklad Pu-239+240 wg lat');

%% Scatter zaleznosci miedzy radionuklidami w wodzie
figure(11);
scatter(data.Cs137WodamBqL, data.Sr90WodamBqL, 40, data.Rok, 'filled');
grid on;
xlabel('Cs-137 w wodzie [mBq/L]');
ylabel('Sr-90 w wodzie [mBq/L]');
title('Zaleznosc Cs-137 vs Sr-90 w wodzie');
cb = colorbar;
cb.Label.String = 'Rok';

%% Area chart dla srednich rocznych w wodzie
figure(12);
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

figure(13);
hm2 = heatmap(string(heatYears), heatPlaces, heatValues, 'Colormap', hot);
hm2.Title = 'Cs-137 w wodzie: srednie rok x miejscowosc';
hm2.XLabel = 'Rok';
hm2.YLabel = 'Miejscowosc';
hm2.CellLabelColor = 'none';

%% Wykres slupkowy pionowy dla najwyzszych srednich Cs-137 w wodzie
figure(14);
bar(categorical(topMiasta.Miejscowosc), topMiasta.mean_Cs137WodamBqL, 'FaceColor', [0.20 0.55 0.85]);
grid on;
xlabel('Miejscowosc');
ylabel('Srednie Cs-137 w wodzie [mBq/L]');
title('Top miejscowosci: Cs-137 w wodzie');
xtickangle(35);

%% Wykres stem dla sredniego Pu-239+240 w osadach
puMiasta = sortrows(miastaPelne(:, {'Miejscowosc', 'mean_Pu239240mBqKg'}), 'mean_Pu239240mBqKg', 'descend');
topPu = puMiasta(1:min(12, height(puMiasta)), :);

figure(15);
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

figure(16);
boxchart(categorical(data.Miejscowosc(topMask), topPlaceNames), data.Cs137WodamBqL(topMask));
grid on;
xlabel('Miejscowosc');
ylabel('Cs-137 w wodzie [mBq/L]');
title('Rozklad Cs-137 w wodzie dla top miejscowosci');
xtickangle(35);

%% Druga mapa tematyczna: kolor = Cs-137 w osadach
figure(17);
gx3 = geoaxes;
geoscatter(gx3, mapMiasta.Latitude, mapMiasta.Longitude, 90, mapMiasta.mean_Cs137OsadyBqKg, 'filled');
title(gx3, 'Mapa tematyczna: Cs-137 w osadach');
try
    geobasemap(gx3, 'satellite');
catch
    geobasemap(gx3, 'topographic');
end
gx3.LatitudeAxis.Visible = 'off';
gx3.LongitudeAxis.Visible = 'off';
colormap(gx3, parula);
cb = colorbar;
cb.Label.String = 'Srednie Cs-137 w osadach [Bq/kg]';
geolimits(gx3, [min(mapMiasta.Latitude) - latMargin, max(mapMiasta.Latitude) + latMargin], ...
    [min(mapMiasta.Longitude) - lonMargin, max(mapMiasta.Longitude) + lonMargin]);