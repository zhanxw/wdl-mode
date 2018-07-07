;; a simple major mode, mywdl-mode

(defvar wpdl-mode-hook nil)

(defvar wdl-mode-syntax-table nil "Syntax table for `wdl-mode'.")

(setq wdl-mode-syntax-table
      (let ( (synTable (make-syntax-table)))
        ;; python style comment: “# …”
        (modify-syntax-entry ?# "<" synTable)
        (modify-syntax-entry ?\n ">" synTable)
        (modify-syntax-entry ?_ "w" synTable)
        synTable))

(setq wdl-font-lock-keywords
      (let* (
             ;; define several categories
             (x-keywords '("call" "runtime" "task" "workflow" "if" "then" "else" "import" "as" "input" "output" "meta" "parameter_meta" "scatter"))
             (x-types '("Array" "Boolean" "File" "Float" "Int" "Map" "Object" "String" "Pair"))
             (x-constants '("true" "false"))
             (x-functions '("read_lines" "stdout"))

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

;; this is your lang's keywords
(setq wdl-keywords
      '("call" "runtime" "task" "workflow" "if" "then" "else" "import" "as" "input" "output" "meta" "parameter_meta" "scatter"))

(defun wdl-completion-at-point ()
  "This is the function to be used for the hook `completion-at-point-functions'."
  (interactive)
  (let* (
         (bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end wdl-keywords . nil)))

;;;###autoload
(define-derived-mode wdl-mode prog-mode "wdl mode"
  "Major mode for editing WDL (Workflow Definition Language)"

  ;; code for syntax highlighting
  (set-syntax-table wdl-mode-syntax-table)
  (setq font-lock-defaults '((wdl-font-lock-keywords)))
  (add-hook 'completion-at-point-functions 'wdl-completion-at-point nil 'local)
  )

;; add the mode to the `features' list
(provide 'wdl-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.wdl\\'" . wdl-mode))

