local formatter = require("scripts.formatter")
local test_util = require("tests.test_util")

local formatting_tests = { tests = { }}
local tests = formatting_tests.tests

function tests.get_suffix()
    local number, suffix = formatter.get_suffix(1)
    test_util.assert_equal(number, 1)
    test_util.assert_nil(suffix)

    number, suffix = formatter.get_suffix(-1)
    test_util.assert_equal(number, -1)
    test_util.assert_nil(suffix)

    number, suffix = formatter.get_suffix(1234)
    test_util.assert_equal(number, 1.234)
    test_util.assert_equal(suffix, "k")

    number, suffix = formatter.get_suffix(1234567)
    test_util.assert_equal(number, 1.234567)
    test_util.assert_equal(suffix, "M")

    number, suffix = formatter.get_suffix(-1234567)
    test_util.assert_equal(number, -1.234567)
    test_util.assert_equal(suffix, "M")

    number, suffix = formatter.get_suffix(1e12)
    test_util.assert_equal(number, 1)
    test_util.assert_equal(suffix, "T")

    number, suffix = formatter.get_suffix(0.1234567)
    test_util.assert_equal(number, 0.1234567)
    test_util.assert_nil(suffix)

    number, suffix = formatter.get_suffix(-0.1234567)
    test_util.assert_equal(number, -0.1234567)
    test_util.assert_nil(suffix)

    number, suffix = formatter.get_suffix(0.000001234567)
    test_util.assert_equal(number, 1.234567)
    test_util.assert_equal(suffix, "u")

    number, suffix = formatter.get_suffix(-0.000001234567)
    test_util.assert_equal(number, -1.234567)
    test_util.assert_equal(suffix, "u")
end

function tests.number()
    test_util.assert_string_equal(formatter.format(0, "number"), "0")
    test_util.assert_string_equal(formatter.format(5, "number"), "5")
    test_util.assert_string_equal(formatter.format(123, "number"), "123")
    test_util.assert_string_equal(formatter.format(-123, "number"), "-123")
    test_util.assert_string_equal(formatter.format(1234, "number"), "1234")
    test_util.assert_string_equal(formatter.format(12343, "number"), "12.34 k")
    test_util.assert_string_equal(formatter.format(123432, "number"), "123.43 k")
end

function tests.power()
    test_util.assert_string_equal(formatter.format(0, "power"), "0 W")
    test_util.assert_string_equal(formatter.format(5, "power"), "5 W")
    test_util.assert_string_equal(formatter.format(1234.44, "power"), "1.234 kW")
    test_util.assert_string_equal(formatter.format(1230, "power"), "1.23 kW")
    test_util.assert_string_equal(formatter.format(1234321, "power"), "1.234 MW")
end

function tests.distance()
    test_util.assert_string_equal(formatter.format(0, "distance"), "0 m")
    test_util.assert_string_equal(formatter.format(1, "distance"), "1 m")
    test_util.assert_string_equal(formatter.format(999, "distance"), "999 m")
    test_util.assert_string_equal(formatter.format(1000, "distance"), "1000 m")
    test_util.assert_string_equal(formatter.format(9999, "distance"), "9999 m")
    test_util.assert_string_equal(formatter.format(10000, "distance"), "10 km")
    test_util.assert_string_equal(formatter.format(10001, "distance"), "10.001 km")
    test_util.assert_string_equal(formatter.format(1234000, "distance"), "1234 km")
    test_util.assert_string_equal(formatter.format(1234999.99, "distance"), "1235 km")
end

function tests.area()
    test_util.assert_string_equal(formatter.format(0, "area"), "0 km2")
    test_util.assert_string_equal(formatter.format(0.12345, "area"), "0.123 km2")
    test_util.assert_string_equal(formatter.format(1, "area"), "1 km2")
    test_util.assert_string_equal(formatter.format(1000.1, "area"), "1000 km2")
    test_util.assert_string_equal(formatter.format(1000.9, "area"), "1001 km2")
    test_util.assert_string_equal(formatter.format(123456, "area"), "123456 km2")
end

function tests.percentage()
    test_util.assert_string_equal(formatter.format(0, "percentage"), "0 %")
    test_util.assert_string_equal(formatter.format(0.0001, "percentage"), "0.01 %")
    test_util.assert_string_equal(formatter.format(0.1, "percentage"), "10 %")
    test_util.assert_string_equal(formatter.format(1, "percentage"), "100 %")
    test_util.assert_string_equal(formatter.format(-1, "percentage"), "-100 %")
    test_util.assert_string_equal(formatter.format(0.5, "percentage"), "50 %")
    test_util.assert_string_equal(formatter.format(-0.5, "percentage"), "-50 %")
    test_util.assert_string_equal(formatter.format(1.5, "percentage"), "150 %")
    test_util.assert_string_equal(formatter.format(0.1234321, "percentage"), "12.34 %")
    test_util.assert_string_equal(formatter.format(0.01234321, "percentage"), "1.234 %")
    test_util.assert_string_equal(formatter.format(-0.01234321, "percentage"), "-1.234 %")
end

function tests.time()
    test_util.assert_string_equal(formatter.format(0, "time"), "00:00:00")
    test_util.assert_string_equal(formatter.format(60, "time"), "00:00:01")
    test_util.assert_string_equal(formatter.format(2 * 60, "time"), "00:00:02")
    test_util.assert_string_equal(formatter.format(62 * 60, "time"), "00:01:02")
    test_util.assert_string_equal(formatter.format(60 * 60 * 60, "time"), "01:00:00")
    test_util.assert_string_equal(formatter.format(60 * 60 * 60 + 60, "time"), "01:00:01")
    test_util.assert_string_equal(formatter.format(100 * 60 * 60 * 60 + 5 * 60 * 60, "time"), "100:05:00")
end

return formatting_tests