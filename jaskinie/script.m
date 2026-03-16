%% Wczytanie danych z pliku Shapefile
filename = 'jaskinie/data/cbdg_srodowisko_jaskinie_2026_03_06.shp';
jaskinie = shaperead(filename);

close all;

% Wyciągnięcie odpowiednich danych do tablic
dlugosc = [jaskinie.DLUGOSC];
glebokosc = [jaskinie.GLEBOKOSC];
przewyzsze = [jaskinie.PRZEWYZSZE];
deniwelacja = [jaskinie.DENIWELACJ];
osuwiskowa = [jaskinie.OSUWISKOWA];
nazwy = {jaskinie.NAZWA};
regiony = {jaskinie.REGION};
wlasciciel = {jaskinie.WLASCICIEL};

liczba_jaskin = length(jaskinie);

%% WIZUALIZACJA 1: Rozkład długości jaskiń (histogram dla jaskiń do 100m)
f = figure(1);
f.Position = [0 500 1200 600];
dlugosc_filtr = dlugosc(dlugosc > 0 & dlugosc <= 100); 
histogram(dlugosc_filtr, 'BinWidth', 5);
title('Częstotliwość występowania jaskiń o danej długości (do 100 m)', 'FontSize', 16);
xlabel('Długość jaskini (m)', 'FontWeight', 'bold');
ylabel('Ilość jaskiń', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic1.png', BackgroundColor='#f0efe9')

%% WIZUALIZACJA 2: Wykres słupkowy dla 10 najdłuższych jaskiń
f = figure(2);
f.Position = [0 500 1200 600];
[posortowane_dlugosci, indeksy_dl] = sort(dlugosc, 'descend');
top10_dlugosci = posortowane_dlugosci(1:10) ./ 1000;
top10_nazwy_dl = nazwy(indeksy_dl(1:10));

bar(top10_dlugosci);
set(gca, 'XTickLabel', top10_nazwy_dl);
title('10 najdłuższych jaskiń w Polsce', 'FontSize', 16);
xlabel('Nazwa jaskini', 'FontWeight', 'bold');
ylabel('Długość (km)', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic2.png', BackgroundColor='#f0efe9')

%% WIZUALIZACJA 3: Rozkład głębokości jaskiń
f = figure(3);
f.Position = [0 500 1200 600];
glebokosc_filtr = glebokosc(glebokosc > 0 & glebokosc <= 50);
histogram(glebokosc_filtr, 'BinWidth', 2, 'FaceColor', [0.4660 0.6740 0.1880]);
title('Rozkład głębokości jaskiń (do 50 m)', 'FontSize', 16);
xticks(0:2:50);
xlabel('Głębokość jaskini (m)', 'FontWeight', 'bold');
ylabel('Liczba jaskiń', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic3.png', BackgroundColor='#f0efe9')

%% WIZUALIZACJA 4: Wykres słupkowy dla 10 najgłębszych jaskiń
f = figure(4);
f.Position = [0 500 1200 600];
[posortowane_glebokosci, indeksy_gl] = sort(glebokosc, 'descend');
top10_glebokosci = posortowane_glebokosci(1:10);
top10_nazwy_gl = nazwy(indeksy_gl(1:10));

bar(top10_glebokosci, 'FaceColor', [0.9290 0.6940 0.1250]);
set(gca, 'XTickLabel', top10_nazwy_gl);
title('10 najgłębszych jaskiń w Polsce', 'FontSize', 16);
xlabel('Nazwa jaskini', 'FontWeight', 'bold');
ylabel('Głębokość (m)', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic4.png', BackgroundColor='#f0efe9')
%% WIZUALIZACJA 5: Rozkład przewyższa jaskiń
f = figure(5);
f.Position = [0 500 1200 600];
przewyzsze_filtr = przewyzsze(przewyzsze > 0 & przewyzsze <= 100);
histogram(przewyzsze_filtr, 'BinWidth', 4, 'FaceColor', [0.4660 0.5540 0.1880]);
title('Rozkład przewyższa jaskiń (do 100 m)', 'FontSize', 16);
xticks(0:4:100);
xlabel('Przewyższe jaskini (m)', 'FontWeight', 'bold');
ylabel('Liczba jaskiń', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic5.png', BackgroundColor='#f0efe9')
%% WIZUALIZACJA 6: Wykres słupkowy dla 10 jaskiń z największym przewyższem
f = figure(6);
f.Position = [0 500 1200 600];
[posortowane_przewyzsze, indeksy_prz] = sort(przewyzsze, 'descend');
top10_przewyzsze = posortowane_przewyzsze(1:10);
top10_nazwy_prz = nazwy(indeksy_prz(1:10));

bar(top10_przewyzsze, 'FaceColor', [0.9290 0.6940 0.1250]);
set(gca, 'XTickLabel', top10_nazwy_prz);
title('10 jaskiń z największym przewyższem', 'FontSize', 16);
xlabel('Nazwa jaskini', 'FontWeight', 'bold');
ylabel('Przewyższe (m)', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic6.png', BackgroundColor='#f0efe9')
%% WIZUALIZACJA 7: Zależność głębokości od długości (Wykres punktowy / Scatter)
f = figure(7);
f.Position = [0 500 1200 600];
idx_valid = (dlugosc <= 100 & glebokosc <= 50);
scatter(dlugosc(idx_valid), glebokosc(idx_valid), 15, 'filled', 'MarkerFaceColor', [0.4940 0.1840 0.5560]);
title('Zależność między długością a głębokością jaskini', 'FontSize', 16);
xlabel('Długość (m)', 'FontWeight', 'bold');
ylabel('Głębokość (m)', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic7.png', BackgroundColor='#f0efe9')

%% WIZUALIZACJA 8: Udział rejonów w liczbie jaskiń
f = figure(8);
f.Position = [0 500 1200 600];
kategorie_regionow = categorical(regiony);
colororder('glow12')
p = piechart(kategorie_regionow);
p.Title = 'Udział rejonów w Polsce';
p.FontSize = 16;

exportgraphics(f, 'pic8.png', BackgroundColor='#f0efe9')

%% WIZUALIZACJA 9: Proporcja jaskiń osuwiskowych do krasowych
f = figure(9);
f.Position = [0 500 1200 600];
liczba_osuwiskowych = sum(osuwiskowa == 1);
liczba_innych = sum(osuwiskowa == 0);

p = piechart([liczba_osuwiskowych, liczba_innych], {'Osuwiskowe', 'Pozostałe (Krasowe itp.)'});
p.Title = 'Udział jaskiń osuwiskowych w Polsce';
p.FontSize = 16;

exportgraphics(f, 'pic9.png', BackgroundColor='#f0efe9')

%% WIZUALIZACJA 10: Udział właścicieli
f = figure(10);
f.Position = [0 500 1200 600];
kategorie_wlasciciel = categorical(wlasciciel);
wlasciciel_count = countcats(kategorie_wlasciciel);

kategorie = categories(kategorie_wlasciciel);
kategorie_sort = sort(kategorie);
kategorie_sort([2 3]) = kategorie_sort([3 2]);
wlasciciel_count([2 3]) = wlasciciel_count([3 2]);

p = piechart(wlasciciel_count, kategorie_sort);
p.Title = 'Struktura typów własności jaskiń w Polsce';
p.FontSize = 16;

exportgraphics(f, 'pic10.png', BackgroundColor='#f0efe9')

%% WIZUALIZACJA 11: Mapa rozmieszczenia jaskiń w Polsce
f = figure(11);
f.Position = [0 500 1200 600];

x = [jaskinie.X];
y = [jaskinie.Y];

x(isnan(x)) = [];
y(isnan(y)) = [];

proj = projcrs(2180);
[lat, lon] = projinv(proj, x, y);

geoscatter(lat, lon, 15, 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0.8500 0.3250 0.0980]);

geobasemap('streets-light'); 

title('Rozmieszczenie jaskiń w Polsce', 'FontSize', 16);

exportgraphics(f, 'pic11.png', BackgroundColor='#f0efe9')