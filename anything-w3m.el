;;; anything-w3m.el --- some w3m commands using anything.el

;; Author: IMAKADO <ken.imakado@gmail.com>
;; Keywords: w3m

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;; Prefix: anything-w3m-

;;; Commentary:

;; Some w3m commands using anything.el

;; M-x anything-w3m-ahead   to select link using anything

;; Tested on Emacs 22

;;; Code:

(require 'w3m-load)

(defun anything-w3m-ahead ()
  (interactive)
  (let* ((previous-ahead (ignore-errors
                              (anything-w3m-ahead-get-previous-ahead-string)))
         (previous-ahead-re (or previous-ahead (concat "^" previous-ahead "$")))) 
    (anything 'anything-w3m-ahead-source nil nil nil
              previous-ahead-re)))

(defun anything-w3m-ahead-cands ()
  (require 'w3m-type-ahead)
  (with-current-buffer anything-current-buffer
    (cond
     (w3m-current-process
      (message "Can't type ahead while W3M is retrieving."))
     (t
      ;; Update hash table containing anchors
      (w3m-type-ahead-get-anchors)
      ;; Create buffer containing links
      (w3m-type-ahead-setup-buffer)
      (let ((buf-str (with-current-buffer (get-buffer "*w3m-type-ahead*")
                       (buffer-string))))
        (with-current-buffer (anything-candidate-buffer 'global)
          (insert buf-str)))))))

(defun anything-w3m-ahead-get-previous-ahead-string ()
  (save-excursion
    (let (anchor end face start string value)
      (setq start
            ;; If there are two adjacent anchors, we may
            ;; already be in the right place
            (if (get-text-property (point) 'w3m-anchor-sequence)
                (point)
              (previous-single-property-change (point)
                                           'w3m-anchor-sequence)))
      (goto-char start)
      (setq anchor (get-text-property (point) 'w3m-anchor-sequence)
            face (get-text-property (point) 'face)
            end (previous-single-property-change (point) 'w3m-anchor-sequence)
            string (buffer-substring start end))

      (setq string
            (cond
             ((fboundp 'replace-regexp-in-string)
              (replace-regexp-in-string "\\s-+$" "" string))
             ((fboundp 'replace-in-string)
                (replace-in-string string "\\s-+$" ""))
             ((and (require 'dired)
                   (fboundp 'dired-replace-in-string))
              (dired-replace-in-string "\\s-+$" "" string))
               (t
                (error "No replace in string function"))))
      string)))

(defun anything-w3m-view-this-url (link &optional new-session)
  (let ((selected (with-temp-buffer
                    (insert link)
                    (goto-char (point-min))
                    (or (get-text-property (point) 'anchor)
                        (next-single-property-change (point-min)
                                                     'anchor)
                        (error "no w3m-anchor-sequence!!")))))
    (with-current-buffer anything-current-buffer
      (goto-char (text-property-any (point-min) (point-max)
                                    'w3m-anchor-sequence selected))
      (w3m-view-this-url w3m-type-ahead-reload new-session))))

(defvar anything-w3m-ahead-source
  `((name . "ahead")
    (candidates-in-buffer)
    (init . anything-w3m-ahead-cands)
    (action . (("view-this-url" . anything-w3m-view-this-url)
               ("view-this-url-with-new-session" .
                (lambda (c)
                  (anything-w3m-view-this-url c t)))) )
    (get-line . buffer-substring)
    (migemo)))

(provide 'anything-w3m)
