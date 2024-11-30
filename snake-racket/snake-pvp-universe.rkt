#lang racket
(require 2htdp/universe)
(require "global-features.rkt")

(provide (all-defined-out)) ; Für Tests und Launch

; Ein UniverseState ist eine Liste aus [Listof iworld?], [List of snake], [Listof item] und Timer.
; Interpretation: Der aktuelle Serverzustand

; Eine snake ist ein Struct bestehend aus ID, Coordinates, Color, SnakeStatus, Direction, Velocity, Score und Banana.
; Interpretation: Die Gesamtheit aller Elemente, die eine Schlange im Spiel definieren.

; Ein item ist ein Struct aus Type, x-Coordinate und y-Coordinate.
; Interpreation: Item im Spiel.

; Timer ist eine Number.
; Interpretation: Vergangene Zeit seit Spielbeginn.

; Timer-String ist ein String.
; Interpretation: Timer, der die bereits vergangene Zeit seit Spielbeginn anzeigt.

; ID ist eine Number.
; Interpretation: Eine eindeutige Kennung der Schlange.

; Coordinates ist eine [Listof (List Number Number)].
; Interpretation: Eine Liste von (x, y)-Koordinaten.

; Color ist ein String.
; Interpretation: Beschreibt eine Farbe.

; Boost-Duration ist eine Number.
; Interpretation: Beschreibt wie lange sich die Schlange im Hochgeschwindigkeitsmodus aufhalten wird.

; Immunity-Duration ist eine Number.
; Interpretation: Beschreibt wie lange sich die Schlange im Unbesiegbarmodus aufhalten wird.

; Direction ist ein Symbol.
; Interpretation: Beschreibt Bewegungsrichtung der Schlange.

; Velocity ist eine Number.
; Interpretation: Beschreibt Geschwindigkeit der Schlange. Je kleiner die Zahl, desto größer die Geschwindigkeit.

; Score ist eine Number.
; Interpretaion: Gibt die länge der gegebenen Schlange wieder.

; Banana ist eine Number.
; Interpretation: Die Anzahl an gegessenen Bananen.

; Blueberry ist eine Number.
; Interpretation: Die Anzahl an gegessenen Blaubeeren.

; Type ist ein Symbol.
; Interpretation: Beschreibt den Typ des Items. Unterschieden wird zwischen 'apple und 'banana.

; x-Coordinate ist eine Number.
; Interpretation: Die x-Koordinate im Spiel.

; y-Coordinate ist eine Number.
; Interpretation: Die y-Koordinate im Spiel.

; Game-Status ist eine Liste aus [Listof snake], [Listof item], Timer und String
; Interpretation: Der Spielstatus einer Welt. 

; Werte für ID, Farbe, Geschwindigkeit, Geschwindigkeitsdauer, Score und Bananen der Schlangen
(define SNAKE-ID1 1)
(define SNAKE-ID2 2)
(define VELOCITY-NORMAL 3)
(define BOOST 1)
(define BOOST-DURATION-INITIAL 0)
(define BOOST-DURATION 15)
(define IMMUNITY-DURATION-INITIAL 0)
(define IMMUNITY-DURATION 15)
(define SCORE-INITIAL 0)
(define BANANA-INITIAL 0)
(define BLUEBERRY-INITIAL 0)

