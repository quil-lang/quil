(defsystem #:quil-spec-gen
  :description "Quil spec and code to generate it as a document."
  :author "Robert Smith"
  :depends-on (#:scrawl #:cl-who #:local-time #:split-sequence)
  :pathname "specgen/"
  :serial t
  :components ((:file "quil")
               (:module "spec"
                :serial t
                :components ((:static-file "sec-intro.scr")))
               (:module "site"
                :serial t
                :components ((:static-file "spec-style.css")))))
