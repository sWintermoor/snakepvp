#lang racket
(provide (all-defined-out)) ; Für World und Universe

; Datei enthält globale Variablen und Structs, die von Universe und World gleichermaßen genutzt werden. 

; Structs: Definition der Strukturen für Items (Futter) und Schlangen
(define-struct item [type x-coordinate y-coordinate] #:prefab)   ; item repräsentiert Futter- oder andere Objekte
(define-struct snake [id coordinates color boost-duration direction velocity score banana] #:prefab) ; Schlange mit ihren Eigenschaften

; Spielgeschwindigkeit
(define GAME-SPEED 18)

; Spielfeldparameter
(define GAME-SIZE 5)                          ; Spielgröße 
(define GRID-SIZE (* GAME-SIZE 5))            ; Spielfeldgröße: hier 25x25 Zellen
(define CELL-SIZE (* GAME-SIZE 6))            ; Jede Zelle ist hier 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds in Pixeln
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds in Pixeln