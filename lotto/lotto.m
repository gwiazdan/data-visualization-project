data = readtable('dl.csv', ReadVariableNames=true);
close all;
disp(head(data))

% Wyciągnięcie samych wylosowanych liczb

numery_macierz = data{:, 3:8};


wszystkie_numery = numery_macierz(:); 
liczba_losowan = size(numery_macierz, 1); 


%% WIZUALIZACJA 1: Histogram występowania wszystkich liczb (1-49)
f = figure(1);
f.Position = [0 500 1200 600];
histogram(wszystkie_numery, 'BinEdges', 0.5:1:49.5, 'FaceColor', [0 0.4470 0.7410]);
hold on;
title('Częstotliwość występowania poszczególnych liczb w Lotto', 'FontSize', 16);
xlabel('Wylosowana liczba', 'FontWeight', 'bold');
ylabel('Ilość losowań', 'FontWeight', 'bold');
xticks(1:2:49);
xlim([0 50]);
grid on;

E = 6 * liczba_losowan/49;

yline(E, 'r', {'Oczekiwana wartość', ''}, 'LineWidth', 2, 'FontWeight', 'bold')
hold off;

exportgraphics(f, 'pic1.png', BackgroundColor='#f0efe9')


%% WIZUALIZACJA 2: Wykres słupkowy dla 10 najczęściej losowanych liczb
f = figure(2);
f.Position = [0 500 1200 600];
[zliczenia, ~] = histcounts(wszystkie_numery, 0.5:1:49.5);
[posortowane_zliczenia, posortowane_indeksy] = sort(zliczenia, 'descend');

top10_zliczenia = posortowane_zliczenia(1:10);
top10_liczby = posortowane_indeksy(1:10);

