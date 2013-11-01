(ns dstk-test
  (:use clojure.test
        dstk))

(deftest test_ip2coordinates
  (testing "Test ip2coordinates"
    (is 
      (= (ip2coordinates "71.198.248.36")
         {"71.198.248.36" {"postal_code" "", "locality" "Berkeley", "latitude" 37.878101348877, "longitude" -122.271003723145, "dma_code" 807, "country_name" "United States", "region" "CA", "country_code" "US", "country_code3" "USA", "area_code" 510}}))))

;(deftest test_street2coordinates
  ;(testing "Test street2coordinates"
    ;(is
      ;(= (street2coordinates "2543 Graystone Pl, Simi Valley, CA 93065")
         ;"expected"))))

;(deftest test_geocode
  ;(testing "Test geocode"
    ;(is (= 0 1))))

(deftest test_coordinates2politics
  (testing "Test coordinates2politics"
    (is
      (= (coordinates2politics [34.281016, -118.766282])
         [{"politics" [{"type" "admin2", "friendly_type" "country", "name" "United States", "code" "usa"} {"type" "admin6", "friendly_type" "county", "name" "Ventura", "code" "06_111"} {"type" "admin5", "friendly_type" "city", "name" "Simi Valley", "code" "06_72016"} {"type" "admin4", "friendly_type" "state", "name" "California", "code" "us06"} {"type" "constituency", "friendly_type" "constituency", "name" "Twenty fourth district, CA", "code" "06_24"}], "location" {"latitude" 34.281016, "longitude" -118.766282}}]))))

;(deftest test_text2places
  ;(testing "Test text2places"
    ;(is (= 0 1))))

;(deftest test_text2sentences
  ;(testing "Test text2sentences"
    ;(is (= 0 1))))

;(deftest test_html2text
  ;(testing "Test html2text"
    ;(is (= 0 1))))

;(deftest test_html2story
  ;(testing "Test html2story"
    ;(is (= 0 1))))

;(deftest test_text2people
  ;(testing "Test text2people"
    ;(is (= 0 1))))

;(deftest test_text2times
  ;(testing "Test text2times"
    ;(is (= 0 1))))

;(deftest test_text2sentiment
  ;(testing "Test text2sentiment"
    ;(is (= 0 1))))

;(deftest test_coordinates2statistics
  ;(testing "Test coordinates2statistics"
    ;(is (= 0 1))))
