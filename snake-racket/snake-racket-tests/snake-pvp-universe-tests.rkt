#lang racket
(require test-engine/racket-tests)
(require "snake-pvp-universe.rkt")
(require "global-features.rkt")

; Seed für random-Funktionen
(random-seed 5)

; Testschlangen
(define SNAKE1 (snake 1 '((1 2) (2 2)) "green" 0 'down 3 2 2))
(define SNAKE2 (snake 2 '((7 8) (8 8) (9 8)) "blue" 0 'left 3 3 2))
(define SNAKE3 (snake 3 '((4 5) (3 5)) "green" 0 'right 1 2 2))
(define SNAKE4 (snake 4 '((3 5) (3 4) (3 3)) "blue" 0 'down 1 3 4))
(define SNAKE5 (snake 5 '((1 1) (1 2) (2 2) (2 1) (1 1)) "green" 5 'down 1 5 4))
(define SNAKE6 (snake 6 '((0 0) (0 1)) "blue" 0 'up 3 0 0))

; Testfrüchte
(define FRUIT1 (item 'apple 5 5))
(define FRUIT2 (item 'banana 1 2))
(define FRUIT3 (item 'apple 0 0))

; Testtimer
(define TIMER1 1080)
(define TIMER2 1)

; Testwelten
(define WORLDS '())

; Testkonstanten für zu sendende Nachrichten
(define MESSAGE1 (list (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1))
(define MESSAGE2 (list (list SNAKE3 SNAKE2) (list FRUIT1) TIMER2))
(define MESSAGE3 (list (list SNAKE5 SNAKE6) (list FRUIT2 FRUIT3) TIMER2))
(define MESSAGE4 (list (list SNAKE3 SNAKE4) (list FRUIT1 FRUIT2 FRUIT3) TIMER1))

; Testuniversen
(define UNIVERSE1 (append (list WORLDS) MESSAGE1))
(define UNIVERSE2 (append (list WORLDS) MESSAGE2))
(define UNIVERSE3 (append (list WORLDS) MESSAGE3))
(define UNIVERSE4 (append (list WORLDS) MESSAGE4))


; Funktionen, um Teile des Universums abzurufen
(check-expect (current-worlds UNIVERSE1) WORLDS)                ; UniverseState -> Listof iworld?; Gibt die aktuellen Welten zurück
(check-expect (current-snakes UNIVERSE1) (list SNAKE1 SNAKE2))   ; UniverseState -> List of snake; Gibt die aktuellen Schlangen zurück
(check-expect (current-fruits UNIVERSE1) (list FRUIT1))          ; UniverseState -> List of item; Gibt die aktuellen Früchte zurück
(check-expect (timer UNIVERSE1) TIMER1)                          ; UniverseState -> Timer; Gibt den Timerwert zurück

; information-to-draw: UniverseState ID -> (List ID [Listof snake] [Listof item] Timer String)
; Funktion zur Bereitstellung der zu zeichnenden Information basierend auf dem Universum
(check-expect (information-to-draw UNIVERSE1 1) (list 1 (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "playing"))
(check-expect (information-to-draw UNIVERSE2 2) (list 2 (list SNAKE3 SNAKE2) (list FRUIT1) TIMER2 "playing"))

; UniverseState ID -> (List ID [Listof snake] [Listof item] Timer String)
; Verschiedene Spielmodi
(check-expect (waiting-mode UNIVERSE1 1) (list 1 (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "waiting"))
(check-expect (win-mode UNIVERSE1 2) (list 2 (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "win"))
(check-expect (loose-mode UNIVERSE1 1) (list 1 (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "loose"))
(check-expect (tie-mode UNIVERSE1 2) (list 2 (list SNAKE1 SNAKE2) (list FRUIT1) TIMER1 "tie"))

; UniverseState -> snake
; Hilfsfunktionen zum Abrufen der ersten und zweiten Schlange
(check-expect (first-snake UNIVERSE1) SNAKE1)
(check-expect (second-snake UNIVERSE1) SNAKE2)

; UniverseState -> Score
; Hilfsfunktionen zum Abrufen des Scores der ersten Schlange und des Scores der zweiten Schlange
(check-expect (first-snake-score UNIVERSE1) 2)
(check-expect (second-snake-score UNIVERSE1) 3)

; add-world - wegen iworld-Verarbeitung keine Tests verfügbar

; detect-key: snake KeyEvent Direction -> snake
; Verarbeitet Tastatureingaben
(check-expect (detect-key SNAKE1 "left" (snake-direction SNAKE1))
              (snake (snake-id SNAKE1) (snake-coordinates SNAKE1) (snake-color SNAKE1) (snake-boost-duration SNAKE1) 'left (snake-velocity SNAKE1) (snake-score SNAKE1) (snake-banana SNAKE1)))
(check-expect (detect-key SNAKE1 " " (snake-direction SNAKE1))
              (snake (snake-id SNAKE1) (snake-coordinates SNAKE1) (snake-color SNAKE1) 15 (snake-direction SNAKE1) 1 (snake-score SNAKE1) 1))
(check-expect (detect-key SNAKE5 " " (snake-direction SNAKE1))
              (snake (snake-id SNAKE5) (snake-coordinates SNAKE5) (snake-color SNAKE5) 20 (snake-direction SNAKE5) 1 (snake-score SNAKE5) 3))
(check-expect (detect-key SNAKE1 "a" (snake-direction SNAKE1))
                          SNAKE1)

; activate-booster: snake -> snake
; Erhöht ggf. Geschwindigkeit der Schlange
(check-expect (activate-booster SNAKE1)
              (snake (snake-id SNAKE1) (snake-coordinates SNAKE1) (snake-color SNAKE1) 15 (snake-direction SNAKE1) 1 (snake-score SNAKE1) 1))
(check-expect (activate-booster SNAKE5)
              (snake (snake-id SNAKE5) (snake-coordinates SNAKE5) (snake-color SNAKE5) 20 (snake-direction SNAKE5) 1 (snake-score SNAKE5) 3))

; change-velocity: snake Velocity-Duration Velocity Banana -> snake
; Passt Geschwindigkeit der Schlange an.
(check-expect (change-velocity SNAKE1 15 2 1)
              (snake (snake-id SNAKE1) (snake-coordinates SNAKE1) (snake-color SNAKE1) 15 (snake-direction SNAKE1) 
         2 (snake-score SNAKE1) 1))
(check-expect (change-velocity SNAKE5 0 3 0)
              (snake (snake-id SNAKE5) (snake-coordinates SNAKE5) (snake-color SNAKE5) 0 (snake-direction SNAKE5) 
         3 (snake-score SNAKE5) 0))

; change-direction: snake Direction -> snake
; Passt Richtung der Schlange an.
(check-expect (change-direction SNAKE1 'right)
              (snake (snake-id SNAKE1) (snake-coordinates SNAKE1) (snake-color SNAKE1) (snake-boost-duration SNAKE1) 'right (snake-velocity SNAKE1) (snake-score SNAKE1) (snake-banana SNAKE1)))
(check-expect (change-direction SNAKE1 (snake-direction SNAKE1)) 
              (snake (snake-id SNAKE1) (snake-coordinates SNAKE1) (snake-color SNAKE1) (snake-boost-duration SNAKE1) (snake-direction SNAKE1) (snake-velocity SNAKE1) (snake-score SNAKE1) (snake-banana SNAKE1)))
(check-expect (change-direction SNAKE5 'up)  ; Eingabe: Entgegengesetzten Richtung
              (snake (snake-id SNAKE5) (snake-coordinates SNAKE5) (snake-color SNAKE5) (snake-boost-duration SNAKE5) 'up (snake-velocity SNAKE5) (snake-score SNAKE5) (snake-banana SNAKE5)))

; handle-messages - wegen iworld-Verarbeitung keine Tests verfügbar

; next-snake-state: snake UniverseState -> snake
; Berechnet den nächsten Zustand einer Schlange
(check-expect (next-snake-state SNAKE2 UNIVERSE1) ; Schlange bewegt sich (nach links). Geschwindigkeit bleibt niedrig.
              (snake (snake-id SNAKE2) '((6 8) (7 8) (8 8)) (snake-color SNAKE2) (snake-boost-duration SNAKE2) (snake-direction SNAKE2) (snake-velocity SNAKE2) (snake-score SNAKE2) (snake-banana SNAKE2)))
(check-expect (next-snake-state SNAKE2 UNIVERSE2) ; Schlange bewegt sich nicht. 
              (snake (snake-id SNAKE2) (snake-coordinates SNAKE2) (snake-color SNAKE2) (snake-boost-duration SNAKE2) (snake-direction SNAKE2) (snake-velocity SNAKE2) (snake-score SNAKE2) (snake-banana SNAKE2)))
(check-expect (next-snake-state SNAKE3 UNIVERSE2) ; Schlange bewegt sich (nach links). Geschwindigkeit fällt. Apfel wird aufgenommen.
              (snake (snake-id SNAKE3) '((5 5) (4 5) (3 5)) (snake-color SNAKE3) (snake-boost-duration SNAKE3) (snake-direction SNAKE3) 3 3 (snake-banana SNAKE3)))
(check-expect (next-snake-state SNAKE5 UNIVERSE3) ; Schlange bewegt sich (nach unten). Geschwindigkeit bleibt hoch. Boost-Dauer verkleinert sich. Banane wird aufgenommen.
              (snake (snake-id SNAKE5) '((1 2) (1 1) (1 2) (2 2) (2 1)) (snake-color SNAKE5) 4 (snake-direction SNAKE5) (snake-velocity SNAKE5) (snake-score SNAKE5) 5))


; move-snake: snake Direction Boolean -> Coordinates
; Bewegt die Schlange basierend auf der aktuellen Richtung
(check-expect (move-snake SNAKE2 'left #f)
              '((6 8) (7 8) (8 8)))
(check-expect (move-snake SNAKE3 'right #t)
              '((5 5) (4 5) (3 5)))
(check-expect (move-snake SNAKE6 'up #f)
              (list (list 0 (- GRID-SIZE 1)) (list 0 0)))

; next-fruit-state: snake snake UniverseState -> [Listof item]
; Berechnet den nächsten Zustand eines Items
; Es wird mit einem seed getestet
(check-expect (next-fruit-state SNAKE1 SNAKE2 UNIVERSE1) (list FRUIT1)) ; Keine Frucht konsumiert.
(check-expect (next-fruit-state SNAKE5 SNAKE6 UNIVERSE3) (list (item 'banana 2 7) (item 'banana 1 2))) ; Frucht wird konsumiert.

; new-fruit: [Listof item] item Coordinates -> [Listof item]
; Entfernt die gegessene Frucht und platziert 1-2 Neue
; Es wird mit einem seed getestet
(check-expect (new-fruit (list FRUIT2 FRUIT3) FRUIT3 (list SNAKE5 SNAKE6)) (list (item 'apple 15 15) (item 'banana 18 16) FRUIT2))

; create-fruit: [Listof item] Type Coordinates -> [Listof item]
; Erstellt 1-2 neue Früchte
; Es wird mit einem seed getestet
(check-expect (create-fruit (list FRUIT2 FRUIT3) 'banana (list SNAKE5 SNAKE6)) (list (item 'apple 9 17) (item 'banana 6 18)))

; correct-random: [Listof item] (List x-Coordinate y-Coordinate) Coordinates -> (List x-Coordinate y-Coordinate)
; Verhindert das Spawnen von neuen Früchten auf der Schlange und auf Früchten (in der World müssen Früchte zuerst gezeichnet werden)
(check-expect (correct-random (list FRUIT1) '(10 10) (append (snake-coordinates SNAKE1) (snake-coordinates SNAKE2)))       ; leere Stelle gewählt
              '(10 10)) ; leere Stelle gewählt
(check-expect (correct-random (list FRUIT2 FRUIT3) '(2 1) (append (snake-coordinates SNAKE5) (snake-coordinates SNAKE5)))  ; Koordinaten einer Schlange gewählt
              '(9 3))
(check-expect (correct-random (list FRUIT2 FRUIT3) '(0 0) (append (snake-coordinates SNAKE5) (snake-coordinates SNAKE5)))  ; Koordinaten einer Frucht gewählt
              '(10 10))

; extract-fruit-type-coordinates: [Listof item] -> [Listof Type (List x-Coordinate y-Coordinate)]
; Wandelt struct-Struktur von [Listof item] in Listenstruktur um.
(check-expect (extract-fruit-type-coordinates (list FRUIT2 FRUIT3))
              (list 'banana (list 1 2) 'apple (list 0 0)))

; tick-handler - wegen iworld-Verarbeitung keine Tests verfügbar

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