bar(top10_zliczenia, 'FaceColor', [0.8500 0.3250 0.0980]);
set(gca, 'XTickLabel', top10_liczby);
title('10 najczęściej losowanych liczb w historii', 'FontSize', 16);
xlabel('Wylosowana liczba', 'FontWeight', 'bold');
ylabel('Liczba wystąpień', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic2.png', BackgroundColor='#f0efe9')


%% WIZUALIZACJA 3: Rozkład sumy 6 wylosowanych liczb (Krzywa dzwonowa)
f = figure(3);
f.Position = [0 500 1200 600];
suma_losowan = sum(numery_macierz, 2); 

histogram(suma_losowan, 'BinWidth', 5, 'FaceColor', [0.4660 0.6740 0.1880]);
title('Rozkład sumy 6 wylosowanych liczb', 'FontSize', 16);
xlabel('Suma liczb w jednym losowaniu', 'FontWeight', 'bold');
ylabel('Liczba losowań', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic3.png', BackgroundColor='#f0efe9')
%% WIZUALIZACJA 4: Rozkład ilości liczb parzystych w pojedynczym losowaniu
f = figure(4);
f.Position = [0 500 1200 600];
parzyste_w_losowaniu = sum(mod(numery_macierz, 2) == 0, 2);

histogram(parzyste_w_losowaniu, 'BinEdges', -0.5:1:6.5, 'FaceColor', [0.9290 0.6940 0.1250]);
title('Ile liczb parzystych wypada w jednym losowaniu?', 'FontSize', 16);
xlabel('Ilość liczb parzystych (od 0 do 6)', 'FontWeight', 'bold');
ylabel('Liczba losowań', 'FontWeight', 'bold');
xticks(0:6);
grid on;

exportgraphics(f, 'pic4.png', BackgroundColor='#f0efe9')
%% WIZUALIZACJA 5: Mapa ciepła (Heatmap) par liczb
f = figure(5);
f.Position = [0 500 1200 600];
wspolwystepowanie = zeros(49, 49);


for i = 1:liczba_losowan
    wylosowane = numery_macierz(i, :);
    pary = nchoosek(wylosowane, 2); 
    for p = 1:size(pary, 1)
        liczba1 = pary(p, 1);
        liczba2 = pary(p, 2);
        wspolwystepowanie(liczba1, liczba2) = wspolwystepowanie(liczba1, liczba2) + 1;
        wspolwystepowanie(liczba2, liczba1) = wspolwystepowanie(liczba2, liczba1) + 1; 
    end
end

imagesc(wspolwystepowanie);
colormap('hot'); 
colorbar;
title('Mapa ciepła współwystępowania par liczb', 'FontSize', 16);
xlabel('Liczba A', 'FontWeight', 'bold');
ylabel('Liczba B', 'FontWeight', 'bold');
axis square;

exportgraphics(f, 'pic5.png', BackgroundColor='#f0efe9')

%% WIZUALIZACJA 6: Ile par sąsiadujących liczb występuje w jednym losowaniu?
f = figure(6);
f.Position = [0 500 1200 600];
kolejne_w_losowaniu = zeros(liczba_losowan, 1);

for i = 1:liczba_losowan
    
    wylosowane = sort(numery_macierz(i, :));
   
    roznice = diff(wylosowane);
    
    kolejne_w_losowaniu(i) = sum(roznice == 1);
end

histogram(kolejne_w_losowaniu, 'BinEdges', -0.5:1:5.5, 'FaceColor', [0.4940 0.1840 0.5560]);
title('Występowanie sąsiadujących liczb (np. 14 i 15) w losowaniu', 'FontSize', 16);
xlabel('Ilość par sąsiadujących liczb', 'FontWeight', 'bold');
ylabel('Liczba losowań', 'FontWeight', 'bold');
xticks(0:5);
grid on;

exportgraphics(f, 'pic6.png', BackgroundColor='#f0efe9')
%% WIZUALIZACJA 7: Liczby "Niskie" (1-24) w jednym losowaniu
f = figure(7);
f.Position = [0 500 1200 600];
liczby_niskie = sum(numery_macierz <= 24, 2);

histogram(liczby_niskie, 'BinEdges', -0.5:1:6.5, 'FaceColor', [0.3010 0.7450 0.9330]);
title('Ile liczb z dolnej połowy (1-24) wypada w jednym losowaniu?', 'FontSize', 16);
xlabel('Ilość liczb z przedziału 1-24', 'FontWeight', 'bold');
ylabel('Liczba losowań', 'FontWeight', 'bold');
xticks(0:6);
grid on;

exportgraphics(f, 'pic7.png', BackgroundColor='#f0efe9')
%% WIZUALIZACJA 8: Liczby "Zimne" - ile losowań minęło od ostatniego trafienia?
f = figure(8);
f.Position = [0 500 1200 600];
opoznienie_liczb = zeros(1, 49);

for liczba = 1:49
    
    [wiersze, ~] = find(numery_macierz == liczba);
    
    if ~isempty(wiersze)
        % Ostatnie losowanie to maksymalny indeks wiersza
        ostatnie_trafienie = max(wiersze);
        % Obliczamy ile losowań minęło od tego momentu
        opoznienie_liczb(liczba) = liczba_losowan - ostatnie_trafienie;
    else
        % Jeśli liczba z jakiegoś powodu nigdy nie padła
        opoznienie_liczb(liczba) = liczba_losowan;
    end
end

bar(1:49, opoznienie_liczb, 'FaceColor', [0.6350 0.0780 0.1840]);
title('Liczby "Zimne": Ile losowań wstecz padła dana liczba po raz ostatni?', 'FontSize', 16);
xlabel('Numer na kuli (1-49)', 'FontWeight', 'bold');
ylabel('Ilość losowań od ostatniego wystąpienia', 'FontWeight', 'bold');
grid on;

exportgraphics(f, 'pic8.png', BackgroundColor='#f0efe9')

%% Chi^2
[zliczenia, ~] = histcounts(wszystkie_numery, 0.5:1:49.5);
E = 6*liczba_losowan/49;
chi2 = sum((zliczenia - E).^2 ./ E);
disp(chi2)
p_value = 1 - gammainc(chi2/2, 48/2);
disp(p_value)