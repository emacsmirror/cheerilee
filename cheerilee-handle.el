;;; cheerilee-handle.el --- Handling events -*- lexical-binding: t -*-

;; Copyright (C) 2015 Alessio Vanni

;; Author: Alessio Vanni <vannilla@airmail.cc>
;; Created: December 2015

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This file provides functions to handle events.

;;; Code:
(require 'cheerilee-classes)
(require 'cheerilee-core)

;; Behold the heavy copy&paste used here!

(defun cheerilee-configure-notify-event (data fake)
    "Event triggered when something happens to the frame.

As an event, it associates DATA with a new instance of the correct event.
FAKE is used to determine if the event
is synthetic (i.e. sent with the function `xcb:SendEvent')."
    (let ((ev (make-instance 'xcb:ConfigureNotify)))
      (xcb:unmarshal ev data)
      (with-slots (event window x y width height) ev
	(let* ((fr (cheerilee-get-frame event cheerilee--model-tree))
	       (o (nth 1 fr)))
	  (oset o location (cons x y))
	  (oset o size (cons width height))
	  (if (< cheerilee--clear-delay 2)
	      (setq cheerilee--clear-delay (1+ cheerilee--clear-delay))
	    (cheerilee-clear-area fr)
	    (setq cheerilee--clear-delay 0))))))

(defun cheerilee-motion-notify-event (data fake)
  "Event triggered when the mouse cursor moves.

As an event, it associates DATA with a new instance of the correct event.
FAKE is used to determine if the event
is synthetic (i.e. sent with the function `xcb:SendEvent')."
  (let ((ev (make-instance 'xcb:MotionNotify)))
    (xcb:unmarshal ev data)
    (with-slots (event event-x event-y) ev
      (let* ((fr (cheerilee-get-frame event cheerilee--model-tree))
	     (lst (nthcdr 4 fr)))
	(cheerilee--apply-function fr #'cheerilee--motion-notify
				   event-x event-y fr)))))

(defun cheerilee-button-press-event (data fake)
    "Event triggered when a mouse button is pressed.

As an event, it associates DATA with a new instance of the correct event.
FAKE is used to determine if the event
is synthetic (i.e. sent with the function `xcb:SendEvent')."
  (let ((ev (make-instance 'xcb:ButtonPress)))
    (xcb:unmarshal ev data)
    (with-slots (detail event event-x event-y) ev
      (let* ((fr (cheerilee-get-frame event cheerilee--model-tree))
	     (lst (nthcdr 4 fr)))
	(cheerilee--apply-function fr #'cheerilee--button-press
				   event-x event-y detail fr)))))

(defun cheerilee-button-release-event (data fake)
  "Event triggered when a mouse button is released.

As an event, it associates DATA with a new instance of the correct event.
FAKE is used to determine if the event
is synthetic (i.e. sent with the function `xcb:SendEvent')."
  (let ((ev (make-instance 'xcb:ButtonPress)))
    (xcb:unmarshal ev data)
    (with-slots (detail event event-x event-y) ev
      (let* ((fr (cheerilee-get-frame event cheerilee--model-tree))
	     (lst (nthcdr 4 fr)))
	(cheerilee--apply-function lst #'cheerilee--button-release
				   event-x event-y detail fr)))))

(defun cheerilee-key-press-event (data fake)
  "Event triggered when a keyboard button is pressed.

As an event, it associates DATA with a new instance of the correct event.
FAKE is used to determine if the event
is synthetic (i.e. sent with the function `xcb:SendEvent')."
  (let ((ev (make-instance 'xcb:ButtonPress)))
    (xcb:unmarshal ev data)
    (with-slots (detail event state) ev
      (let ((lst (nthcdr 4 (cheerilee-get-frame event cheerilee--model-tree))))
	(cheerilee--apply-function lst #'cheerilee--key-press
				   detail state)))))

(defun cheerilee-key-release-event (data fake)
    "Event triggered when a keyboard button is released.

As an event, it associates DATA with a new instance of the correct event.
FAKE is used to determine if the event
is synthetic (i.e. sent with the function `xcb:SendEvent')."
  (let ((ev (make-instance 'xcb:ButtonPress)))
    (xcb:unmarshal ev data)
    (with-slots (detail event state) ev
      (let ((lst (nthcdr 4 (cheerilee-get-frame event cheerilee--model-tree))))
	(cheerilee--apply-function lst #'cheerilee--key-release
				   detail state)))))

(defun cheerilee-add-motion-event (tree id fun)
  "Associate to each element of TREE called ID the function FUN."
  (let ((bts (cheerilee-search-by-id tree id)))
    (dolist (el bts)
      (push fun (oref (nth 1 el) motion-note)))))

(defun cheerilee-add-button-press-event (tree id fun)
  "Associate to each element of TREE called ID the function FUN."
  (let ((bts (cheerilee-search-by-id tree id)))
    (dolist (el bts)
      (push fun (oref (nth 1 el) button-press)))))

(defun cheerilee-add-button-release-event (tree id fun)
  "Associate to each element of TREE called ID the function FUN."
  (let ((bts (cheerilee-search-by-id tree id)))
    (dolist (el bts)
      (push fun (oref (nth 1 el) button-rel)))))

(defun cheerilee-add-key-press-event (tree id fun)
  "Associate to each element of TREE called ID the function FUN."
  (let ((bts (cheerilee-search-by-id tree id)))
    (dolist (el bts)
      (push fun (oref (nth 1 el) key-press)))))

(defun cheerilee-add-key-release-event (tree id fun)
  "Associate to each element of TREE called ID the function FUN."
  (let ((bts (cheerilee-search-by-id tree id)))
    (dolist (el bts)
      (push fun (oref (nth 1 el) key-release)))))

(defmethod cheerilee--motion-notify ((ctrl cheerilee-control) x y tree)
  "Execute CTRL's Mouse Motion Notify handling functions.

X and Y are used to determine the location of the mouse; TREE is the
application in which the event happened."
  (dolist (el (oref ctrl motion-note))
    (funcall el ctrl x y (list tree))))

(defmethod cheerilee--button-press ((ctrl cheerilee-control) x y detail tree)
  "Execute CTRL's Mouse Button Press handling functions.

X and Y are used to determine the location of the mouse; DETAIL is a
description of the button that generated the event; TREE is the
application in which the event happened."
  (let ((cr (oref ctrl clip-region)))
    (when (and (<= (nth 0 cr) x (+ (nth 0 cr) (nth 2 cr)))
	       (<= (nth 1 cr) y (+ (nth 1 cr) (nth 3 cr)))
	       (null (oref ctrl capture)))
      (oset ctrl capture t)
      (dolist (el (oref ctrl button-press))
	(funcall el ctrl detail x y (list tree))))))

(defmethod cheerilee--button-release ((ctrl cheerilee-control) x y detail tree)
  "Execute CTRL's Mouse Button Release handling functions.

X and Y are used to determine the location of the mouse; DETAIL is a
description of the button that generated the event; TREE is the
application in which the event happened."
  (let ((cr (oref ctrl clip-region)))
    (when (eq (oref ctrl capture) t)
      (oset ctrl capture nil))
    (when (and (<= (nth 0 cr) x (+ (nth 0 cr) (nth 2 cr)))
	       (<= (nth 1 cr) y (+ (nth 1 cr) (nth 3 cr))))
      (dolist (el (oref ctrl button-rel))
	(funcall el ctrl detail x y (list tree))))))

(defmethod cheerilee--key-press ((ctrl cheerilee-control) detail modifier)
  "Execute CTRL's Keyboard Button Press handling functions.

X and Y are used to determine the location of the mouse; DETAIL is a
description of the button that generated the event; TREE is the
application in which the event happened."
  (dolist (el (oref ctrl key-press))
    (funcall el ctrl detail)))

(defmethod cheerilee--key-release ((ctrl cheerilee-control) detail modifier)
    "Execute CTRL's Keyboard Button Release handling functions.

X and Y are used to determine the location of the mouse; DETAIL is a
description of the button that generated the event; TREE is the
application in which the event happened."
  (dolist (el (oref ctrl key-release))
    (funcall el ctrl detail)))

(provide 'cheerilee-handle)

;;; cheerilee-handle.el ends here