(ns dstk
  (:require [clj-http.client :as client])
  (:require [clojure.data.json :as json])
  (:require [clojure.java [io :as io]])

  (:use [ring.util.codec :only [url-encode]]))

(defn api-action [method path & [opts]]
  (client/request
    (merge {:method method :url (str "http://www.datasciencetoolkit.org" path)} opts)))

(defn make-query-string [m]
  (->> (for [[k v] m]
         (str (url-encode k) "=" (url-encode v)))
       (interpose "&")
       (apply str)))

(defn json-api-call [endpoint arguments data_payload data_payload_type]
  (if (not (nil? data_payload))
    (api-action :get, (str endpoint data_payload))))

(defn ip2coordinates [input]
  (json/read-str
    (:body
      (json-api-call "/ip2coordinates/" {} input "json"))))

(defn street2coordinates [input]
  (json/read-str
    (:body
      (json-api-call "/street2coordinates/" {} input "json"))))

(defn geocode [input]
  (json/read-str
    (:body
      (json-api-call "/maps/api/geocode/json?address=" {} input "json"))))

(defn coordinates2politics [input]
  (json/read-str
    (:body
      (json-api-call "/coordinates2politics/" {} (str
                                                    (first input)
                                                    ","
                                                    (last input)) "json"))))

(defn text2sentences [input]
  (json/read-str
    (:body
      (json-api-call "/text2sentences/" {} input "json"))))
      ;(api-action :get, (str "/text2sentences/" input)))))

(defn coordinates2statistics [input]
  (json/read-str
    (:body
      (json-api-call "/coordinates2statistics/" {} (str
                                                    (first input)
                                                    ","
                                                    (last input)) "json"))))
