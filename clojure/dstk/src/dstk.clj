(ns dstk
  (:require [clj-http.client :as client])
  (:require [clojure.data.json :as json]))
  ;(:use [clojure.contrib.java-utils :only [as-str]]
        ;[clojure.contrib.str-utils :only [str-join]])
  ;(:import (java.util URL URLEncoder)))

(defn api-action [method path & [opts]]
  (client/request
    (merge {:method method :url (str "http://www.datasciencetoolkit.org" path)} opts)))

; thanks https://github.com/technomancy/clojure-http-client/blob/master/src/clojure_http/client.clj
;(defn url-encode
  ;"Wrapper around java.net.URLEncoder returning a (UTF-8) URL encoded
  ;representation of argument, either a string or map."
  ;[arg]
  ;(if (map? arg)
    ;(str-join \& (map #(str-join \= (map url-encode %)) arg))
    ;(URLEncoder/encode (as-str arg) "UTF-8")))

(defn ip2coordinates [input]
  (json/read-str
    (:body
      (api-action :get, (str "/ip2coordinates/" input)))))

(defn street2coordinates [input]
  (json/read-str
    (:body
      (api-action :get, (str "/street2coordinates/" input)))))

(defn geocode [input]
  (json/read-str
    (:body
      (api-action :get, (str "/maps/api/geocode/json?address=" input)))))

(defn coordinates2politics [input]
  (json/read-str
    (:body
      (api-action :get, (str "/coordinates2politics/"
                             (first input)
                             ","
                             (last input))))))

(defn coordinates2statistics [input]
  (json/read-str
    (:body
      (api-action :get, (str "/coordinates2statistics/"
                             (first input)
                             ","
                             (last input))))))