; Initiale Schlangen und Früchte
(define SNAKE1 (snake SNAKE-ID1 (list (list 1 0) (list 0 0)) "Yellow Green" BOOST-DURATION-INITIAL IMMUNITY-DURATION-INITIAL 'right VELOCITY-NORMAL SCORE-INITIAL BANANA-INITIAL BLUEBERRY-INITIAL)) ; Erste Schlange
(define SNAKE2 (snake SNAKE-ID2 (list (list (- GRID-SIZE 2) (- GRID-SIZE 1)) (list (- GRID-SIZE 1) (- GRID-SIZE 1))) "navy" BOOST-DURATION-INITIAL IMMUNITY-DURATION-INITIAL 'left VELOCITY-NORMAL SCORE-INITIAL BANANA-INITIAL BLUEBERRY-INITIAL))      ; Zweite Schlange
(define FRUIT1 (item 'apple (floor (/ GRID-SIZE 2)) (floor (/ GRID-SIZE 2))))                   ; Erste Frucht (Apfel)

; Initiale Listen und Werte für Welten, Schlangen, Früchte und den Timer
(define LIST-WORLDS-INITIAL '())                       ; Liste der Welten (zunächst leer)
(define LIST-SNAKES-INITIAL (list SNAKE1 SNAKE2))      ; Liste der Schlangen 
(define LIST-FRUITS-INITIAL (list FRUIT1))             ; Liste der Früchte 
(define TIMER-INITIAL (* 180 GAME-SPEED))              ; Initialer Timerwert (Eingebene Zahl in Sekunden)
(define TICK-VALUE (/ 1 GAME-SPEED))                   ; Zeitwert für Ticks

; Initiales Universum, das Welten, Schlangen, Früchte und den Timer enthält
(define UNIVERSE (list LIST-WORLDS-INITIAL LIST-SNAKES-INITIAL LIST-FRUITS-INITIAL TIMER-INITIAL))

;; Maximale Anzahl an Spielern
(define NUM_PLAYERS 2)                                ; Zwei Spieler möglich


; Spielstatus
(define PLAYING "playing")                            ; Status: Spiel läuft
(define WAITING "waiting")                            ; Status: Warten auf Spieler
(define WIN "win")                                    ; Status: Gewonnen
(define LOOSE "loose")                                ; Status: Verloren
(define REJECTED "rejected")                          ; Status: Abgelehnt
(define TIE "tie")                                    ; Status: Unentschieden

; Funktionen, um Teile des Universums abzurufen
(define (current-worlds univ) (first univ))            ; UniverseState -> Listof iworld?; Gibt die aktuellen Welten zurück
(define (current-snakes univ) (second univ))           ; UniverseState -> List of snake; Gibt die aktuellen Schlangen zurück
(define (current-fruits univ) (third univ))            ; UniverseState -> List of item; Gibt die aktuellen Früchte zurück
(define (timer univ) (fourth univ))                    ; UniverseState -> Timer; Gibt den Timerwert zurück

; information-to-draw: UniverseState ID -> (List ID [Listof snake] [Listof item] Timer String ID)
; Funktion zur Bereitstellung der zu zeichnenden Information basierend auf dem Universum
(define (information-to-draw univ id)
  (list id (current-snakes univ) (current-fruits univ) (timer univ) PLAYING))

; UniverseState ID -> (List ID [Listof snake] [Listof item] Timer String)
; Verschiedene Spielmodi
(define (waiting-mode univ id)                                                   
  (list id (current-snakes univ) (current-fruits univ) (timer univ) WAITING))
(define (win-mode univ id)
  (list id (current-snakes univ) (current-fruits univ) (timer univ) WIN))
(define (loose-mode univ id)
  (list id (current-snakes univ) (current-fruits univ) (timer univ) LOOSE))
(define (tie-mode univ id)
  (list id (current-snakes univ) (current-fruits univ) (timer univ) TIE))

; UniverseState -> snake
; Hilfsfunktionen zum Abrufen der ersten und zweiten Schlange
(define (first-snake univ) (first (current-snakes univ)))
(define (second-snake univ) (second (current-snakes univ)))

; UniverseState -> Score
; Hilfsfunktionen zum Abrufen des Scores der ersten Schlange und des Scores der zweiten Schlange
(define (first-snake-score univ) (snake-score (first-snake univ)))
(define (second-snake-score univ) (snake-score (second-snake univ)))

; UniverseState -> iworld?
; Hilfsfunktion zum Abrufen der ersten und zweiten Welt
(define (first-world univ) (first (current-worlds univ)))
(define (second-world univ) (second (current-worlds univ)))

; add-world: UniverseState iworld? -> UniverseState
; Fügt eine neue Welt hinzu
(define (add-world univ wrld)
  (cond 
    ; Maximale Anzahl an Spielern erreicht
    ; --> Weise diese Welt ab
    [(= (length (current-worlds univ)) NUM_PLAYERS)
     (make-bundle univ
                  (list (make-mail wrld '('() '() 0 REJECTED))) ; Weltzustand mit ablehnendem Zustand
                  '())]

    ; Maximale Anzahl an Spielern mit dieser Welt erreicht
    ; --> Füge die Welt zu den bekannten hinzu
    ; --> Starte das Spiel
    [(= (length (current-worlds univ)) (- NUM_PLAYERS 1))
     (local ((define UNIV (list (append (current-worlds univ) (list wrld)) (current-snakes univ) (current-fruits univ) (timer univ))))
       (make-bundle UNIV
                    (list (make-mail wrld (information-to-draw univ (length (current-worlds UNIV)))))
                    '()))]

    ; Maximale Anzahl an Spielern noch nicht erreicht
    ; --> Füge die Welt zu den bekannten hinzu
    [(= (length (current-worlds univ)) (- NUM_PLAYERS 2))
     (local ((define UNIV (list (append (current-worlds univ) (list wrld)) (current-snakes univ) (current-fruits univ) (timer univ))))
       (make-bundle UNIV
                    (list (make-mail wrld (waiting-mode univ (length (current-worlds UNIV)))))
                    '()))]))

; detect-key: snake KeyEvent Direction -> snake
; Verarbeitet Tastatureingaben
(define (detect-key snake-input a-key snake-current-direction)
         (cond
           [(and (key=? a-key "r") (> (snake-blueberry snake-input) 0)) (activate-immunity snake-input)]
           [(and (key=? a-key " ") (> (snake-banana snake-input) 0)) (activate-booster snake-input)]
           [(and (key=? a-key "left") (not (eq? snake-current-direction 'right))) (change-direction snake-input 'left)]
           [(and (key=? a-key "right") (not (eq? snake-current-direction 'left))) (change-direction snake-input 'right)]
           [(and (key=? a-key "up") (not (eq? snake-current-direction 'down))) (change-direction snake-input 'up)]
           [(and (key=? a-key "down") (not (eq? snake-current-direction 'up))) (change-direction snake-input 'down)]
           [else snake-input]))

; activate-immunity: snake -> snake
; Erhöht ggf. Immunität der Schlange
(define (activate-immunity snake-input)
  (change-immunity snake-input (+ (snake-immunity-duration snake-input) IMMUNITY-DURATION) (- (snake-blueberry snake-input) 1)))

; change-immunity: snake Immunity-Duration Blueberry -> snake
; Passt Immunität der Schlange an.
(define (change-immunity snake-input new-immunity-duration new-blueberry)
  (snake (snake-id snake-input) (snake-coordinates snake-input) (snake-color snake-input) (snake-boost-duration snake-input) new-immunity-duration (snake-direction snake-input) 
         (snake-velocity snake-input) (snake-score snake-input) (snake-banana snake-input) new-blueberry))

; activate-booster: snake -> snake
; Erhöht ggf. Geschwindigkeit der Schlange
(define (activate-booster snake-input)
  (change-velocity snake-input (+ (snake-boost-duration snake-input) BOOST-DURATION) BOOST (- (snake-banana snake-input) 1)))

; change-velocity: snake Boost-Duration Velocity Banana -> snake
; Passt Geschwindigkeit der Schlange an.
(define (change-velocity snake-input new-velocity-duration new-velocity new-banana)
  (snake (snake-id snake-input) (snake-coordinates snake-input) (snake-color snake-input) new-velocity-duration (snake-immunity-duration snake-input) (snake-direction snake-input) 
         new-velocity (snake-score snake-input) new-banana (snake-blueberry snake-input)))

; change-direction: snake Direction -> snake
; Passt Richtung der Schlange an.
(define (change-direction snake-input new-direction)
  (snake (snake-id snake-input) (snake-coordinates snake-input) (snake-color snake-input) (snake-boost-duration snake-input) (snake-immunity-duration snake-input) new-direction 
         (snake-velocity snake-input) (snake-score snake-input) (snake-banana snake-input) (snake-blueberry snake-input)))


; handle-messages: UniverseState iworld? S-expression -> UniverseState
; Verarbeitet Tastatureingaben für das Universum und aktualisiert die Schlangen
(define (handle-messages univ wrld m)
  (let* ([worldname (iworld-name wrld)]
         [snakes (second univ)]
         [snake1 (first snakes)]
         [snake2 (second snakes)]
         [direction1 (snake-direction snake1)]
         [direction2 (snake-direction snake2)]
         [food (third univ)])
         
    (cond
      ; Prüft, ob die erste oder zweite Schlange die Eingabe erhalten hat
      [(eq? worldname (iworld-name (first-world univ)))
       (let ([new-univ (list (current-worlds univ) (list (detect-key snake1 m direction1) snake2) (current-fruits univ) (timer univ))])
         new-univ)]
      [(eq? worldname (iworld-name (second-world univ)))
       (let ([new-univ (list (current-worlds univ) (list snake1 (detect-key snake2 m direction2)) (current-fruits univ) (timer univ))])
         new-univ)]
      [else
       univ])))


; next-snake-state: snake UniverseState -> snake
; Berechnet den nächsten Zustand einer Schlange
(define (next-snake-state snake-input univ)
  (cond
    ; Anhand der Geschwindigkeit wird überprüft, ob der neue Zustand der Schlange berechnet werden soll.
    [(= (modulo (timer univ) (snake-velocity snake-input)) 0)
  (let* ([snake_coordinates (snake-coordinates snake-input)]
         [direction (snake-direction snake-input)]
         [fruits (extract-fruit-type-coordinates (current-fruits univ))]  
         [score (snake-score snake-input)]
         [banana (snake-banana snake-input)]
         [blueberry (snake-blueberry snake-input)]
         
         ; Berechne den neuen Kopf der Schlange, bevor die Bewegung stattfindet
         [new-head (cond
                     [(eq? direction 'up)    (list (first (first snake_coordinates)) (modulo (sub1 (second (first snake_coordinates))) GRID-SIZE))]
                     [(eq? direction 'down)  (list (first (first snake_coordinates)) (modulo (add1 (second (first snake_coordinates))) GRID-SIZE))]
                     [(eq? direction 'left)  (list (modulo (sub1 (first (first snake_coordinates))) GRID-SIZE) (second (first snake_coordinates)))]
                     [(eq? direction 'right) (list (modulo (add1 (first (first snake_coordinates))) GRID-SIZE) (second (first snake_coordinates)))])]
         
         ; Überprüfe, ob der neue Kopf auf dem Futter ist
         [ate-apple? (and (member new-head fruits) (eq? 'apple (list-ref fruits (sub1 (index-of fruits new-head)))))]
         [ate-banana? (and (member new-head fruits) (eq? 'banana (list-ref fruits (sub1 (index-of fruits new-head)))))]
         [ate-blueberry? (and (member new-head fruits) (eq? 'blueberry (list-ref fruits (sub1 (index-of fruits new-head)))))]
         [new-score (if ate-apple? (add1 score) score)]  ; Punkte erhöhen, wenn Futter gegessen wurde
         [new-banana (if ate-banana? (add1 banana) banana)]
         [new-blueberry (if ate-blueberry? (add1 blueberry) blueberry)]
         [new-snake-coordinates (move-snake snake-input direction ate-apple?)]  ; Schlange wächst nur, wenn Futter gegessen wurde
         [new-snake-boost-duration (if (> (snake-boost-duration snake-input) 0) (sub1 (snake-boost-duration snake-input)) 0)] ;
         [new-snake-immunity-duration (if (> (snake-immunity-duration snake-input) 0) (sub1 (snake-immunity-duration snake-input)) 0)]
         [new-snake-velocity (if (> (snake-boost-duration snake-input) 0) BOOST VELOCITY-NORMAL)])
    (snake (snake-id snake-input) new-snake-coordinates (snake-color snake-input) new-snake-boost-duration new-snake-immunity-duration (snake-direction snake-input) new-snake-velocity new-score new-banana new-blueberry))] ;Inventory muss ausgebessert werden
    [else snake-input]))


; move-snake: snake Direction Boolean -> Coordinates
; Bewegt die Schlange basierend auf der aktuellen Richtung
(define (move-snake snake-input direction grow?)
  (let ([head (first (snake-coordinates snake-input))])
    (let* ([new-head-coordinates (cond
                       [(eq? direction 'up)    (list (first head) (modulo (sub1 (second head)) GRID-SIZE))]
                       [(eq? direction 'down)  (list (first head) (modulo (add1 (second head)) GRID-SIZE))]
                       [(eq? direction 'left)  (list (modulo (sub1 (first head)) GRID-SIZE) (second head))]
                       [(eq? direction 'right) (list (modulo (add1 (first head)) GRID-SIZE) (second head))])]
           
           ; Falls die Schlange wachsen soll, wird der neue Kopf einfach hinzugefügt,
           ; ansonsten wird der Rest entsprechend angepasst
           [new-snake-coordinates (if grow?
                          (cons new-head-coordinates (snake-coordinates snake-input))  ; Schlange wächst
                          (cons new-head-coordinates (take (snake-coordinates snake-input) (sub1 (length (snake-coordinates snake-input))))))])
      new-snake-coordinates)))


; next-fruit-state: snake snake UniverseState -> [Listof item]
; Berechnet den nächsten Zustand eines Items
(define (next-fruit-state snake1 snake2 univ)
  (let* ([head1 (first (snake-coordinates snake1))]
         [head2 (first (snake-coordinates snake2))]
         [fruits-str (current-fruits univ)]
         [fruits (extract-fruit-type-coordinates (current-fruits univ))] ;fruits als Liste
         [forbidden (append (snake-coordinates snake1)
                            (snake-coordinates snake2))] ;verbietet die Felder der Schlange und das Feld direkt vor dem Kopf
         [ate-food? (or (member head1 fruits) (member head2 fruits))]
         [who-ate-food (if ate-food? (if (member head1 fruits) head1 head2) 'rejected)])
    (if ate-food?
        (new-fruit fruits-str (item (list-ref fruits (sub1 (index-of fruits who-ate-food)))
                                    (first who-ate-food)
                                    (second who-ate-food)) forbidden)
        (current-fruits univ))))

; new-fruit: [Listof item] item Coordinates -> [Listof item]
; Entfernt die gegessene Frucht und platziert 1-2 Neue
(define (new-fruit fruits fruit forbidden-fields)
  (append (create-fruit fruits (item-type fruit) forbidden-fields) (remove fruit fruits)))
    
; create-fruit: [Listof item] Type Coordinates -> [Listof item]
; Erstellt 1-2 neue Früchte
(define (create-fruit fruits type forbidden-fields)
  (let* ([randnum (random 12)]
         [x1 (first (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields))]
         [y1 (second (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields))]
         [x2 (first (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields))]
         [y2 (second (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields))]
         [fruit-choices (list
                         (list (item 'apple x1 y1))     ; Äußerst unschöner Code
                         (list (item 'banana x1 y1))
                         (list (item 'blueberry x1 y1))
                         (list (item 'apple x1 y1))
                         (list (item 'banana x1 y1))
                         (list (item 'blueberry x1 y1))
                         (list (item 'apple x1 y1))
                         (list (item 'banana x1 y1))
                         (list (item 'blueberry x1 y1))
                         (list (item 'apple x1 y1) (item 'apple x2 y2))
                         (list (item 'apple x1 y1) (item 'banana x2 y2))
                         (list (item 'apple x1 y1) (item 'blueberry x2 y2)))])
    (list-ref fruit-choices randnum)))

; correct-random: [Listof item] (List x-Coordinate y-Coordinate) Coordinates -> (List x-Coordinate y-Coordinate)
; Verhindert das Spawnen von neuen Früchten auf der Schlange und auf Früchten (in der World müssen Früchte zuerst gezeichnet werden)
(define (correct-random fruits coordinates forbidden-fields)
  (let ([ext (extract-fruit-type-coordinates fruits)])
    (if (or (member coordinates ext) (member coordinates forbidden-fields)) (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields) coordinates)))


; extract-fruit-type-coordinates: [Listof item] -> [Listof Type (List x-Coordinate y-Coordinate)]
; Hilfsfunktion: Wandelt struct-Struktur von items in [Listof item] in Listenstruktur um.
(define (extract-fruit-type-coordinates fruit-list)
  (foldl (lambda (fruit current-list)
           (append current-list (list (item-type fruit) (list (item-x-coordinate fruit) (item-y-coordinate fruit)))))
         '()
         fruit-list))


; tick-handler: UniverseState -> UniverseState
; Wird mit jedem Tick aufgerufen. Beendet das Spiel oder setzt neuen Spielzustand.
(define (tick-handler univ)
  (cond [(= (length (current-worlds univ)) NUM_PLAYERS)

         ; Überprüfen, ob es Kollisionen gab
         (cond[(eq? (check-all-collisions (first-snake univ) (second-snake univ)) #t)
               ; Überprüfen, wer mit wem kollidiert ist und Endergebnis setzen
               (cond
                 [(and (check-collision (second-snake univ) (first-snake univ)) (check-collision (first-snake univ) (second-snake univ))) (set-final-score tie-mode tie-mode univ)]
                 [(check-collision (first-snake univ) (second-snake univ)) (set-final-score loose-mode win-mode univ)]
                 [(check-collision (second-snake univ) (first-snake univ)) (set-final-score win-mode loose-mode univ)]
                 [(check-self-collision (first-snake univ)) (set-final-score loose-mode win-mode univ)]
                 [(check-self-collision (second-snake univ)) (set-final-score win-mode loose-mode univ)]
                 )
               ]
              ; Überprüfen, ob die Spielzeit abgelaufen ist.
              [(<= (timer univ) 6)
               ; Die Scores der beiden Schlangen vergleichen und das entsprechende Endergebnis setzen.
               (cond
                                    [(= (first-snake-score univ) (second-snake-score univ)) (set-final-score tie-mode tie-mode univ)]
                                    [(> (first-snake-score univ) (second-snake-score univ)) (set-final-score win-mode loose-mode univ)]
                                    [(< (first-snake-score univ) (second-snake-score univ)) (set-final-score loose-mode win-mode univ)])
               ]
              [else
               ; Neuen Spielzustand setzen
               (let*
                   ([snake1 (next-snake-state (first-snake univ) univ)]
                    [snake2 (next-snake-state (second-snake univ) univ)]
                    [fruits (next-fruit-state snake1 snake2 univ)]
                    [time (timer univ)]
                    [univ* (list (current-worlds univ) (list snake1 snake2) fruits (sub1 time))]) 
                 (make-bundle univ*
                              (list (make-mail (first-world univ) (information-to-draw univ* (snake-id (first-snake univ))))
                                    (make-mail (second-world univ) (information-to-draw univ* (snake-id (second-snake univ)))))
                              '()))
               ])]
        [else univ]
        ))

; set-final-score: Game-Status Game-Status UniverseState -> bundle
; Setzt das Endergebnis
(define (set-final-score mode-wrld1 mode-wrld2 univ)
  (make-bundle univ (list (make-mail (first-world univ) (mode-wrld1 univ SNAKE-ID1))
                    (make-mail (second-world univ) (mode-wrld2 univ SNAKE-ID2))) '()))

; check-collision: snake snake -> Boolean
; Prüft, ob der Kopf der ersten Schlange in den Koordinaten der zweiten Schlange vorkommt
(define (check-collision snake1 snake2)
  (let ([head1 (first (snake-coordinates snake1))]   ; Kopf der ersten Schlange
        [body2 (snake-coordinates snake2)])           ; Körper der zweiten Schlange
    (not (false? (member head1 body2)))))  ; Wenn der Kopf der ersten Schlange in den Koordinaten der zweiten Schlange auftaucht, gibt es eine Kollision

; check-snake-collision: snake snake -> Boolean
; Prüft, ob die beiden Schlangen kollidieren
(define (check-snake-collisions snake1 snake2)
  (or (check-collision snake1 snake2)   ; Prüft, ob snake1 mit snake2 kollidiert
      (check-collision snake2 snake1))) ; Prüft, ob snake2 mit snake1 kollidiert

; check-self-collision: snake -> Boolean
; Prüft, ob eine Schlange mit sich selbst kollidiert (Selbstkollision)
(define (check-self-collision snake)
  (let ([head (first (snake-coordinates snake))]     ; Kopf der Schlange
        [body (rest (snake-coordinates snake))])     ; Restlicher Körper der Schlange
    (not (false? (member head body)))))  ; Wenn der Kopf im Körper auftaucht, gibt es eine Selbstkollision

; check-all-collisions: snake snake -> Boolean
; Überprüft, ob eine der beiden Schlangen kollidiert (entweder mit der anderen oder mit sich selbst)
(define (check-all-collisions snake1 snake2)
  (if (or (> (snake-immunity-duration snake1) 0) (> (snake-immunity-duration snake2) 0))
  #f
  (or (check-snake-collisions snake1 snake2)  ; Kollidieren die beiden Schlangen miteinander?
      (check-self-collision snake1)           ; Kollidiert snake1 mit sich selbst?
      (check-self-collision snake2))))         ; Kollidiert snake2 mit sich selbst?


;; Erschafft das Universum mit den entsprechenden Handlern
(define (server-run)
  (universe UNIVERSE
            (on-new add-world)
            (port 9092)
            (on-msg handle-messages)
            (on-tick tick-handler TICK-VALUE)))




