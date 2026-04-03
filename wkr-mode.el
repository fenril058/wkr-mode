;;; wkr-mode.el --- major mode for writing weekly report -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2026  ril

;; Author: ril <fenril.nh@gmail.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "29.1") (markdown-mode "2.0"))
;; Keywords: outlines, convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Require emacs 29.1 or higher to use `date-to-time'.

;;; Code:

(require 'markdown-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ### Constants

(defconst wkr-mode-version "1.0.0"
  "wkr mode version number.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ### Customizable Variables

(defgroup wkr nil
  "Major mode for for writing weekly report."
  :prefix "wkr-"
  :group 'text
  :link '(url-link "https://github.com/fenril058/wkr-mode"))

(defcustom wkr-preview-email-script
  (concat (file-name-directory (buffer-file-name)) "outlook.sh")
  "Command to run markdown."
  :group 'wkr
  :type '(string))

(defcustom wkr-this-week-schedule-header-regexps "^予定$"
  "`wkr-update-weekly-plan'で使われる.
これと`wkr-this-week-result-header-regexps'の間が今週の予定と判断される."
  :group 'wkr
  :type '(string))

(defcustom wkr-this-week-result-header-regexps "^実績$"
  "`wkr-update-weekly-plan'で使われる.
これと`wkr-work-time-header-regexp'の間が今週の予定と判断される."
  :group 'wkr
  :type '(string))

(defcustom wkr-work-time-header-regexp "^### 実作業時間$"
  "`wkr-update-weekly-plan'で使われる.
これと`wkr-next-week-schedule-header-regexps'の間が作業時間の記述と判断される."
  :group 'wkr
  :type '(string))

(defcustom wkr-next-week-schedule-header-regexps "^次週予定$"
  "`wkr-update-weekly-plan'で使われる.
これ以降が次週の予定と判断される."
  :group 'wkr
  :type '(string))

