;;; quil-mode.el --- Quil mode for Emacs             -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Rigetti Computing

;; Author: Juan M. Bello-Rivas <jbellorivas@rigetti.com>
;; Keywords: quil, languages

;;; Commentary:

;; Major mode for editing Quil code.
;;
;; To use it, add the following line to your Emacs init file:
;;     (add-to-list 'auto-mode-alist '("\\.quil" . quil-mode))

;;; Code:

(defgroup quil nil
  "Mode for editing Quil programs."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :prefix "quil-"
  :group 'languages)

(defcustom quil-mode-hook nil
  "Hook called by `quil-mode`."
  :type 'hook
  :group 'quil)

(defconst quil-font-lock-keywords
  '(("\\#.*" (0 font-lock-comment-face t))
    ("%[a-zA-z][a-zA-Z0-9]*" . font-lock-variable-name-face)
    ("\\_<\\(?:AS\\|BIT\\|C\\(?:AN\\|CNOT\\|NOT\\|ONTROLLED\\|PHASE\\(?:0[01]\\|10\\)?\\|SWAP\\|Z\\)\\|D\\(?:AGGER\\|E\\(?:CLARE\\|F\\(?:CIRCUIT\\|GATE\\)\\)\\)\\|FORKED\\|HALT\\|I\\(?:N\\(?:CLUDE\\|TEGER\\)\\|SWAP\\)\\|JUMP\\(?:-\\(?:UNLESS\\|WHEN\\)\\)?\\|L\\(?:ABEL\\|OAD\\)\\|M\\(?:ATRIX\\|\\(?:EASUR\\|OV\\)E\\)\\|O\\(?:\\(?:CT\\|FFS\\)ET\\)\\|P\\(?:ERMUTATION\\|HASE\\|ISWAP\\|RAGMA\\|SWAP\\)\\|R\\(?:E\\(?:AL\\|SET\\)\\|[XYZ]\\)\\|SHARING\\|WAIT\\|XY\\|[HISTXYZ]\\)\\_>" . font-lock-keyword-face))
  "Default `font-lock-keywords' for Quil mode.")

;;;###autoload
(define-derived-mode quil-mode prog-mode "Quil"
  "Emacs mode for Quil programs."
  ;; :group quil
  (setq-local comment-start "#")
  (setq-local parse-sexp-ignore-comments t)
  (setq-local font-lock-defaults '(quil-font-lock-keywords nil)))

(provide 'quil-mode)
;;; quil-mode.el ends here
