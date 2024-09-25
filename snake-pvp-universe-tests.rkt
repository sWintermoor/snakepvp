#lang racket
(require test-engine/racket-tests)
(require "snake-pvp-universe.rkt")

; Testschlangen
(define SNAKE1 (snake '((1 2) (2 2)) "green" "solid" "down" 1 2 2))
(define SNAKE2 (snake '((7 8) (8 8) (9 8)) "blue" "solid" "left" 1 3 2))

; Testfrüchte
(define FRUIT1 (item 'apple 5 5))
(define FRUIT2 (item 'banana 5 6))

; Testuniversen
(define UNIVERSE1 (list '() (list SNAKE1 SNAKE2) (list FRUIT1) 1080))


; Funktionen, um Teile des Universums abzurufen
(check-expect (current-worlds UNIVERSE1) '())                    ; UniverseState -> Listof iworld?; Gibt die aktuellen Welten zurück
(check-expect (current-snakes UNIVERSE1) (list SNAKE1 SNAKE2))   ; UniverseState -> List of snake; Gibt die aktuellen Schlangen zurück
(check-expect (current-fruits UNIVERSE1) (list FRUIT1))          ; UniverseState -> List of item; Gibt die aktuellen Früchte zurück
(check-expect (timer UNIVERSE1) 1080)                            ; UniverseState -> Timer; Gibt den Timerwert zurück

; information-to-draw: UniverseState -> [Listof snake] [Listof item] Timer
; Funktion zur Bereitstellung der zu zeichnenden Information basierend auf dem Universum

(define (information-to-draw univ)


(test)