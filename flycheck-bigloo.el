;;;; Copyright(c) 2013 Joseph Donaldson(donaldsonjw@yahoo.com)
;;;; This file is part of flycheck-bigloo.
;;;;
;;;; flycheck-bigloo is free software: you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as
;;;; published by the Free Software Foundation, either version 3 of the
;;;; License, or (at your option) any later version.
;;;;
;;;; flycheck-bigloo is distributed in the hope that it will be useful, but
;;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;;;; General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public
;;;; License along with flycheck-bigloo. If not, see
;;;; <http://www.gnu.org/licenses/>.
;;;; Copyright(c) 2013 Joseph Donaldson(donaldsonjw@yahoo.com) 

(provide 'flycheck-bigloo)
(require 'flycheck)



(flycheck-def-option-var flycheck-bigloo-buildfile-list
    '("GNUmakefile" "makefile" "Makefile")
    flycheck-bigloo
    "*The list of buildfile(makefile) names to search for"
  :type '(repeat (string)))


(flycheck-def-option-var flycheck-bigloo-buildfile-target 
    "check-syntax" 
    flycheck-bigloo
  "*The name of the flycheck check syntax target"
  :type 'string)


(flycheck-def-option-var flycheck-bigloo-buildfile 
    nil 
    flycheck-bigloo
  "*the name of the bigloo buildfile"
  :type 'string)

(flycheck-def-option-var flycheck-bigloo-buildfile-dir 
    nil 
    flycheck-bigloo
  "*the name of the bigloo buildfile dir"
  :type 'string)

(flycheck-def-option-var flycheck-bigloo-error-regexps
    '("File \"\\(?1:[^\"]+\\)\", line \\(?2:[0-9]+\\), character \\([0-9]+\\):[\012]\\(?4:\\(.+[\012]\\)+\\)"
      "\\(?:\*\*\* \\(?4:ERROR:\\(.+[\012]\\)\\{2\\}\\)\\)")
    flycheck-bigloo
  "*The list of bigloo error regexps"
  :type '(repeat (string)))

(flycheck-def-option-var flycheck-bigloo-standalone-command
    '("bigloo" "-ast" source-inplace)
    flycheck-bigloo
  "*The flycheck command list used by the flycheck syntax checker bigloo-standalone"
  :type 'sexp)

(flycheck-def-option-var flycheck-bigloo-make-command
    '( "make"
	      (option "-f" flycheck-bigloo-buildfile)
	      (option "-C" flycheck-bigloo-buildfile-dir)
	      (eval flycheck-bigloo-buildfile-target) 
	      (eval (let ((fname (flycheck-save-buffer-to-temp #'flycheck-temp-file-inplace "flycheck")))
		      
		      (add-to-list 
		       'flycheck-temp-files
		       (concat (file-name-directory (expand-file-name fname))
			       (trim-common-prefix (expand-file-name flycheck-bigloo-buildfile-dir) 
						   (expand-file-name fname))))
		      (format "CHK_SOURCES=%s" (flycheck-save-buffer-to-temp #'flycheck-temp-file-inplace "flycheck"))))
	      source-inplace
	      )
    flycheck-bigloo
  "*The flycheck command list used by the flycheck syntax checker bigloo-make"
  :type 'sexp)
  

;;;; utility procedures

(defun parent-dir (path)
  (file-name-directory (directory-file-name path)))


(defun flycheck-bigloo-find-buildfile-dir (start-dir)
  "Search from start-dir looking for sutiable makefile containing a flycheck
check-syntax target. If one is found return its location, otherwise return
nil"
  (catch 'found
    (let ((curr-dir start-dir))
      (while curr-dir
	(dolist (name flycheck-bigloo-buildfile-list)
	  (let ((result (locate-dominating-file curr-dir name)))
	    (when (and result
		       (file-contains-flycheck-target-p
			(concat (file-name-as-directory result) name)))
	      (setq-local flycheck-bigloo-buildfile 
			  name)
	      (setq-local flycheck-bigloo-buildfile-dir 
			  (file-name-as-directory result))
	      (throw 'found result))))
	(setq curr-dir (parent-dir curr-dir)))
	nil)))

(defun file-contains-flycheck-target-p (filename)
  "does the file contain a check-syntax target?"
  (save-excursion
    (let* ((buffer (find-file filename))
(result (search-forward flycheck-bigloo-buildfile-target nil t)))
      (kill-buffer buffer)
      result)))


(defun check-syntax-target-exists-p()
  (let* ((source-file-name buffer-file-name)
	 (source-dir (file-name-directory buffer-file-name))
	 (buildfile-dir (flycheck-bigloo-find-buildfile-dir source-dir)))
    (and buildfile-dir t)))


(defun trim-common-prefix (prefix str)
  (string-match prefix str)
  (substring str (match-end 0)))


(defun flycheck-bigloo-get-regexp ()
  "create a single regexp including all defined error regexps"
  (s-join "\\|" (--map (format "\\(?:%s\\)" it) flycheck-bigloo-error-regexps)))

(defun flycheck-bigloo-match-string-non-empty (match count)
  (let ((res (nth count match)))
    (if (string= "" res)
	nil
      res)))

(defun flycheck-bigloo-match-int (match count)
  (let ((res (nth count match)))
    (if (and (stringp res) 
	     (not (string= "" res)))
	(string-to-number res)
      1)))

(defun flycheck-bigloo-get-error-msgs (output)
  "return a list of errors  contained in output"
  (let ((regexp (flycheck-bigloo-get-regexp))
	(err-msgs nil)
	(last-match 0))
    (while (string-match regexp output last-match)
      (setq err-msgs (cons (match-string 0 output) err-msgs))
      (setq last-match (match-end 0)))
    err-msgs))

(defun flycheck-bigloo-get-errors (err-msgs)
  (let ((errs nil))
    (dolist (msg err-msgs errs)
      (catch 'exit 
	(dolist (regexp flycheck-bigloo-error-regexps)
	  (let ((match (s-match regexp msg)))
	    (when match
	      (let ((file-name (buffer-file-name))
		    (line (flycheck-bigloo-match-int match 2))
		    (message (flycheck-bigloo-match-string-non-empty match 4)))
		(setq errs (cons (flycheck-error-new 
				  :filename file-name
				  :line  line
				  :message message
				  :level 'error)
				 errs))
		(throw 'exit nil)))))))))



(defun flycheck-bigloo-parse-errors (output checker buffer)
  "Parse bigloo errors from output"
  (let ((res (flycheck-bigloo-get-errors
	      (flycheck-bigloo-get-error-msgs output))))
    res))
  

(flycheck-declare-checker bigloo-make
  "a syntax checker for bigloo scheme"
  :command flycheck-bigloo-make-command
  :error-parser 'flycheck-bigloo-parse-errors
  :modes 'bee-mode
  :predicate '(check-syntax-target-exists-p))



(flycheck-declare-checker bigloo-standalone
  "a syntax checker for bigloo scheme"
  :command flycheck-bigloo-standalone-command
  :error-parser 'flycheck-bigloo-parse-errors
  :modes 'bee-mode
  :predicate '(not (check-syntax-target-exists-p)))


(add-to-list 'flycheck-checkers 'bigloo-standalone)
(add-to-list 'flycheck-checkers 'bigloo-make)







(add-hook 'bee-mode-hook (lambda ()
			   (flycheck-mode 1)))