(defcustom wkr-filename-header "wk"
  "ファイル名はこれに2桁の週番号が続くことが期待されている.
`wkr-increment-week-numbers-in-string'でつかわれる."
  :group 'wkr
  :type '(string))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ### Macro / Utilities

(defun wkr-preview-email ()
  "Shell scriptを実行し, mailを作成する.
Shell scriptの中身はWindowsのpython scriptの呼び出し."
  (interactive)
  (let ((cmd wkr-preview-email-script)
        (file (buffer-file-name)))
    (shell-command (concat cmd " " file))))

(defun wkr-conver-date (date)
  "Convert DATE which stayle is \"%Y/%m/%d\" to time value."
  (date-to-time (replace-regexp-in-string "/" "-" date)))

(defun wkr-update-top-date ()
  "Rewrite top line of the weekly report.
 From \\'Weekly Report n週目 (yyyy/mm/dd - yyyy/mm/dd)\\' to \\'Weekly
Report n+1週目 (yyyy/mm/dd+7 - yyyy/mm/dd+7)\\' in the buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((report-regex "Weekly Report \\([0-9]+\\)週目 (\\([0-9]+/[0-9]+/[0-9]+\\) - \\([0-9]+/[0-9]+/[0-9]+\\))"))
      (re-search-forward report-regex nil t)
      (let* ((week-number (string-to-number (match-string 1)))
             (start-date (match-string 2))
             (end-date (match-string 3))
             (next-week-number (1+ week-number))
             (start-date-time (wkr-conver-date start-date))
             (end-date-time (wkr-conver-date end-date))
             (next-start-date (format-time-string "%Y/%m/%d" (time-add start-date-time (days-to-time 7))))
             (next-end-date (format-time-string "%Y/%m/%d" (time-add end-date-time (days-to-time 7))))
             (next-report (format "Weekly Report %d週目 (%s - %s)" next-week-number next-start-date next-end-date)))
        (goto-char (point-min))
        (re-search-forward report-regex nil t)
        (replace-match next-report)))))

(defun wkr-update-reported-date ()
  "Update reported date."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((report-regex "^\\([0-9]+/[0-9]+/[0-9]+\\)"))
      (re-search-forward report-regex nil t)
      (let* ((start-date (match-string 1))
             (start-date-time (wkr-conver-date start-date))
             (next-start-date (format-time-string "%Y/%m/%d" (time-add start-date-time (days-to-time 7)))))
        (goto-char (point-min))
        (re-search-forward report-regex nil t)
        (replace-match next-start-date)))))

(defun wkr-update-weekly-plan ()
  "【次週予定】を【予定】と【実績】にコピーする."
  (interactive)
  (save-excursion
    (wkr-update-top-date)
    (wkr-update-reported-date)
    (goto-char (point-min))
    (let ((begin (re-search-forward
                  wkr-this-week-schedule-header-regexps
                  (point-max) t))
          (end (progn
                 (re-search-forward
                  wkr-this-week-result-header-regexps
                  (point-max) t)
                 (pos-bol))))
      (when (and begin end) (kill-region begin (- end 1)))
      (setq begin (progn
                    (re-search-backward
                     wkr-this-week-result-header-regexps
                     (point-min) t)
                    (pos-eol))
            end (progn
                  (re-search-forward
                   wkr-work-time-header-regexp
                   (point-max) t)
                  (pos-bol)))
      (when (and begin end) (kill-region begin (- end 1)))
      (setq begin (re-search-forward
                   wkr-next-week-schedule-header-regexps
                   (point-max) t)
            end (progn
                  (re-search-forward "^<!--+>" (point-max) t)
                  (pos-bol)))
      (when (and begin end)
        (kill-ring-save begin (- end 1))
        (goto-char (point-min))
        (re-search-forward
         wkr-this-week-schedule-header-regexps
         (point-max) t)
        (yank)
        (re-search-forward
         wkr-this-week-result-header-regexps
         (point-max) t)
        (yank)
        ))))

(defun wkr-increment-week-numbers-in-string (input-string)
  "Increment all week numbers in the format \\'wkNN\\' within the given INPUT-STRING."
  (let ((start 0))
    (while (string-match (concat wkr-filename-header "\\([0-9]+\\)") input-string start)
      (let* ((week-number (string-to-number (match-string 1 input-string)))
             (next-week-number (1+ week-number))
             (next-week (format (concat wkr-filename-header "%02d") next-week-number)))
        (setq input-string (replace-match next-week t t input-string))
        (setq start (match-end 0))))
    input-string))

(defun wkr-update-weekly ()
  "週番号をincrementしたファイルを新しく作り、内容を更新する."
  (interactive)
  (let* ((old-name (buffer-file-name))
         (new-name (wkr-increment-week-numbers-in-string old-name)))
    (if (eq new-name old-name)
        (message "Something wrong: new and old file name are the same.")
      (write-file new-name)
      (wkr-update-weekly-plan)
      (message "Create New Weekly Report."))))

;;;###autoload
(defun wkr-cleanup ()
  "Formatting weekly report.
- Delete \\r (carriage return)
- Replace full-width spaces with half-width spaces
- Replace tabs with half-width spaces

主に他人のWeeklyreportの体裁を整えるために使う。"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (search-forward "" nil t nil)
      (replace-match ""))
    (goto-char (point-min))
    (while (search-forward "　" nil t nil)
      (replace-match "  "))
    (while (search-forward "	" nil t nil)
      (replace-match "    "))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ### Major Mode

;;;###autoload
(define-derived-mode wkr-mode
  markdown-mode
  "Wkr"
  "Major mode for writing Weekly Report.
  \\{wkr-mode-map}"
  (setq case-fold-search nil)
  (display-fill-column-indicator-mode 1)
  (define-key wkr-mode-map (kbd "C-c C-u") 'wkr-update-weekly)
  (define-key wkr-mode-map (kbd "C-c C-c") 'wkr-preview-email))

(provide 'wkr-mode)
;;; wkr-mode.el ends here
