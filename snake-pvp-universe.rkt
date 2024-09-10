;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname snake-pvp-universe) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
#lang racket
(require 2htdp/universe)
(require test-engine/racket-tests)

; UniverseState is [Listof iworld?]
; StopMessage is 'done.
; GoMessage is 'it-is-your-turn.

; [Listof iworld?] iworld? -> Result
; add world iw to the universe, when server is in state u
(check-expect
  (add-world '() iworld1)
  (make-bundle (list iworld1)
               (list (make-mail iworld1 'it-is-your-turn))
               '()))

(define (add-world univ wrld)
  (local ((define univ* (append univ (list wrld))))
    (make-bundle univ*
                 (list (make-mail (first univ*) 'it-is-your-turn))
                 '())))

; [Listof iworld?] iworld? StopMessage -> Result
; world iw sent message m when server is in state u
(check-expect
 (switch (list iworld1 iworld2) iworld1 'done)
 (make-bundle (list iworld2 iworld1)
              (list (make-mail iworld2 'it-is-your-turn))
              '()))

(define (switch univ wrld m)
  (local ((define univ* (append (rest univ) (list (first univ)))))
    (make-bundle univ*
                 (list (make-mail (first univ*) 'it-is-your-turn))
                 '())))

; Start the universe
(universe '() (on-new add-world) (on-msg switch))