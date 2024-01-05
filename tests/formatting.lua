local lib = require("scripts.lib")
local test_util = require("tests.test_util")

local formatting_tests = { tests = { }}
local tests = formatting_tests.tests

function tests.normal_number_without_suffix()
    test_util.assert_string_equal(lib.format_number(0), "0")
    test_util.assert_string_equal(lib.format_number(5), "5")
    test_util.assert_string_equal(lib.format_number(123), "123")
    test_util.assert_string_equal(lib.format_number(-123), "-123")

    test_util.assert_string_equal(lib.format_number(1234), "1234")
    test_util.assert_string_equal(lib.format_number(12345), "12345")
    test_util.assert_string_equal(lib.format_number(123456), "123456")
end

function tests.normal_number_with_suffix()
    test_util.assert_string_equal(lib.format_number(0), "0")
    test_util.assert_string_equal(lib.format_number(5), "5")
    test_util.assert_string_equal(lib.format_number(123), "123")
    test_util.assert_string_equal(lib.format_number(-123), "-123")

    test_util.assert_string_equal(lib.format_number(1234, true), "1.234 k")
    test_util.assert_string_equal(lib.format_number(-1234, true), "-1.234 k")
    -- The next are weird because there's an internal limit of 6 decimals
    test_util.assert_string_equal(lib.format_number(1234567, true), "1.234567 M")
    test_util.assert_string_equal(lib.format_number(1234567890, true), "1.234567 G")
    test_util.assert_string_equal(lib.format_number(1234567890123, true), "1.234567 T")
end

function tests.normal_number_decimals_no_suffix()
    test_util.assert_string_equal(lib.format_number(1.234567), "1.234567")
    test_util.assert_string_equal(lib.format_number(1.234567, false, 1), "1.2")
    test_util.assert_string_equal(lib.format_number(1.234567, false, 2), "1.23")
    test_util.assert_string_equal(lib.format_number(1.230000, false, 2), "1.23")
    test_util.assert_string_equal(lib.format_number(1.234000, false, 3), "1.234")
    test_util.assert_string_equal(lib.format_number(1.234000, false, 4), "1.234")

    test_util.assert_string_equal(lib.format_number(-1.234567), "-1.234567")
    test_util.assert_string_equal(lib.format_number(-1.234567, false, 1), "-1.2")
    test_util.assert_string_equal(lib.format_number(-1.234567, false, 2), "-1.23")
    test_util.assert_string_equal(lib.format_number(-1.230000, false, 2), "-1.23")
    test_util.assert_string_equal(lib.format_number(-1.234000, false, 3), "-1.234")
    test_util.assert_string_equal(lib.format_number(-1.234000, false, 4), "-1.234")
end

function tests.normal_number_decimals_with_suffix()
    test_util.assert_string_equal(lib.format_number(1234.567, true, 1), "1.2 k")
    test_util.assert_string_equal(lib.format_number(1234.567, true, 2), "1.23 k")
    test_util.assert_string_equal(lib.format_number(1230.000, true, 2), "1.23 k")
    test_util.assert_string_equal(lib.format_number(1234.100, true, 3), "1.234 k")
    test_util.assert_string_equal(lib.format_number(1234.900, true, 3), "1.235 k")
    test_util.assert_string_equal(lib.format_number(1234.000, true, 4), "1.234 k")

    test_util.assert_string_equal(lib.format_number(-1234.567, true, 1), "-1.2 k")
    test_util.assert_string_equal(lib.format_number(-1234.567, true, 2), "-1.23 k")
    test_util.assert_string_equal(lib.format_number(-1230.000, true, 2), "-1.23 k")
    test_util.assert_string_equal(lib.format_number(-1234.100, true, 3), "-1.234 k")
    test_util.assert_string_equal(lib.format_number(-1234.900, true, 3), "-1.235 k")
    test_util.assert_string_equal(lib.format_number(-1234.100, true, 4), "-1.2341 k")
end

function tests.power()
    test_util.assert_string_equal(lib.format_power(0), "0 W")
    test_util.assert_string_equal(lib.format_power(5), "5 W")
    test_util.assert_string_equal(lib.format_power(1234.567), "1.234 kW")
    test_util.assert_string_equal(lib.format_power(1230), "1.23 kW")
    test_util.assert_string_equal(lib.format_power(1234567), "1.234 MW")
end

function tests.distance()
    test_util.assert_string_equal(lib.format_distance(0), "0 m")
    test_util.assert_string_equal(lib.format_distance(1), "1 m")
    test_util.assert_string_equal(lib.format_distance(999), "999 m")
    test_util.assert_string_equal(lib.format_distance(1000), "1 km")
    test_util.assert_string_equal(lib.format_distance(1234000), "1234 km")
    test_util.assert_string_equal(lib.format_distance(1234999), "1235 km")
end

function tests.area()
    test_util.assert_string_equal(lib.format_area(0), "0 km2")
    test_util.assert_string_equal(lib.format_area(0.12345), "0.12345 km2")
    test_util.assert_string_equal(lib.format_area(1), "1 km2")
    test_util.assert_string_equal(lib.format_area(1000.1), "1000 km2")
    test_util.assert_string_equal(lib.format_area(1000.9), "1001 km2")
    test_util.assert_string_equal(lib.format_area(123456), "123456 km2")
end

function tests.time()
    test_util.assert_string_equal(lib.format_time(0), "00:00:00")
    test_util.assert_string_equal(lib.format_time(60), "00:00:01")
    test_util.assert_string_equal(lib.format_time(2 * 60), "00:00:02")
    test_util.assert_string_equal(lib.format_time(62 * 60), "00:01:02")
    test_util.assert_string_equal(lib.format_time(60 * 60 * 60), "01:00:00")
    test_util.assert_string_equal(lib.format_time(60 * 60 * 60 + 60), "01:00:01")
    test_util.assert_string_equal(lib.format_time(100 * 60 * 60 * 60 + 5 * 60 * 60), "100:05:00")
end

return formatting_tests