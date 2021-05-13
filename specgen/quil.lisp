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


;;; Scrawl Commands

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

(defclass display-syntax (body-mixin)
  ((name :initarg :name :reader display-syntax-name)))
(setf (gethash 'display-syntax *commands*) 'display-syntax)
(setf (gethash 'syntax *commands*) 'display-syntax)

(defclass syntax-alt ()
  ())
(setf (gethash 'syntax-alt *commands*) 'syntax-alt)
(setf (gethash 'alt *commands*) 'syntax-alt)

(defclass inline-quil (inline-code)
  ())
(setf (gethash 'inline-quil *commands*) 'inline-quil)
(setf (gethash 'quil *commands*) 'inline-quil)

(defclass inline-emph (body-mixin)
  ())
(setf (gethash 'inline-emph *commands*) 'inline-emph)
(setf (gethash 'emph *commands*) 'inline-emph)

(defclass inline-meta-syntax (body-mixin)
  ())
(setf (gethash 'inline-meta-syntax *commands*) 'inline-meta-syntax)
(setf (gethash 'ms *commands*) 'inline-meta-syntax)

(defclass heading-section (titled-mixin)
  ())
(setf (gethash 'heading-section *commands*) 'heading-section)
(setf (gethash 'section *commands*) 'heading-section)

(defclass heading-subsection (titled-mixin)
  ())
(setf (gethash 'heading-subsection *commands*) 'heading-subsection)
(setf (gethash 'subsection *commands*) 'heading-subsection)

(defclass document (titled-mixin body-mixin)
  ((author :initarg :author :reader document-author)
   (version :initarg :version :reader document-version)))

(defun clos-form-handler (operator &key options
                                        (body nil body-present-p))
  (let ((class (gethash operator *commands*)))
    (cond
      ((not (symbolp operator))
       (assert (null options))
       (assert (null body))
       operator)
      (class
       (when body-present-p
         (setf (getf options ':body) body))
       (apply 'make-instance class options))
      (t
       (warn "No object representation for ~S" operator)
       (scrawl:default-form-handler operator :options options :body body)))))

(defun include (filename)
  (with-open-file (s filename :direction ':input)
    (let ((*readtable* (named-readtables:find-readtable 'scrawl:syntax))
          (scrawl:*form-handler* 'clos-form-handler)
          (scrawl:*debug-stream* t)
          ;; Scrawl needs to intern symbols into this package (where
          ;; all the commands are at).
          (*package* (find-package "QUIL-SPEC-GEN")))
      (loop :for r := (read s nil nil)
            :while r
            :collect r))))

(defun make-quil-spec-document ()
  (make-instance 'document
    :title "Quil Specification"
    :author "many"
    :version "2021.1"
    :body (append
           (include (spec/ "sec-intro.scr")))))


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
             (cl-who:esc (format nil "<unknown ~A>~2%" (class-name (class-of object))))))))

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
      (:title (cl-who:esc (title o)))
      #+ignore
      (:link :rel "stylesheet"
             :href "https://maxcdn.bootstrapcdn.com/bootstrap/4.1.1/css/bootstrap.min.css")
      (:link :rel "stylesheet"
             :href "spec-style.css")
      (:script :src "https://polyfill.io/v3/polyfill.min.js?features=es6")
      (:script :id "MathJax-script"
               :src "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"))
     (:body
      (:h1 (cl-who:esc (title o)))
      (:p (:b "Authors: ") (cl-who:esc (document-author o)))
      (:p (:b "Language Version: ") (cl-who:esc (document-version o)))
      (html-body s o)))))

(defmethod html (stream (o string))
  (cl-who:with-html-output (s stream)
    (cl-who:esc o)))

(defmethod html (stream (o paragraph))
  (cl-who:with-html-output (s stream)
    (:p
     (html-body s o))))

(defmethod html (stream (o inline-emph))
  (cl-who:with-html-output (s stream)
    (:em
     (html-body s o))))

(defmethod html (stream (o inline-meta-syntax))
  (cl-who:with-html-output (s stream)
    (:span
     (cl-who:esc "⟨")
     (:span :class "meta-syntax"
      (html-body s o))
     (cl-who:esc "⟩"))))

(defmethod html (stream (o inline-code))
  (cl-who:with-html-output (s stream)
    (:tt
     (html-body s o))))

(defmethod html (stream (o heading-section))
  (cl-who:with-html-output (s stream)
    (:h2
     (html s (title o)))))

(defmethod html (stream (o heading-subsection))
  (cl-who:with-html-output (s stream)
    (:h3
     (html s (title o)))))

(defmethod html (stream (o aside))
  (cl-who:with-html-output (s stream :indent t)
    (:p :class "aside"
        (:b "Note: ")
        (html-body s o))
    #+ig
    (:details
     (:summary "Side Note")
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
                              (cl-who:esc " ⩴"))
                             (:td
                              (html-list s (pop alternatives))))
                            (loop :for alt :in alternatives
                                  :do (cl-who:htm
                                       (:tr
                                        (:td :style "text-align:right" (cl-who:esc "|"))
                                        (:td (html-list s alt)))))))))
                (t
                 (cl-who:htm
                  (:p
                   (html s ms)
                   (cl-who:esc " ⩴ ")
                   (cl-who:htm
                    (:code
                     (html-body s o)))))
                 #+ig
                 (:details
                  (:summary "Side Note")
                  (html-body s o)))))))))

(defmethod html (stream (o syntax-alt))
  (cl-who:with-html-output (s stream)
    (:code " | ")))

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
  (with-open-file (s (site/ "spec.html")
                     :direction ':output
                     :if-exists ':supersede
                     :if-does-not-exist ':create)
    (html s document)
    (format t "~&; Wrote ~A.~%" (site/ "spec.html"))))
