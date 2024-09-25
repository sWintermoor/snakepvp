#lang racket
(require test-engine/racket-tests)
(require "snake-pvp-world.rkt")

; Regressionstests für snake-pvp-world

; Structs: Definition der Strukturen für Items (Futter), Schlangen und den Weltzustand
(define-struct item [type x-coordinate y-coordinate] #:prefab)   ; item repräsentiert Futter- oder andere Objekte
(define-struct snake [coordinates color snakeStatus direction velocity score banana] #:prefab) ; Schlange mit ihren Eigenschaften
(define-struct world [snakes items timer worldStatus] #:prefab) ; Weltzustand mit Schlangen, Items, Timer und Spielstatus (waiting, playing, win, loose)

; Testschlangen
(define SNAKE1 (snake '((1 2) (2 2)) "green" "solid" "down" 1 2 2))
(define SNAKE2 (snake '((7 8) (8 8) (9 8)) "blue" "solid" "left" 1 3 2))

; Testfrüchte
(define FRUIT1 (item 'apple 5 5))
(define FRUIT2 (item 'banana 5 6))

; Testwelten
(define WORLD1 (world '() '() "3:00" "waiting"))
(define WORLD2 (world '(SNAKE1 SNAKE2) '(ITEM1 ITEM2) "0:30" "playing"))

; Testnachrichten
(define MESSAGE '((SNAKE1 SNAKE2) (ITEM1 ITEM2) 180 "playing"))


; receive: WorldState S-expression -> WorldState
; Empfangen von Nachrichten (Weltstatus aktualisieren)
(check-expect (receive WORLD1 MESSAGE) WORLD2)

; seconds-to-minutes: Number -> String 
; Funktion zur Umwandlung von Sekunden in Minuten. Ausgabe in "Minuten:Sekunden" Format
(check-expect (seconds-to-minutes 200) "3:20")
(check-expect (seconds-to-minutes 0) "0:0")


(test)