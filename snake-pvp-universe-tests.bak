#lang racket
(require test-engine/racket-tests)
(require "snake-pvp-universe.rkt")

; Testschlangen
(define SNAKE1 (snake '((1 2) (2 2)) "green" 0 'down 1 2 2))
(define SNAKE2 (snake '((7 8) (8 8) (9 8)) "blue" 0 'left 1 3 2))
(define SNAKE3 (snake '((4 5) (3 5)) "green" 0 'right 1 2 2))
(define SNAKE4 (snake '((3 5) (3 4) (3 3)) "blue" 0 'down 1 3 4))
(define SNAKE5 (snake '((1 1) (1 2) (2 2) (2 1) (1 1)) "blue" 0 'down 1 5 4))

; Testfrüchte
(define FRUIT1 (item 'apple 5 5))
(define FRUIT2 (item 'banana 5 6))

; Testtimer
(define TIMER1 1080)

; Testwelten
(define WORLDS1 '())

; Testkonstanten für zu sendende Nachrichten
(define MESSAGE1 (list (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1))
(define MESSAGE2 (list (list SNAKE3 SNAKE2) (list FRUIT1) TIMER1))

; Testuniversen
(define UNIVERSE1 (append (list WORLDS1) MESSAGE1))
(define UNIVERSE2 (append (list WORLDS1) MESSAGE2))


; Funktionen, um Teile des Universums abzurufen
(check-expect (current-worlds UNIVERSE1) WORLDS1)                    ; UniverseState -> Listof iworld?; Gibt die aktuellen Welten zurück
(check-expect (current-snakes UNIVERSE1) (list SNAKE1 SNAKE2))   ; UniverseState -> List of snake; Gibt die aktuellen Schlangen zurück
(check-expect (current-fruits UNIVERSE1) (list FRUIT1))          ; UniverseState -> List of item; Gibt die aktuellen Früchte zurück
(check-expect (timer UNIVERSE1) TIMER1)                            ; UniverseState -> Timer; Gibt den Timerwert zurück

; information-to-draw: UniverseState -> (List [Listof snake] [Listof item] Timer String)
; Funktion zur Bereitstellung der zu zeichnenden Information basierend auf dem Universum
(check-expect (information-to-draw UNIVERSE1) (list (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "playing"))

; UniverseState -> (List [Listof snake] [Listof item] Timer String)
; Verschiedene Spielmodi
(check-expect (waiting-mode UNIVERSE1) (list (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "waiting"))
(check-expect (win-mode UNIVERSE1) (list (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "win"))
(check-expect (loose-mode UNIVERSE1) (list (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "loose"))
(check-expect (tie-mode UNIVERSE1) (list (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "tie"))

; UniverseState -> snake
; Hilfsfunktionen zum Abrufen der ersten und zweiten Schlange
(check-expect (first-snake UNIVERSE1) SNAKE1)
(check-expect (second-snake UNIVERSE1) SNAKE2)

; UniverseState -> Score
; Hilfsfunktionen zum Abrufen des Scores der ersten Schlange und des Scores der zweiten Schlange
(check-expect (first-snake-score UNIVERSE1) 2)
(check-expect (second-snake-score UNIVERSE1) 3)

; add-world wird nicht getestet, weil man eine iworld als Eingabe benötigt.

; detect-key: snake KeyEvent Direction -> snake
; Verarbeitet Tastatureingaben
(check-expect (detect-key SNAKE1 "left" (snake-direction SNAKE1))
              (snake (snake-coordinates SNAKE1) (snake-color SNAKE1) (snake-velocity-duration SNAKE1) 'left (snake-velocity SNAKE1) (snake-score SNAKE1) (snake-banana SNAKE1)))
(check-expect (detect-key SNAKE1 " " (snake-direction SNAKE1))
              (snake (snake-coordinates SNAKE1) (snake-color SNAKE1) 15 (snake-direction SNAKE1) 2 (snake-score SNAKE1) 1))
(check-expect (detect-key SNAKE1 "a" (snake-direction SNAKE1))
                          SNAKE1)

; activate-booster: snake -> snake
; Erhöht ggf. Geschwindigkeit der Schlange
(check-expect (activate-booster SNAKE1)
              (snake (snake-coordinates SNAKE1) (snake-color SNAKE1) 15 (snake-direction SNAKE1) 2 (snake-score SNAKE1) 1))

; change-velocity: snake Velocity-Duration Velocity Banana -> snake
; Passt Geschwindigkeit der Schlange an.
(check-expect (change-velocity SNAKE1 15 2 1)
              (snake (snake-coordinates SNAKE1) (snake-color SNAKE1) 15 (snake-direction SNAKE1) 
         2 (snake-score SNAKE1) 1))

; change-direction: snake Direction -> snake
; Passt Richtung der Schlange an.
(check-expect (change-direction SNAKE1 'right)
              (snake (snake-coordinates SNAKE1) (snake-color SNAKE1) (snake-velocity-duration SNAKE1) 'right (snake-velocity SNAKE1) (snake-score SNAKE1) (snake-banana SNAKE1)))

; key-handler wird nicht getestet, weil man eine iworld als Eingabe benötigt.

; handle-messages wird nicht getestet, weil man eine iworld als Eingabe benötigt.

; next-snake-state: snake UniverseState -> snake
; Berechnet den nächsten Zustand einer Schlange
(check-expect (next-snake-state SNAKE2 UNIVERSE1)
              (snake '((6 8) (7 8) (8 8)) (snake-color SNAKE2) (snake-velocity-duration SNAKE2) (snake-direction SNAKE2) (snake-velocity SNAKE2) (snake-score SNAKE2) (snake-banana SNAKE2)))
(check-expect (next-snake-state SNAKE3 UNIVERSE2)
              (snake '((5 5) (4 5) (3 5)) (snake-color SNAKE3) (snake-velocity-duration SNAKE3) (snake-direction SNAKE3) (snake-velocity SNAKE3) 3 (snake-banana SNAKE3)))

; move-snake: snake Direction Boolean -> Coordinates
; Bewegt die Schlange basierend auf der aktuellen Richtung
(check-expect (move-snake SNAKE2 'left #f)
              '((6 8) (7 8) (8 8)))
(check-expect (move-snake SNAKE3 'right #t)
              '((5 5) (4 5) (3 5)))

; next-fruit-state: snake snake UniverseState -> [Listof item]
; Berechnet den nächsten Zustand eines Items
(check-expect (next-fruit-state SNAKE1 SNAKE2 UNIVERSE1) (list FRUIT1))

; new-fruit lässt sich schlecht testen, da mit random gearbeitet wird

; create-fruit lässt sich schlecht testen, da mit random gearbeitet wird

; correct-random: [Listof item] (List x-Coordinate y-Coordinate) Coordinates -> (List x-Coordinate y-Coordinate)
; Verhindert das Spawnen von neuen Früchten auf der Schlange und auf Früchten (in der World müssen Früchte zuerst gezeichnet werden)
(check-expect (correct-random (list FRUIT1) '(10 10) (append (snake-coordinates SNAKE1) (snake-coordinates SNAKE2)))
              '(10 10))

; extract-fruit-type-coordinates: [Listof item] -> [Listof (List Type x-Coordinate y-Coordinate)]
; Wandelt struct-Struktur von [Listof item] in Listenstruktur um.
;(check-expect (extract-fruit-type-coordinates fruit-list))

; tick-handler: UniverseState -> UniverseState
; Wird mit jedem Tick aufgerufen. Beendet das Spiel oder setzt neuen Spielzustand.
;(check-expect (tick-handler UNIVERSE1) )

; check-collision: snake snake -> Boolean
; Prüft, ob der Kopf der ersten Schlange in den Koordinaten der zweiten Schlange vorkommt
(check-expect (check-collision SNAKE1 SNAKE2) #f)
(check-expect (check-collision SNAKE4 SNAKE3) #t)
(check-expect (check-collision SNAKE3 SNAKE4) #f)

; check-snake-collision: snake snake -> Boolean
; Prüft, ob die beiden Schlangen kollidieren
(check-expect (check-snake-collisions SNAKE1 SNAKE2) #f)
(check-expect (check-snake-collisions SNAKE3 SNAKE4) #t)

; check-self-collision: snake -> Boolean
; Prüft, ob eine Schlange mit sich selbst kollidiert (Selbstkollision)
(check-expect (check-self-collision SNAKE1) #f)
(check-expect (check-self-collision SNAKE5) #t)

; check-all-collisions: snake snake -> Boolean
; Überprüft, ob eine der beiden Schlangen kollidiert (entweder mit der anderen oder mit sich selbst)
(check-expect (check-all-collisions SNAKE1 SNAKE2) #f)
(check-expect (check-all-collisions SNAKE2 SNAKE5) #t)
(check-expect (check-all-collisions SNAKE3 SNAKE4) #t)


(test)