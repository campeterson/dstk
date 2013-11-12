(defproject dstk "0.1.0-SNAPSHOT"
  :description "Data Science Toolkit Clojure Library"
  :url "http://www.datasciencetoolkit.org"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.5.1"]
                 [org.clojure/data.json "0.2.3"]
                 [ring/ring-core "1.2.1"]
                 [clj-http "0.7.7"]
                 [expectations "1.4.52"]]
  :plugins [[lein-expectations "0.0.7"]
            [lein-autoexpect "1.0"]])
