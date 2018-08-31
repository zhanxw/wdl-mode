;;; wdl-mode.el --- WDL (Workflow Definition Language) major mode

;; Copyright (C) 2018 Xiaowei Zhan

;; Author: Xiaowei Zhan <zhanxw@gmail.com>
;; URL: http://github.com/zhanxw/wdl-mode
;; Version: 20170709
;; Created: 14 Jul 2010
;; Keywords: languages

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package provides a major mode for WDL (Workflow Definition Language).
;; It supports basic font-lock highlights and indentation.
;;
;; Installation instructions:
;;
;;   Use MELPA (easier)
;;
;;     1. Install MELPA (https://melpa.org/#/getting-started)
;;     2. In Emacs, M-x package-list-package, 
;;        select `wdl-mode`, 
;         press `i` to mark it for installation, 
;;        then press `x` to perform installation.
;;
;;   Manual installation
;; 
;;   $ cd YOUR_GIT_DIRECTORY
;;   $ git clone https://github.com/zhanxw/wdl-mode.git
;;
;; and add EITHER the following line to your .emacs file
;;     (require 'wdl-mode "YOUR_GIT_DIRECTORY/wdl-mode/wdl-mode.el" t)
;;
;; to always load the mode, OR make it autoload by adding the following:
;;
;;     (add-to-list 'auto-mode-alist '("\\.wdl\\'" . wdl-mode))
;;     (autoload 'wdl-mode YOUR_GIT_DIRECTORY/wdl-mode/wdl-mode.el" nil t)
;;
;; and execute it (or restart emacs). 
;; 
;; Customization:
;;     to customize indentaiton, add something like this to your .emacs: 
;;
;;     (setq wdl-indent-level 4)
;;

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Syntax table and font-lock types
(defvar wdl-mode-syntax-table nil "Syntax table for `wdl-mode'.")

(defvar wdl-indent-level 2
  "Indentation of statements with respect to containing block.")

(setq wdl-mode-syntax-table
      (let ( (synTable (make-syntax-table)))
        ;; python style comment: “# …”
        (modify-syntax-entry ?# "<" synTable)
        (modify-syntax-entry ?\n ">" synTable)
        (modify-syntax-entry ?_ "w" synTable)  ;; treat a_b as part of the word
        synTable))

(defconst wdl-keywords
      '("call" "runtime" "task" "workflow" "if" "then" "else" "import" "as" "input" "output" "meta" "parameter_meta" "scatter" "command")
      "Syntax table for `wdl-mode'.")

(defconst wdl-font-lock-keywords
      (let* (
             ;; define several categories
             (x-keywords wdl-keywords)
             (x-types '("Array" "Boolean" "File" "Float" "Int" "Map" "Object" "String" "Pair"))
             (x-constants '("true" "false"))
             (x-functions '("stdout" "stderr"
                            "read_lines" "read_tsv" "read_map" "read_object" "read_objects" "read_json" "read_int" "read_string" "read_float" "read_boolean"
                            "write_lines" "write_tsv" "write_map" "write_object" "write_objects" "write_json"
                            "size" "sub" "range" "transpose" "zip" "cross" "length" "prefix" "select_first" "select_all" "defined"
                            "basename" "floor" "ceil" "round"
                            ))

             ;; generate regex string for each category of keywords
             (x-keywords-regexp (regexp-opt x-keywords 'words))
             (x-types-regexp (regexp-opt x-types 'words))
             (x-constants-regexp (regexp-opt x-constants 'words))
             (x-functions-regexp (regexp-opt x-functions 'words)))

      `(
        (,x-types-regexp . font-lock-type-face)
        (,x-constants-regexp . font-lock-constant-face)
        (,x-functions-regexp . font-lock-function-name-face)
        (,x-keywords-regexp . font-lock-keyword-face))
      )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Auto completion
(defun wdl-completion-at-point ()
  "This is the function to be used for the hook `completion-at-point-functions'."
  (interactive)
  (let* (
         (bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end wdl-keywords . nil)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Indentation
;; heavily borrowed from https://www.emacswiki.org/emacs/wpdl-mode.el
(defun wdl-indent-line ()
  "Indent current line as WDL code."
  (interactive)
  (beginning-of-line)
  (if (bobp)
      (indent-line-to 0)   ; First line is always non-indented
    (let ((not-indented t) cur-indent)
      (if (looking-at "^[^{\n]*\\(>>>\\|}\\)$") ; If the line we are looking at is the end of a block, then decrease the indentation
          (progn
            (save-excursion
              (forward-line -1)
              (setq cur-indent (- (current-indentation) wdl-indent-level)))
            (if (< cur-indent 0) ; We can't indent past the left margin
                (setq cur-indent 0)))
        (save-excursion
          (while not-indented ; Iterate backwards until we find an indentation hint
            (forward-line -1)
            (if (looking-at "^[^{\n]*\\(>>>\\|}\\)$") ; This hint indicates that we need to indent at the level of the END_ token
                (progn
                  (setq cur-indent (current-indentation))
                  (setq not-indented nil))
              (if (looking-at "^.*\\(<<<\\|{\\)$") ; This hint indicates that we need to indent an extra level
                  (progn
                    (setq cur-indent (+ (current-indentation) wdl-indent-level)) ; Do the actual indenting
                    (setq not-indented nil))
                (if (bobp)
                    (setq not-indented nil)))))))
      (if cur-indent
          (indent-line-to cur-indent)
        (indent-line-to 0))))) ; If we didn't see an indentation hint, then allow no indentation


;;;###autoload
(define-derived-mode wdl-mode prog-mode "wdl mode"
  "Major mode for editing WDL (Workflow Definition Language)"

  ;; code for syntax highlighting
  (set-syntax-table wdl-mode-syntax-table)
  (setq font-lock-defaults '((wdl-font-lock-keywords)))
  (add-hook 'completion-at-point-functions 'wdl-completion-at-point nil 'local)
  ;; Register our indentation function
  (set (make-local-variable 'indent-line-function) 'wdl-indent-line)
  )

;; add the mode to the `features' list
(provide 'wdl-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.wdl\\'" . wdl-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; useless codes
;; (defconst demo-triple-quoted-string-regex
;;   (rx "\"\"\""))

;; (defun demo-stringify-triple-quote ()
;;   "Put `syntax-table' property on triple-quoted strings."
;;   (let* ((string-end-pos (point))
;;          (string-start-pos (- string-end-pos 3))
;;          (ppss (prog2
;;                    (backward-char 3)
;;                    (syntax-ppss)
;;                  (forward-char 3))))
;;     (unless (nth 4 (syntax-ppss)) ;; not inside comment
;;       (if (nth 8 (syntax-ppss))
;;           ;; We're in a string, so this must be the closing triple-quote.
;;           ;; Put | on the last " character.
;;           (put-text-property (1- string-end-pos) string-end-pos
;;                              'syntax-table (string-to-syntax "|"))
;;         ;; We're not in a string, so this is the opening triple-quote.
;;         ;; Put | on the first " character.
;;         (put-text-property string-start-pos (1+ string-start-pos)
;;                            'syntax-table (string-to-syntax "|"))))))

;; (defconst demo-syntax-propertize-function
;;   (syntax-propertize-rules
;;    (demo-triple-quoted-string-regex
;;         (0 (ignore (demo-stringify-triple-quote))))))

;;; wdl-mode.el ends here
