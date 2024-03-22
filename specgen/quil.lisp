;;;; Author: Robert Smith

(defpackage #:quil-spec-gen
  (:use #:cl)
  (:export #:write-quil-spec))

(in-package #:quil-spec-gen)

;;; Organization of files

(defun spec/ (relative-path)
  ;; Location of the specification verbiage
  (merge-pathnames relative-path
                   (asdf:system-relative-pathname ':quil-spec-gen "specgen/spec/")))

(defun site/ (relative-path)
  ;; Location of the generated HTNL site
  (merge-pathnames relative-path
                   (asdf:system-relative-pathname ':quil-spec-gen "specgen/site/")))


;;; Scriptum Commands

(defvar *commands* (make-hash-table :test 'eq))

(defclass titled-mixin ()
  ((title :initarg :title :reader title)))

(defclass body-mixin ()
  ((body :initarg :body :reader body)))

(defclass paragraph (body-mixin)
  ())
(setf (gethash 'paragraph *commands*) 'paragraph)
(setf (gethash 'p *commands*) 'paragraph)

(defclass aside (body-mixin)
  ())
(setf (gethash 'aside *commands*) 'aside)


(defclass inline-code (body-mixin)
  ())
(setf (gethash 'inline-code *commands*) 'inline-code)
(setf (gethash 'c *commands*) 'inline-code)

(defclass display-code (body-mixin)
  ())
(setf (gethash 'display-code *commands*) 'display-code)
(setf (gethash 'clist *commands*) 'display-code)

(defclass inline-math (body-mixin)
  ())
(setf (gethash 'inline-math *commands*) 'inline-math)
(setf (gethash 'm *commands*) 'inline-math)

(defclass display-math (body-mixin)
  ())
(setf (gethash 'display-math *commands*) 'display-math)
(setf (gethash 'dm *commands*) 'display-math)

(defclass hyperlink (body-mixin)
  ((target :initarg :target :reader hyperlink-target)))
(setf (gethash 'hyperlink *commands*) 'hyperlink)
(setf (gethash 'link *commands*) 'hyperlink)

(defclass display-syntax (body-mixin)
  ((name :initarg :name :reader display-syntax-name)))
(setf (gethash 'display-syntax *commands*) 'display-syntax)
(setf (gethash 'syntax *commands*) 'display-syntax)

(defclass syntax-alt ()
  ())
(setf (gethash 'syntax-alt *commands*) 'syntax-alt)
(setf (gethash 'alt *commands*) 'syntax-alt)

(defclass syntax-group (body-mixin)
  ())
(setf (gethash 'syntax-group *commands*) 'syntax-group)
(setf (gethash 'group *commands*) 'syntax-group)

(defclass syntax-descriptive (body-mixin)
  ())
(setf (gethash 'syntax-descriptive *commands*) 'syntax-descriptive)

(defclass syntax-repetition (body-mixin)
  ((min :initarg :min
        :initform 0
        :reader syntax-repetition-min)
   (max :initarg :max
        :initform nil
        :reader syntax-repetition-max)))
(setf (gethash 'syntax-repetition *commands*) 'syntax-repetition)
(setf (gethash 'rep *commands*) 'syntax-repetition)

(defclass inline-quil (inline-code)
  ())
(setf (gethash 'inline-quil *commands*) 'inline-quil)
(setf (gethash 'quil *commands*) 'inline-quil)

(defclass inline-emph (body-mixin)
  ())
(setf (gethash 'inline-emph *commands*) 'inline-emph)
(setf (gethash 'emph *commands*) 'inline-emph)

(defclass inline-meta-syntax (body-mixin)
  ((sub :initarg :sub :reader inline-meta-syntax-sub)))
(setf (gethash 'inline-meta-syntax *commands*) 'inline-meta-syntax)
(setf (gethash 'ms *commands*) 'inline-meta-syntax)

(defclass heading-mixin (titled-mixin)
  ((number :initarg :number :accessor heading-number
           :initform nil)))

(defclass heading-section (heading-mixin)
  ())
(setf (gethash 'heading-section *commands*) 'heading-section)
(setf (gethash 'section *commands*) 'heading-section)

(defclass heading-subsection (heading-mixin)
  ())
(setf (gethash 'heading-subsection *commands*) 'heading-subsection)
(setf (gethash 'subsection *commands*) 'heading-subsection)

(defclass heading-subsubsection (heading-mixin)
  ())
(setf (gethash 'heading-subsubsection *commands*) 'heading-subsubsection)
(setf (gethash 'subsubsection *commands*) 'heading-subsubsection)

(defclass heading-subsubsubsection (heading-mixin)
  ())
(setf (gethash 'heading-subsubsubsection *commands*) 'heading-subsubsubsection)
(setf (gethash 'subsubsubsection *commands*) 'heading-subsubsubsection)

(defclass itemize (body-mixin)
  ())
(setf (gethash 'itemize *commands*) 'itemize)

(defclass enumerate (body-mixin)
  ())
(setf (gethash 'enumerate *commands*) 'enumerate)

(defclass list-item (body-mixin)
  ())
(setf (gethash 'list-item *commands*) 'list-item)
(setf (gethash 'item *commands*) 'list-item)

(defclass document (titled-mixin body-mixin)
  ((author :initarg :author :reader document-author)
   (version :initarg :version :reader document-version)))

;;; Post-Processing

;; Heading Numbers

(defun make-counter ()
  (make-array 10 :initial-element 0))

(defun heading-counter-string (counter level)
  (format nil "~{~D~^.~}"
          (coerce
           (subseq counter 0 level)
           'list)))

(defun incf-heading (counter level)
  (incf (aref counter (1- level)))
  (fill counter 0 :start level))

(defun assign-heading-numbers (document)
  (let ((counter (make-counter)))
    (dolist (item (body document))
      (typecase item
        (heading-section
         (incf-heading counter 1)
         (setf (heading-number item) (heading-counter-string counter 1)))
        (heading-subsection
         (incf-heading counter 2)
         (setf (heading-number item) (heading-counter-string counter 2)))
        (heading-subsubsection
         (incf-heading counter 3)
         (setf (heading-number item) (heading-counter-string counter 3)))
        (heading-subsubsubsection
         (incf-heading counter 4)
         (setf (heading-number item) (heading-counter-string counter 4)))))))


(defclass table-of-contents ()
  ((headings :initarg :headings :reader table-of-contents-headings)))

(defun headingp (x)
  (typep x 'heading-mixin))

(defun generate-toc (doc)
  (let ((headings (remove-if-not #'headingp (body doc))))
    (make-instance 'table-of-contents
      :headings headings)))

;;; Generating the Document

(defun clos-form-handler (operator &key (options nil options-present-p)
                                        (body nil body-present-p))
  (let ((class (gethash operator *commands*)))
    (cond
      ((and (not (symbolp operator))
            (not options-present-p)
            (not body-present-p))
       operator)
      (class
       (when body-present-p
         (setf (getf options ':body) body))
       (apply 'make-instance class options))
      (t
       (warn "No object representation for ~S" operator)
       (scriptum:default-form-handler operator :options options :body body)))))

(defun include (filename)
  (with-open-file (s filename :direction ':input)
    (let ((*readtable* (named-readtables:find-readtable 'scriptum:syntax))
          (scriptum:*form-handler* 'clos-form-handler)
          (scriptum:*debug-stream* t)
          ;; Scriptum needs to intern symbols into this package (where
          ;; all the commands are at).
          (*package* (find-package "QUIL-SPEC-GEN")))
      (loop :for r := (read s nil nil)
            :while r
            :collect r))))

(defun make-quil-spec-document ()
  (let ((doc (make-instance 'document
               :title "Quil Specification"
               :author "Robert S. Smith; Rigetti & Co. Inc.; and contributors"
               :version "2024.1 (DRAFT)"
               :body (append
                      (include (spec/ "sec-intro.s"))
                      (include (spec/ "sec-opsem.s"))
                      (include (spec/ "sec-structure.s"))
                      (include (spec/ "sec-gates.s"))
                      (include (spec/ "sec-reset.s"))
                      (include (spec/ "sec-mem.s"))
                      (include (spec/ "sec-measurement.s"))
                      (include (spec/ "sec-control.s"))
                      (include (spec/ "sec-other.s"))
                      (include (spec/ "sec-circuits.s"))
                      (include (spec/ "sec-history.s"))
                      (include (spec/ "sec-quilt.s"))))))
    (assign-heading-numbers doc)
    (push (generate-toc doc) (slot-value doc 'body))
    doc))

;;; HTML Generation and Export

(defvar *path* nil)
(defun current-path ()
  ;; don't include the node we are on
  (rest *path*))

(defgeneric html (stream object)
  ;; Ensure we know the path we took to get here.
  (:method :around (stream object)
    (let ((*path* (cons object *path*)))
      (call-next-method)
      nil))
  (:method (stream object)
    (cl-who:with-html-output (s stream :indent t)
      (:span :style "color:tomato"
             (cl-who:esc (format nil "<unknown ~A>~2%" (class-name (class-of object)))))))
  (:method :before (stream (o heading-mixin))
    (unless (= 1 (length (current-path)))
      (error "Can't have nested headings. Found ~A nested inside of ~A" o (current-path)))))

(defun html-list (stream list)
  (loop :for x :in list
        :do (html stream x)))

(defun html-body (stream o)
  (html-list stream (body o)))


(defmethod html (stream (o document))
  (cl-who:with-html-output (s stream :prologue t :indent t)
    (:html
     (cl-who:fmt "~&<!-- This document was automatically generated on ~A. -->"
                 (local-time:format-timestring nil (local-time:now)))
     (:head
      (:link :rel "stylesheet"
             :type "text/css"
             :href "style.css")
      (:script :src "https://polyfill.io/v3/polyfill.min.js?features=es6")
      (:script :id "MathJax-script"
               :src "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js")
      (:title (cl-who:esc (title o))))
     (:body
      (:h1 (cl-who:esc (title o)))
      (:p (:b "Authors: ") (cl-who:esc (document-author o)))
      (:p (:b "Language Version: ") (cl-who:esc (document-version o)))
      (html-body s o)))))

(defun heading-anchor (h)
  (substitute-if-not #\- #'alphanumericp
                     (concatenate 'string (heading-number h) (title h))))

(defmethod html (stream (o table-of-contents))
  (cl-who:with-html-output (s stream :indent t)
    (:nav
     :class "toc-wrapper"
     (:h2 "Table of Contents")
     (:ul
      (dolist (heading (table-of-contents-headings o))
        (cl-who:htm
         (:li (:a :href (concatenate 'string "#" (heading-anchor heading))
                  (cl-who:esc
                   (format nil "~A. ~A"
                           (heading-number heading)
                           (title heading)))))))))))

(defmethod html (stream (o string))
  (cl-who:with-html-output (s stream)
    (cl-who:esc o)))

(defmethod html (stream (o paragraph))
  (cl-who:with-html-output (s stream :indent t)
    (:p
     (html-body s o))))

(defmethod html (stream (o inline-emph))
  (cl-who:with-html-output (s stream)
    (:em
     (html-body s o))))

(defmethod html (stream (o inline-meta-syntax))
  (cl-who:with-html-output (s stream)
    (:span :class "meta-syntax"
           (cl-who:esc "⟨"))
    (:span :class "meta-syntax-identifier"
           (html-body s o))
    (when (slot-boundp o 'sub)
      (cl-who:htm
       (:sub
        (:span :class "meta-syntax-identifier"
               (cl-who:esc
                (princ-to-string
                 (inline-meta-syntax-sub o)))))))
    (:span :class "meta-syntax"
           (cl-who:esc "⟩"))))

(defmethod html (stream (o inline-code))
  (cl-who:with-html-output (s stream)
    (:tt
     (html-body s o))))

(defmethod html :around (stream (o heading-mixin))
  (cl-who:with-html-output (s stream)
    (:a :name (heading-anchor o)
        (call-next-method))))

(defmethod html (stream (o heading-section))
  (cl-who:with-html-output (s stream)
    (:h2
     (cl-who:str (heading-number o))
     (cl-who:str ". ")
     (html s (title o)))))

(defmethod html (stream (o heading-subsection))
  (cl-who:with-html-output (s stream)
    (:h3
     (cl-who:str (heading-number o))
     (cl-who:str ". ")
     (html s (title o)))))

(defmethod html (stream (o heading-subsubsection))
  (cl-who:with-html-output (s stream)
    (:h4
     (cl-who:str (heading-number o))
     (cl-who:str ". ")
     (html s (title o)))))

(defmethod html (stream (o heading-subsubsubsection))
  (cl-who:with-html-output (s stream)
    (:h4
     (cl-who:str (heading-number o))
     (cl-who:str ". ")
     (html s (title o)))))

(defmethod html (stream (o itemize))
  (cl-who:with-html-output (s stream)
    (:ul
     (dolist (item (body o))
       (unless (typep item 'list-item)
         (error "Found something that's not a LIST-ITEM in an ITEMIZE: ~S" item))
       (cl-who:htm
        (:li (html-body s item)))))))

(defmethod html (stream (o enumerate))
  (cl-who:with-html-output (s stream)
    (:ol
     (dolist (item (body o))
       (unless (typep item 'list-item)
         (error "Found something that's not a LIST-ITEM in an ENUMERATE: ~S" item))
       (cl-who:htm
        (:li (html-body s item)))))))

(defmethod html (stream (o aside))
  (cl-who:with-html-output (s stream)
    (:p :class "aside"
        (:b "Note: ")
        (html-body s o))
    #+ig
    (:details
     (:summary "Side Note")
     (html-body s o))))

(defmethod html (stream (o hyperlink))
  (cl-who:with-html-output (s stream :indent nil)
    (:a :href (hyperlink-target o)
        (html-body s o))))

(defun syntax-alt-p (x)
  (typep x 'syntax-alt))

(defmethod html (stream (o display-syntax))
  (let ((ms (make-instance 'inline-meta-syntax
              :body (list (display-syntax-name o)))))
    (cl-who:with-html-output (s stream)
      (:div :class "syntax"
            (let ((body (body o)))
              (cond
                ((find-if #'syntax-alt-p body)
                 (let ((alternatives
                         (split-sequence:split-sequence-if #'syntax-alt-p body)))
                   (cl-who:htm
                    (:table :border 0 :cellpadding 4
                            (:tr
                             (:td
                              :style "text-align:right"
                              (html s ms)
                              (cl-who:esc " ::="))
                             (:td
                              (:code
                               (html-list s (pop alternatives)))))
                            (loop :for alt :in alternatives
                                  :do (cl-who:htm
                                       (:tr
                                        (:td :style "text-align:right"
                                             (:span :class "meta-syntax"
                                                    (cl-who:esc "|")))
                                        (:td
                                         (:code
                                          (html-list s alt))))))))))
                (t
                 (cl-who:htm
                  (:p
                   (html s ms)
                   (cl-who:esc " ::= ")
                   (cl-who:htm
                    (:code
                     (html-body s o))))))))))))

(defmethod html (stream (o syntax-alt))
  (cl-who:with-html-output (s stream)
    (:span :class "meta-syntax"
           (cl-who:esc " | "))))

(defmethod html (stream (o syntax-group))
  (cl-who:with-html-output (s stream)
    (:span :class "meta-syntax"
           (cl-who:esc "("))
    (html-body s o)
    (:span :class "meta-syntax"
           (cl-who:esc ")"))))

(defmethod html (stream (o syntax-descriptive))
  (cl-who:with-html-output (s stream)
    (:span :class "meta-syntax"
           (cl-who:esc "⟨"))
    (:span :class "meta-syntax-descriptive"
           (html-body s o))
    (:span :class "meta-syntax"
           (cl-who:esc "⟩"))))

(defmethod html (stream (o syntax-repetition))
  (let ((min (syntax-repetition-min o))
        (max (syntax-repetition-max o)))
    (cl-who:with-html-output (s stream)
      (html-body s o)
      (:span :class "meta-syntax"
             (:sup
              (cond
                ((null max)
                 (cond
                   ((zerop min)
                    (cl-who:esc "*"))
                   ((= 1 min)
                    (cl-who:esc "+"))
                   (t
                    (cl-who:esc
                     (format nil "[~D,∞)" min)))))
                ((= 0 min max)
                 (error "min and max can't be 0 in a @rep"))
                ((= 1 min max)
                 nil)
                ((and (= 0 min)
                      (= 1 max))
                 (cl-who:esc "?"))
                ((= min max)
                 (cl-who:esc
                  (format nil "~D" min)))
                (t
                 (cl-who:fmt "[~D,~D]" min max))))))))

(defmethod html (stream (o display-code))
  (cl-who:with-html-output (s stream :indent t)
    (:pre :class "source-code"
     (html-body s o))))

(defmethod html (stream (o inline-math))
  (cl-who:with-html-output (s stream)
    (write-string "\\(" s)
    (dolist (b (body o))
      (cl-who:str b))
    (write-string "\\)" s)))

(defmethod html (stream (o display-math))
  (cl-who:with-html-output (s stream)
    (write-string "\\[" s)
    (dolist (b (body o))
      (cl-who:str b))
    (write-string "\\]" s)))


(defun write-quil-spec (&optional (document (make-quil-spec-document)))
  (with-open-file (s (site/ "index.html")
                     :direction ':output
                     :if-exists ':supersede
                     :if-does-not-exist ':create)
    (html s document)
    (format t "~&; Wrote ~A.~%" (site/ "spec.html"))
    nil))
