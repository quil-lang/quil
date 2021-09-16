(defsystem #:quil-spec-gen
  :description "Quil spec and code to generate it as a document."
  :author "Robert Smith"
  :depends-on (#:scriptum #:cl-who #:local-time #:split-sequence)
  :pathname "specgen/"
  :serial t
  :components ((:file "quil")
               (:module "spec"
                :serial t
                :components ((:static-file "sec-intro.s")
                             (:static-file "sec-opsem.s")
                             (:static-file "sec-structure.s")
                             (:static-file "sec-gates.s")
                             (:static-file "sec-reset.s")
                             (:static-file "sec-mem.s")
                             (:static-file "sec-measurement.s")
                             (:static-file "sec-control.s")
                             (:static-file "sec-other.s")
                             (:static-file "sec-circuits.s")
                             (:static-file "sec-history.s")))
               (:module "site"
                :serial t
                :components ((:static-file "spec-style.css")))))
