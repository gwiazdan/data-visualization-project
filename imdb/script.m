% Kompleksowa analiza IMDb - Każdy wykres w osobnej figurze (11 wykresów)
clear; clc; close all;

% 1. Ścieżki do plików
dataFolder = 'imdb/data/';
fileBasics = fullfile(dataFolder, 'title.basics.tsv');
fileRatings = fullfile(dataFolder, 'title.ratings.tsv');
fileEpisode = fullfile(dataFolder, 'title.episode.tsv');

% 2. Import title.basics.tsv
disp('Wczytywanie title.basics.tsv');
optsB = detectImportOptions(fileBasics, 'FileType', 'text', 'Delimiter', '\t');
optsB = setvaropts(optsB, optsB.VariableNames, 'TreatAsMissing', '\N');
optsB = setvartype(optsB, {'tconst', 'titleType', 'primaryTitle', 'genres'}, 'string');
optsB = setvartype(optsB, {'startYear', 'runtimeMinutes', 'isAdult'}, 'double');
basics = readtable(fileBasics, optsB);

% 3. Import title.ratings.tsv
disp('Wczytywanie title.ratings.tsv...');
optsR = detectImportOptions(fileRatings, 'FileType', 'text', 'Delimiter', '\t');
optsR = setvaropts(optsR, optsR.VariableNames, 'TreatAsMissing', '\N');
optsR = setvartype(optsR, 'tconst', 'string');
optsR = setvartype(optsR, {'averageRating', 'numVotes'}, 'double');
ratings = readtable(fileRatings, optsR);

% 4. Import title.episode.tsv
disp('Wczytywanie title.episode.tsv...');
optsE = detectImportOptions(fileEpisode, 'FileType', 'text', 'Delimiter', '\t');
optsE = setvaropts(optsE, optsE.VariableNames, 'TreatAsMissing', '\N');
optsE = setvartype(optsE, {'tconst', 'parentTconst'}, 'string');
optsE = setvartype(optsE, {'seasonNumber', 'episodeNumber'}, 'double');
episodes = readtable(fileEpisode, optsE);

% 5. Łączenie i czyszczenie danych
disp('Przetwarzanie danych...');
dataAll = innerjoin(basics, ratings, 'Keys', 'tconst');

% Ekstrakcja wiodącego gatunku
dataAll.primaryGenre = extractBefore(dataAll.genres + ",", ",");
% Odfiltrowanie błędów dla isAdult
dataAll = dataAll(dataAll.isAdult == 0 | dataAll.isAdult == 1, :);

moviesOnly = dataAll(dataAll.titleType == "movie", :);

%% Wykresy
disp('Generowanie wykresów w osobnych oknach...');

% --- WYKRES 1 ---
figure('Name', '1. Liczba produkcji rocznie');
validYears = dataAll.startYear(~isnan(dataAll.startYear) & dataAll.startYear <= 2026);
histogram(validYears, 'BinMethod', 'integers', 'FaceColor', '#0072BD', 'BinWidth', 1);
title('Liczba wyprodukowanych tytułów rocznie');
xlabel('Rok'); ylabel('Ilość'); grid on; xlim([1900 2026]);

% --- WYKRES 2 ---
figure('Name', '2. Rozkład czasu trwania (Filmy)');
validRuntimes = moviesOnly.runtimeMinutes(~isnan(moviesOnly.runtimeMinutes) & moviesOnly.runtimeMinutes > 30 & moviesOnly.runtimeMinutes < 240);
histogram(validRuntimes, 'BinWidth', 5, 'FaceColor', '#D95319');
title('Rozkład czasu trwania filmów');
xlabel('Czas trwania (minuty)'); ylabel('Częstotliwość'); grid on; xticks(40:5:200); xlim([40 200]);

% --- WYKRES 3 ---
figure('Name', '3. Średnia ocena filmów w czasie');
yearsUnique = unique(validYears);
avgRatingYear = arrayfun(@(y) mean(moviesOnly.averageRating(moviesOnly.startYear == y), 'omitnan'), yearsUnique);
validY_Rating = yearsUnique >= 1920;
plot(yearsUnique(validY_Rating), avgRatingYear(validY_Rating), '-', 'LineWidth', 2, 'Color', '#EDB120', 'MarkerFaceColor', '#EDB120');
title('Średnia ocena filmów wg roku produkcji');
xlabel('Rok'); ylabel('Średnia ocena'); grid on; ylim([4.5 7.5]); xlim([1920 2026]);

% --- WYKRES 4 ---
figure('Name', '4. Oceny: Dla dorosłych vs Reszta');
isAdultCat = categorical(dataAll.isAdult, [0 1], {'Dla wszystkich', 'Tylko dla dorosłych (18+)'});
boxchart(isAdultCat, dataAll.averageRating, 'MarkerStyle', 'none');
title('Porównanie ocen: Filmy dla dorosłych a reszta');
ylabel('Ocena IMDb'); grid on;

