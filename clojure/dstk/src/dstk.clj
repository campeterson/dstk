(ns dstk
  (:require [clj-http.client :as client])
  (:require [clojure.data.json :as json])
  (:require [clojure.java [io :as io]])

  (:use [ring.util.codec :only [url-encode]]))

(defn api_url [endpoint]
  (str "http://www.datasciencetoolkit.org" endpoint))

;(defn make-query-string [m]
  ;(->> (for [[k v] m]
         ;(str (url-encode k) "=" (url-encode v)))
       ;(interpose "&")
       ;(apply str)))

(defn prep-payload [data_payload data_payload_type]
  (if (= data_payload_type "json")
    (json/write-str data_payload)
    data_payload))

(defn to->vector [input]
  (if (= clojure.lang.PersistentVector (type input))
    input
    [input]))

(defn call-dstk-api [endpoint arguments & [data_payload data_payload_type]]
  (if data_payload
    (client/post (api_url endpoint)
      {:body (prep-payload data_payload data_payload_type)})
    (client/get (api_url endpoint) {:query-params arguments})))


; geocode
(defn geocode [input] ; PASSING!
  (json/read-str
    (:body
      (call-dstk-api "/maps/api/geocode/json" {"address" input}))))

; ip2coordinates
(defn ip2coordinates [ips] ; PASSING!
  (json/read-str
    (:body
      (call-dstk-api "/ip2coordinates" {} (to->vector ips) "json"))))

; street2coordinates
(defn street2coordinates [addresses] ; PASSING!
  (json/read-str
    (:body
      (call-dstk-api "/street2coordinates" {} (to->vector addresses) "json"))))

; text2sentences
(defn text2sentences [text] ; PASSING!
  (json/read-str
    (:body
      (call-dstk-api "/text2sentences" {} text "json"))))

;coordinages2politics
; FIXME - failing
;(defn coordinates2politics [input]
  ;(json/read-str
    ;(:body
      ;(call-dstk-api "/coordinates2politics" {} (str
                                                    ;(first input)
                                                    ;","
                                                    ;(last input)) "json"))))

; coordinates2statistics
; FIXME - failing
;(defn coordinates2statistics [input]
  ;(json/read-str
    ;(:body
      ;(call-dstk-api "/coordinates2statistics" {} (str
                                                    ;(first input)
                                                    ;","
                                                    ;(last input)) "json"))))
