#lang racket
(require test-engine/racket-tests)
(require 2htdp/image)
(require 2htdp/universe)
(require "snake-pvp-world.rkt")
(require "global-features.rkt")

; Testscenes
(define SCENE1 (empty-scene WIDTH TOTAL-HEIGHT))

; Testschlangen
(define SNAKE1 (snake 1 '((1 2) (2 2)) "green" "solid" "down" 1 2 2))
(define SNAKE2 (snake 2 '((7 8) (8 8) (9 8)) "blue" "solid" "left" 1 3 2))

; Testfrüchte
(define FRUIT1 (item 'apple 5 5))
(define FRUIT2 (item 'banana 5 6))

; Testwelten
(define WORLD1 (world 1 '() '() "3:00" "waiting"))
(define WORLD2 (world 2 '(SNAKE1 SNAKE2) '(FRUIT1 FRUIT2) "0:30" "playing"))

; Testnachrichten
(define MESSAGE1 (list 1 (list SNAKE1 SNAKE2) (list FRUIT1 FRUIT2) (* 10 GAME-SPEED) "playing"))
(define MESSAGE2 (list 1 (list SNAKE1) (list FRUIT1 FRUIT2) (* 180 GAME-SPEED) "waiting"))
(define MESSAGE3 (list 2 (list SNAKE1 SNAKE2) (list FRUIT1 FRUIT2) (* 0 GAME-SPEED) "loose"))


; receive: WorldState S-expression -> WorldState
; Empfangen von Nachrichten (Weltstatus aktualisieren)
(check-expect (receive WORLD1 MESSAGE1) (world 1 (list SNAKE1 SNAKE2) (list FRUIT1 FRUIT2) "0:10" "playing"))
(check-expect (receive WORLD1 MESSAGE2) (world 1 (list SNAKE1) (list FRUIT1 FRUIT2) "3:00" "waiting"))
(check-expect (receive WORLD2 MESSAGE3) (world 2 (list SNAKE1 SNAKE2) (list FRUIT1 FRUIT2) "0:00" "loose"))

; seconds-to-minutes: Number -> Timer-String
; Funktion zur Umwandlung von Sekunden in Minuten. Ausgabe in "Minuten:Sekunden" Format
(check-expect (seconds-to-minutes 200) "3:20")
(check-expect (seconds-to-minutes 0) "0:00")

; Methoden, die zur Visualisierung dienen, werden nicht geprüft

; key-handler: WorldState KeyEvent -> WorldState
; Funktion zur Verarbeitung der Tastatureingabe
(check-expect (key-handler WORLD2 "up") (make-package WORLD2 "up"))
(check-expect (key-handler WORLD2 " ") (make-package WORLD2 " "))
(check-expect (key-handler WORLD2 "a") (make-package WORLD2 "a"))

(test)