% --- WYKRES 5 ---
figure('Name', '5. Oceny wg rodzaju tytułu (TOP 6)');
[typeCounts, typeNames] = groupcounts(dataAll.titleType);
[~, sortIdx] = sort(typeCounts, 'descend');
top6Types = typeNames(sortIdx(1:min(6, length(typeNames))));
typeMask = ismember(dataAll.titleType, top6Types);
boxchart(categorical(dataAll.titleType(typeMask)), dataAll.averageRating(typeMask), 'MarkerStyle', 'none');
title('Rozkład ocen dla 6 najpopularniejszych typów produkcji');
ylabel('Ocena IMDb'); grid on;

% --- WYKRES 6 ---
figure('Name', '6. Liczba Głosów vs Ocena (Skala Log)');
popData = dataAll(dataAll.numVotes > 1000, :);
scatter(popData.averageRating, log10(popData.numVotes), 5, 'filled', 'MarkerFaceAlpha', 0.5);
title('Zależność popularności (liczby głosów) od oceny');
xlabel('Średnia ocena'); ylabel('Liczba głosów (log10)'); grid on;

% --- WYKRES 7 ---
% Przetwarzanie odcinków dla seriali
epStats = groupsummary(episodes, 'parentTconst', 'max', 'seasonNumber');
figure('Name', '7. Rozkład liczby odcinków w serialach');
epCounts = epStats.GroupCount;
histogram(epCounts(epCounts <= 100), 'BinWidth', 2, 'FaceColor', '#77AC30');
title('Rozkład całkowitej liczby odcinków w serialach');
xlabel('Ilość odcinków'); ylabel('Liczba seriali'); grid on; xlim([0, 100]);

% --- WYKRES 8 ---
figure('Name', '8. Rozkład liczby sezonów w serialach');
maxSeasons = epStats.max_seasonNumber;
histogram(maxSeasons(maxSeasons > 0 & maxSeasons <= 20), 'BinMethod', 'integers', 'FaceColor', '#4DBEEE', 'BinWidth', 1);
title('Rozkład maksymalnej liczby sezonów w serialach');
xlabel('Ilość sezonów'); ylabel('Liczba seriali'); grid on; xlim([1, 20]);

% --- WYKRES 9 ---
figure('Name', '9. Top 10 najpopularniejszych gatunków');
genreCounts = tabulate(categorical(dataAll.primaryGenre));
genreCounts(strcmp(genreCounts(:,1), '<missing>'), :) = [];
[~, sortIdx] = sort(cell2mat(genreCounts(:,2)), 'descend');
top10Genres = genreCounts(sortIdx(1:10), 1);
top10Counts = cell2mat(genreCounts(sortIdx(1:10), 2));
barh(categorical(top10Genres, top10Genres), top10Counts, 'FaceColor', '#A2142F');
set(gca, 'YDir', 'reverse');
title('Top 10 najczęściej występujących gatunków');
xlabel('Liczba tytułów'); grid on;

% --- WYKRES 10 ---
figure('Name', '10. Rozkład ocen TOP 10 gatunków');
genreMask = ismember(dataAll.primaryGenre, string(top10Genres));

catGenres = categorical(dataAll.primaryGenre(genreMask), string(top10Genres));
boxchart(catGenres, dataAll.averageRating(genreMask), 'BoxFaceColor', '#0072BD', 'MarkerStyle', 'none');

title('Rozkład ocen dla Top 10 najpopularniejszych gatunków');
xlabel('Gatunek'); 
ylabel('Ocena IMDb'); 
grid on;

% --- WYKRES 11: Średni czas trwania filmu rocznie ---
figure('Name', '11. Średni czas trwania filmu rocznie');
avgRuntimeYear = arrayfun(@(y) mean(moviesOnly.runtimeMinutes(moviesOnly.startYear == y), 'omitnan'), yearsUnique);
validY_Runtime = yearsUnique >= 1920 & yearsUnique <= 2026;
plot(yearsUnique(validY_Runtime), avgRuntimeYear(validY_Runtime), '-', 'LineWidth', 2, 'Color', '#7E2F8E', 'MarkerFaceColor', '#7E2F8E');
title('Średni czas trwania filmu kinowego na przestrzeni lat');
xlabel('Rok'); ylabel('Średni czas trwania (minuty)'); grid on; xlim([1920, 2027]); ylim([75, 110]);

outputFolder = fullfile('imdb', 'plots');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

allFigures = findall(0, 'Type', 'figure');

[~, idx] = sort([allFigures.Number]);
sortedFigures = allFigures(idx);

for i = 1:length(sortedFigures)
    currentFig = sortedFigures(i);
    
    safeName = matlab.lang.makeValidName(currentFig.Name);
    fileName = fullfile(outputFolder, sprintf('wykres_%02d_%s.png', i, safeName));
    
    exportgraphics(currentFig, fileName, 'Resolution', 300);
    
    fprintf('Zapisano: %s\n', fileName);
end