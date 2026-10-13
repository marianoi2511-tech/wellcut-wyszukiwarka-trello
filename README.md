# WELLCUT – Wyszukiwarka Trello

Aplikacja Windows do wyszukiwania detali i cen w kartach Trello.

## Funkcje
- wyszukiwanie na jednej lub dwóch tablicach Trello,
- osobne API Key i Token dla każdej tablicy,
- dane dostępowe ukryte w Ustawieniach,
- filtrowanie po kliencie,
- cena i data zakończenia,
- dwuklik otwiera kartę Trello,
- wersja EXE bez okna konsoli,
- **EKSPORT DO WIECZNEGO ARCHIWUM**: pobiera wszystkie karty (także zarchiwizowane) z checklistami z obu tablic i zapisuje
  pliki JSON (po 1000 kart) na pulpicie w folderze `WELLCUT-Wieczne-archiwum-Trello`. W WELLCUT: W. ARCHIWUM → Dodaj plik…
  → zaznacz wszystkie pliki z tego folderu.

## Pobieranie
Gotowy plik EXE jest budowany automatycznie przez GitHub Actions. Otwórz zakładkę **Actions**, wybierz najnowszy udany przebieg **Build Windows EXE** i pobierz artefakt **WELLCUT-Wyszukiwarka-Trello-Windows**.

API Key i Token nie są umieszczane w repozytorium. Wpisuje się je lokalnie w aplikacji.
